import Foundation
import UIKit
import SwiftData
import OSLog

@MainActor @Observable
final class ThemeGeneratorViewModel {
    // MARK: - State

    var selectedStyle: GeneratorStyle = .abstract
    var selectedColor: ColorFamily = .warm
    var selectedMood: GeneratorMood = .calm
    var detailLevel: Float = 0.5

    var isGenerating = false
    var progress: Double = 0
    var generatedImage: UIImage?
    var canGenerate = false
    var capabilityMessage: String?
    var isModelReady = false
    var isDownloadingModel = false
    var downloadProgress: Double = 0
    var modelSizeText: String?
    var errorMessage: String?
    var savedThemeId: String?

    // MARK: - Dependencies

    private let mlService: MLBackgroundServiceProtocol
    private let analyticsService: AnalyticsServiceProtocol
    private let logger = Logger(subsystem: "com.lumen.app", category: "ThemeGenerator")

    init(
        mlService: MLBackgroundServiceProtocol = MLBackgroundService.shared,
        analyticsService: AnalyticsServiceProtocol = AnalyticsService.shared
    ) {
        self.mlService = mlService
        self.analyticsService = analyticsService
    }

    // MARK: - Actions

    func checkDeviceCapability() async {
        let capability = mlService.checkCapability()
        switch capability {
        case .supported:
            canGenerate = true
            capabilityMessage = nil
        case .unsupported(let reason):
            canGenerate = false
            capabilityMessage = reason
        }

        isModelReady = await mlService.isModelReady()

        if let bytes = await mlService.modelSizeBytes() {
            modelSizeText = ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
        }
    }

    func downloadModel() async {
        isDownloadingModel = true
        downloadProgress = 0
        defer { isDownloadingModel = false }

        do {
            try await mlService.downloadModel { [weak self] progress in
                Task { @MainActor in
                    self?.downloadProgress = progress
                }
            }
            isModelReady = true
            logger.info("Model downloaded successfully")
        } catch {
            logger.error("Model download failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func deleteModel() async {
        do {
            try await mlService.deleteModel()
            isModelReady = false
            modelSizeText = nil
            logger.info("Model deleted")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func generate() async {
        isGenerating = true
        progress = 0
        generatedImage = nil
        savedThemeId = nil
        errorMessage = nil

        analyticsService.log(event: .backgroundGenerationStarted(style: selectedStyle.rawValue))

        let request = BackgroundGenerationRequest(
            styleId: selectedStyle,
            colorFamily: selectedColor,
            mood: selectedMood,
            detailLevel: detailLevel
        )

        do {
            let result = try await mlService.generate(request: request)

            // Load the generated image for preview
            if let imageData = try? Data(contentsOf: result.imagePath),
               let image = UIImage(data: imageData) {
                generatedImage = image
            }

            savedThemeId = result.themeId
            analyticsService.log(event: .backgroundGenerationCompleted(durationMs: result.metadata.durationMs))
            logger.info("Generated theme: \(result.themeId)")
        } catch is CancellationError {
            analyticsService.log(event: .backgroundGenerationCancelled)
        } catch {
            logger.error("Generation error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }

        isGenerating = false
    }

    func cancelGeneration() {
        mlService.cancelGeneration()
        isGenerating = false
    }

    func saveAsTheme(modelContext: ModelContext) {
        guard let themeId = savedThemeId else { return }

        do {
            let metadata = GenerationMetadata(
                model: "procedural",
                styleId: selectedStyle.rawValue,
                seed: 0,
                steps: 0,
                guidanceScale: 7.0,
                size: 512,
                prompt: "",
                durationMs: 0
            )
            let metadataJSON = try JSONEncoder().encode(metadata)

            let theme = AppTheme(
                id: themeId,
                name: "\(selectedStyle.rawValue.capitalized) \(selectedColor.rawValue.capitalized)",
                type: .generatedImage,
                isPremium: false,
                dataJSON: String(data: metadataJSON, encoding: .utf8) ?? "{}"
            )
            modelContext.insert(theme)
            try modelContext.save()
            logger.info("Theme saved: \(themeId)")
        } catch {
            errorMessage = "Couldn't save theme: \(error.localizedDescription)"
        }
    }
}
