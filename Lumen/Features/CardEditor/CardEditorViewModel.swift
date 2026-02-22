import UIKit
import SwiftData
import OSLog

// MARK: - CardEditorViewModel

/// Manages card customization state — background style, palette, font, and text.
///
/// Supports both procedural and AI-generated backgrounds. Initializes from
/// an existing ``CardCustomization`` if present, otherwise derives sensible
/// defaults from the affirmation itself.
@MainActor @Observable
final class CardEditorViewModel {

    // MARK: - Background Mode

    enum BackgroundMode: String, CaseIterable, Identifiable {
        case procedural = "Instant"
        case ai = "AI ✨"

        var id: String { rawValue }
    }

    // MARK: - AI Load State (mirrors ThemeGeneratorViewModel)

    enum AILoadState: Equatable {
        case idle
        case downloading(progress: Double)
        case loadingModel(phase: String, progress: Double)
        case ready
        case failed(String)

        var isWorking: Bool {
            switch self {
            case .downloading, .loadingModel: true
            default: false
            }
        }

        var statusText: String {
            switch self {
            case .idle: "Tap Load to download the AI model"
            case .downloading(let p): "Downloading AI model… \(Int(p * 100))%"
            case .loadingModel(let phase, _): phase
            case .ready: "AI model ready"
            case .failed(let msg): "Failed: \(msg)"
            }
        }

        var progress: Double? {
            switch self {
            case .downloading(let p): p
            case .loadingModel(_, let p): p
            default: nil
            }
        }
    }

    // MARK: - Public State

    let affirmation: Affirmation

    var backgroundMode: BackgroundMode
    var selectedStyle: GeneratorStyle
    var selectedPalette: ColorPalette
    var selectedFontStyle: AffirmationFontStyle?
    var customText: String
    var backgroundSeed: UInt32

    // AI state
    var selectedPromptCategory: AIBackgroundPrompt.PromptCategory = .ethereal
    var selectedPrompt: AIBackgroundPrompt?
    var aiLoadState: AILoadState = .idle
    var isModelReady: Bool { aiLoadState == .ready }

    var previewImage: UIImage?
    var isGeneratingPreview: Bool = false

    /// Path to the last generated image (for caching on save).
    private var lastGeneratedImagePath: URL?

    /// Only user-authored affirmations allow text editing.
    var canEditText: Bool { affirmation.source == .user }

    /// `true` when any property differs from the initial snapshot.
    var hasChanges: Bool {
        backgroundMode != initialMode
            || selectedStyle != initialStyle
            || selectedPalette != initialPalette
            || selectedFontStyle != initialFontStyle
            || customText != initialCustomText
            || backgroundSeed != initialSeed
            || selectedPrompt?.id != initialPromptId
    }

    // MARK: - Private

    private let customizationService: any CardCustomizationServiceProtocol
    private let backgroundGenerator: any BackgroundGeneratorProtocol
    private let aiGenerator: any AIBackgroundServiceProtocol

    private let initialMode: BackgroundMode
    private let initialStyle: GeneratorStyle
    private let initialPalette: ColorPalette
    private let initialFontStyle: AffirmationFontStyle?
    private let initialCustomText: String
    private let initialSeed: UInt32
    private let initialPromptId: String?

    // MARK: - Init

