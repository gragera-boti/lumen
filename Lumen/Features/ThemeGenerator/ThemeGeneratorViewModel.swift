import Dependencies
import Foundation
import OSLog
import SwiftData
import UIKit

@MainActor @Observable
final class ThemeGeneratorViewModel {
    // MARK: - Shared state

    enum GeneratorMode: String, CaseIterable, Identifiable {
        case procedural = "Instant"
        case ai = "AI ✨"

        var id: String { rawValue }
    }

    /// Unified loading state — one source of truth
    enum AILoadState: Equatable {
        case idle
        case downloading(progress: Double)
        case loadingModel(phase: String, progress: Double)
        case ready
        case generating(promptName: String, step: Int, totalSteps: Int)
        case failed(String)

        var isWorking: Bool {
            switch self {
            case .downloading, .loadingModel, .generating: true
            default: false
            }
        }

        var statusText: String {
            switch self {
            case .idle: "Tap Load to download the AI model"
            case .downloading(let p): "Downloading AI model… \(Int(p * 100))%"
            case .loadingModel(let phase, _): phase
            case .ready: "AI model ready"
            case .generating(let name, let step, let total):
                step > 0 ? "Generating \"\(name)\"… Step \(step)/\(total)" : "Generating \"\(name)\"…"
            case .failed(let msg): msg
            }
        }

        var progress: Double? {
            switch self {
            case .downloading(let p): p
            case .loadingModel(_, let p): p
            case .generating(_, let step, let total) where total > 0:
                Double(step) / Double(total)
            default: nil
            }
        }
    }

    var selectedMode: GeneratorMode = .procedural

    var isGenerating = false
    var generatedImage: UIImage?
    var savedThemeId: String?
    var isSaved = false
    var errorMessage: String?
    var showPaywallPrompt = false

    // MARK: - Procedural state

    var selectedStyle: GeneratorStyle = .aurora
    var selectedPalette: ColorPalette = .warmFlame
    var selectedMood: GeneratorMood = .calm
    var complexity: Float = 0.5

    // MARK: - AI state

    var selectedPromptCategory: AIBackgroundPrompt.PromptCategory = .ethereal
    var selectedPrompt: AIBackgroundPrompt?
    var aiStepCount: Int = 10
    var aiLoadState: AILoadState = .idle
    var cachedAIBackgrounds: [GeneratedBackground] = []

    var isModelReady: Bool { aiLoadState == .ready }

    // MARK: - Dependencies

    @ObservationIgnored @Dependency(\.backgroundGenerator) private var generator
    @ObservationIgnored @Dependency(\.aiBackgroundService) private var aiGenerator
    @ObservationIgnored @Dependency(\.analyticsService) private var analyticsService
    @ObservationIgnored @Dependency(\.preferencesService) private var preferencesService
    @ObservationIgnored @Dependency(\.entitlementService) private var entitlementService
    private let logger = Logger(subsystem: "com.gragera.lumen", category: "ThemeGenerator")

    /// Background task ID to keep model loading alive when app is backgrounded
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid

    // MARK: - Lifecycle

    func onAppear() async {
        let ready = await aiGenerator.isModelReady()
        if ready {
            aiLoadState = .ready
        }
        cachedAIBackgrounds = await aiGenerator.cachedBackgrounds()
    }

    // MARK: - Actions

    func generate() async {
        switch selectedMode {
        case .procedural:
            await generateProcedural()
        case .ai:
            await generateAI()
        }
    }

    // MARK: - Procedural Generation