    init(
        affirmation: Affirmation,
        existingCustomization: CardCustomization?,
        customizationService: some CardCustomizationServiceProtocol = CardCustomizationService.shared,
        backgroundGenerator: some BackgroundGeneratorProtocol = BackgroundGeneratorService.shared,
        aiGenerator: some AIBackgroundServiceProtocol = AIBackgroundService.shared
    ) {
        self.affirmation = affirmation
        self.customizationService = customizationService
        self.backgroundGenerator = backgroundGenerator
        self.aiGenerator = aiGenerator

        let usesAI = existingCustomization?.usesAIBackground ?? false
        let mode: BackgroundMode = usesAI ? .ai : .procedural
        let style = existingCustomization?.backgroundStyle
            .flatMap(GeneratorStyle.init(rawValue:)) ?? Self.defaultStyle(for: affirmation)
        let palette = existingCustomization?.colorPalette
            .flatMap(ColorPalette.init(rawValue:)) ?? Self.defaultPalette(for: affirmation)
        let fontStyle = existingCustomization?.fontStyleOverride
            .flatMap(AffirmationFontStyle.init(rawValue:))
            ?? affirmation.fontStyle.flatMap(AffirmationFontStyle.init(rawValue:))
        let text = existingCustomization?.customText ?? affirmation.text
        let seed = existingCustomization?.backgroundSeed ?? Self.defaultSeed(for: affirmation)
        let promptId = existingCustomization?.aiPromptId

        let resolvedPrompt = promptId.flatMap { id in
            AIBackgroundPrompt.library.first { $0.id == id }
        }

        self.backgroundMode = mode
        self.selectedStyle = style
        self.selectedPalette = palette
        self.selectedFontStyle = fontStyle
        self.customText = text
        self.backgroundSeed = seed
        self.selectedPrompt = resolvedPrompt
        if let resolvedPrompt {
            self.selectedPromptCategory = resolvedPrompt.category
        }

        // Load cached image if it exists
        if let cachedPath = existingCustomization?.cachedImagePath {
            let fullPath = Self.customizationImagesDir.appendingPathComponent(cachedPath)
            self.previewImage = UIImage(contentsOfFile: fullPath.path)
            self.lastGeneratedImagePath = fullPath
        }

        self.initialMode = mode
        self.initialStyle = style
        self.initialPalette = palette
        self.initialFontStyle = fontStyle
        self.initialCustomText = text
        self.initialSeed = seed
        self.initialPromptId = promptId
    }

    // MARK: - Actions

    /// Check AI model status on appear.
    func checkAIModelStatus() async {
        if await aiGenerator.isModelReady() {
            aiLoadState = .ready
        }
    }

    /// Load the AI model.
    func loadAIModel() async {
        guard !aiLoadState.isWorking else { return }
        aiLoadState = .downloading(progress: 0)

        aiGenerator.setLoadPhaseHandler { [weak self] phase, progress in
            Task { @MainActor in
                self?.aiLoadState = .loadingModel(phase: phase, progress: progress)
            }
        }

        do {
            try await aiGenerator.loadModel()
            aiLoadState = .ready
        } catch {
            aiLoadState = .failed(error.localizedDescription)
            Logger.viewModel.error("AI model load failed: \(error.localizedDescription)")
        }
    }

    /// Generates a preview background image from the current selections.
    func generatePreview() async {
        isGeneratingPreview = true
        defer { isGeneratingPreview = false }

        switch backgroundMode {
        case .procedural:
            await generateProceduralPreview()
        case .ai:
            await generateAIPreview()
        }
    }

    /// Persists a ``CardCustomization`` record and caches the background image.
    func save(modelContext: ModelContext) throws {
        try customizationService.delete(for: affirmation.id, modelContext: modelContext)

        // Cache the preview image to persistent storage
        var relativePath: String?
        if let image = previewImage, let lastPath = lastGeneratedImagePath {
            relativePath = try Self.cacheImage(from: lastPath, for: affirmation.id)
        } else if let image = previewImage {
            // Fallback: save from UIImage directly
            relativePath = try Self.cacheImageData(image, for: affirmation.id)
        }

        let customization = CardCustomization(
            affirmationId: affirmation.id,
            backgroundStyle: selectedStyle.rawValue,
            colorPalette: selectedPalette.rawValue,
            backgroundSeed: backgroundSeed,
            fontStyleOverride: selectedFontStyle?.rawValue,
            aiPromptId: selectedPrompt?.id,
            usesAIBackground: backgroundMode == .ai,
            customText: canEditText ? customText : nil
        )
        customization.cachedImagePath = relativePath
        try customizationService.save(customization, modelContext: modelContext)

        if let fontStyle = selectedFontStyle {
            affirmation.fontStyle = fontStyle.rawValue
        }
        if canEditText {
            affirmation.text = customText
        }

        Logger.viewModel.debug("Saved card customization for \(self.affirmation.id, privacy: .private)")
    }

    /// Removes the customization record, reverting the card to defaults.
    func resetToDefaults(modelContext: ModelContext) throws {
        try customizationService.delete(for: affirmation.id, modelContext: modelContext)

        backgroundMode = .procedural
        selectedStyle = Self.defaultStyle(for: affirmation)
        selectedPalette = Self.defaultPalette(for: affirmation)
        selectedFontStyle = affirmation.fontStyle.flatMap(AffirmationFontStyle.init(rawValue:))
        customText = affirmation.text
        backgroundSeed = Self.defaultSeed(for: affirmation)
        selectedPrompt = nil
        previewImage = nil
        lastGeneratedImagePath = nil

        Logger.viewModel.debug("Reset card customization for \(self.affirmation.id, privacy: .private)")
    }

    /// Randomizes the background seed and triggers a preview regeneration.
    func randomizeSeed() {
        backgroundSeed = UInt32.random(in: 0...UInt32.max)
    }

    // MARK: - Private Generation

    private func generateProceduralPreview() async {
        let request = BackgroundRequest(
            style: selectedStyle,
            palette: selectedPalette,
            mood: .calm,
            complexity: 0.5,
            seed: backgroundSeed,
            size: CGSize(width: 1080, height: 1920)
        )

        do {
            let result = try await backgroundGenerator.generate(request: request)
            previewImage = UIImage(contentsOfFile: result.imagePath.path)
            lastGeneratedImagePath = result.imagePath
        } catch {
            Logger.viewModel.error("Procedural preview failed: \(error.localizedDescription)")
        }
    }

    private func generateAIPreview() async {
        guard isModelReady else { return }

        let prompt = selectedPrompt ?? AIBackgroundPrompt.random(category: selectedPromptCategory)
        selectedPrompt = prompt

        let request = AIBackgroundRequest(
            prompt: prompt,
            seed: backgroundSeed,
            stepCount: 8
        )

        do {
            let result = try await aiGenerator.generate(request: request)
            previewImage = UIImage(contentsOfFile: result.imagePath.path)
            lastGeneratedImagePath = result.imagePath
        } catch {
            Logger.viewModel.error("AI preview failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Image Caching

    static let customizationImagesDir: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CardCustomizations", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    private static func cacheImage(from sourcePath: URL, for affirmationId: String) throws -> String {
        let filename = "\(affirmationId)_\(Int(Date().timeIntervalSince1970)).png"
        let destPath = customizationImagesDir.appendingPathComponent(filename)
        // Remove old cached images for this affirmation
        cleanOldCaches(for: affirmationId)
        try FileManager.default.copyItem(at: sourcePath, to: destPath)
        return filename
    }

    private static func cacheImageData(_ image: UIImage, for affirmationId: String) throws -> String {
        let filename = "\(affirmationId)_\(Int(Date().timeIntervalSince1970)).png"
        let destPath = customizationImagesDir.appendingPathComponent(filename)
        cleanOldCaches(for: affirmationId)
        guard let data = image.pngData() else { throw CacheError.encodingFailed }
        try data.write(to: destPath)
        return filename
    }

    private static func cleanOldCaches(for affirmationId: String) {
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(at: customizationImagesDir, includingPropertiesForKeys: nil) else { return }
        for file in contents where file.lastPathComponent.hasPrefix(affirmationId) {
            try? fm.removeItem(at: file)
        }
    }

    enum CacheError: Error {
        case encodingFailed
    }

    // MARK: - Defaults

    private static func defaultStyle(for affirmation: Affirmation) -> GeneratorStyle {
        let hash = abs(affirmation.id.hashValue)
        let styles = GeneratorStyle.allCases
        return styles[hash % styles.count]
    }

    private static func defaultPalette(for affirmation: Affirmation) -> ColorPalette {
        let hash = abs(affirmation.id.hashValue >> 4)
        let palettes = ColorPalette.allCases
        return palettes[hash % palettes.count]
    }

    private static func defaultSeed(for affirmation: Affirmation) -> UInt32 {
        UInt32(abs(affirmation.id.hashValue) & 0xFFFF_FFFF)
    }
}