    private func generateProcedural() async {
        isGenerating = true
        generatedImage = nil
        savedThemeId = nil
        isSaved = false
        errorMessage = nil

        await analyticsService.log(event: .backgroundGenerationStarted(style: selectedStyle.rawValue))

        let request = BackgroundRequest(
            style: selectedStyle,
            palette: selectedPalette,
            mood: selectedMood,
            complexity: complexity,
            size: CGSize(width: 1080, height: 1920)
        )

        do {
            let result = try await generator.generate(request: request)

            if let data = try? Data(contentsOf: result.imagePath),
                let image = UIImage(data: data)
            {
                generatedImage = image
                savedThemeId = result.themeId
            } else {
                errorMessage = "Failed to load generated image"
            }

            await analyticsService.log(event: .backgroundGenerationCompleted(durationMs: result.metadata.durationMs))
        } catch is CancellationError {
            await analyticsService.log(event: .backgroundGenerationCancelled)
        } catch {
            logger.error("Generation error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }

        isGenerating = false
    }

    // MARK: - AI Model Loading

    func loadAIModel() async {
        guard !aiLoadState.isWorking else { return }

        beginBackgroundTask()
        defer { endBackgroundTask() }

        // Wire up download progress for ODR
        await aiGenerator.setDownloadProgressHandler { [weak self] progress in
            Task { @MainActor [weak self] in
                self?.aiLoadState = .downloading(progress: progress)
            }
        }

        // Wire up load phase progress
        await aiGenerator.setLoadPhaseHandler { [weak self] phase, progress in
            Task { @MainActor [weak self] in
                self?.aiLoadState = .loadingModel(phase: phase, progress: progress)
            }
        }

        aiLoadState = .loadingModel(phase: "Preparing…", progress: 0)

        do {
            try await aiGenerator.loadModel()
            aiLoadState = .ready
            logger.info("AI model loaded successfully")
        } catch {
            logger.error("AI model load failed: \(error)")
            let desc = String(describing: error)
            aiLoadState = .failed("Load failed: \(desc.prefix(150))")
            errorMessage = "AI model error: \(desc.prefix(200))"
        }

        await aiGenerator.setDownloadProgressHandler(nil)
        await aiGenerator.setLoadPhaseHandler(nil)
    }

    // MARK: - AI Generation

    private func generateAI() async {
        // AI backgrounds are premium-only
        let isPremium = await entitlementService.isPremium()
        if !isPremium {
            showPaywallPrompt = true
            return
        }

        if !isModelReady {
            await loadAIModel()
            guard isModelReady else { return }
        }

        let prompt = selectedPrompt ?? .random(category: selectedPromptCategory)

        isGenerating = true
        generatedImage = nil
        savedThemeId = nil
        isSaved = false
        errorMessage = nil
        aiLoadState = .generating(promptName: prompt.displayName, step: 0, totalSteps: aiStepCount)

        beginBackgroundTask()
        defer { endBackgroundTask() }

        // Wire up step progress
        await aiGenerator.setStepProgressHandler { [weak self] step, total in
            Task { @MainActor [weak self] in
                self?.aiLoadState = .generating(promptName: prompt.displayName, step: step, totalSteps: total)
            }
        }

        let request = AIBackgroundRequest(
            prompt: prompt,
            stepCount: aiStepCount,
            device: .current()
        )

        do {
            let result = try await aiGenerator.generate(request: request)

            if let data = try? Data(contentsOf: result.imagePath),
                let image = UIImage(data: data)
            {
                generatedImage = image
                savedThemeId = result.themeId
            } else {
                errorMessage = "Failed to load generated image"
            }

            cachedAIBackgrounds = await aiGenerator.cachedBackgrounds()
            logger.info("AI background generated: \(result.themeId)")
        } catch is CancellationError {
            logger.info("AI generation cancelled")
        } catch {
            logger.error("AI generation error: \(error)")
            // Show the full error, not just localizedDescription (which can be vague)
            let desc = String(describing: error)
            errorMessage = "AI generation failed: \(desc.prefix(200))"
        }

        await aiGenerator.setStepProgressHandler(nil)
        aiLoadState = .ready
        isGenerating = false
    }

    func pregenerateAIBatch() async {
        let isPremium = await entitlementService.isPremium()
        if !isPremium {
            showPaywallPrompt = true
            return
        }

        if !isModelReady {
            await loadAIModel()
            guard isModelReady else { return }
        }

        isGenerating = true
        aiLoadState = .generating(promptName: "batch", step: 0, totalSteps: 0)

        beginBackgroundTask()
        defer { endBackgroundTask() }

        do {
            let device = AIDeviceProfile.current()
            let results = try await aiGenerator.pregenerate(count: 6, device: device)
            cachedAIBackgrounds = await aiGenerator.cachedBackgrounds()
            logger.info("Pre-generated \(results.count) AI backgrounds")
        } catch {
            logger.error("Batch generation error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }

        aiLoadState = .ready
        isGenerating = false
    }

    // MARK: - Cache Actions

    func loadCachedBackground(_ bg: GeneratedBackground) {
        if let data = try? Data(contentsOf: bg.imagePath),
            let image = UIImage(data: data)
        {
            generatedImage = image
            savedThemeId = bg.themeId
            isSaved = false
        }
    }

    func deleteCachedBackground(_ bg: GeneratedBackground) async {
        do {
            try await aiGenerator.removeCached(themeId: bg.themeId)
            cachedAIBackgrounds = await aiGenerator.cachedBackgrounds()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Cancel

    func cancelGeneration() async {
        await generator.cancelGeneration()
        await aiGenerator.cancelGeneration()
        isGenerating = false
        if aiLoadState != .ready {
            aiLoadState = .idle
        }
    }

    // MARK: - Save

    func saveAsTheme(modelContext: ModelContext) {
        guard let themeId = savedThemeId else { return }

        do {
            let isAI = selectedMode == .ai
            let metadataJSON: String

            if isAI, let prompt = selectedPrompt {
                let aiMeta = [
                    "type": "ai",
                    "prompt_id": prompt.id,
                    "prompt_name": prompt.displayName,
                    "category": prompt.category.rawValue,
                ]
                let data = try JSONEncoder().encode(aiMeta)
                metadataJSON = String(data: data, encoding: .utf8) ?? "{}"
            } else {
                let metadata = GenerationMetadata(
                    style: selectedStyle.rawValue,
                    palette: selectedPalette.rawValue,
                    mood: selectedMood.rawValue,
                    seed: 0,
                    complexity: complexity,
                    width: 1080,
                    height: 1920,
                    durationMs: 0
                )
                let data = try JSONEncoder().encode(metadata)
                metadataJSON = String(data: data, encoding: .utf8) ?? "{}"
            }

            let name =
                isAI
                ? "AI: \(selectedPrompt?.displayName ?? selectedPromptCategory.displayName)"
                : "\(selectedStyle.displayName) \(selectedPalette.displayName)"

            let theme = AppTheme(
                id: themeId,
                name: name,
                type: .generatedImage,
                isPremium: isAI,
                dataJSON: metadataJSON,
                isActive: true
            )
            modelContext.insert(theme)
            try modelContext.save()

            isSaved = true
            logger.info("Theme saved to rotation: \(themeId)")
        } catch {
            errorMessage = "Couldn't save theme: \(error.localizedDescription)"
        }
    }

    // MARK: - Background Task Protection

    private func beginBackgroundTask() {
        guard backgroundTaskID == .invalid else { return }
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "AIModelLoad") { [weak self] in
            self?.endBackgroundTask()
        }
    }

    private func endBackgroundTask() {
        guard backgroundTaskID != .invalid else { return }
        UIApplication.shared.endBackgroundTask(backgroundTaskID)
        backgroundTaskID = .invalid
    }

}
