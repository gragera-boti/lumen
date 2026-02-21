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
    var aiModelReady: Bool = false
    var aiLoadingPhase: String = ""
    var aiLoadProgress: Double = 0
    var isLoadingAIModel: Bool = false

    var previewImage: UIImage?
    var isGeneratingPreview: Bool = false

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

        // Derive defaults from existing customization or affirmation metadata
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

        self.initialMode = mode
        self.initialStyle = style
        self.initialPalette = palette
        self.initialFontStyle = fontStyle
        self.initialCustomText = text
        self.initialSeed = seed
        self.initialPromptId = promptId
    }

    // MARK: - Actions

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

    /// Check if the AI model is available.
    func checkAIModelStatus() async {
        aiModelReady = await aiGenerator.isModelReady()
    }

    /// Load the AI model for generation.
    func loadAIModel() async {
        guard !isLoadingAIModel else { return }
        isLoadingAIModel = true
        defer { isLoadingAIModel = false }

        aiGenerator.setLoadPhaseHandler { [weak self] phase, progress in
            Task { @MainActor in
                self?.aiLoadingPhase = phase
                self?.aiLoadProgress = progress
            }
        }

        do {
            try await aiGenerator.loadModel()
            aiModelReady = true
        } catch {
            Logger.viewModel.error("AI model load failed: \(error.localizedDescription)")
        }
    }

    /// Persists a ``CardCustomization`` record for the current selections.
    func save(modelContext: ModelContext) throws {
        try customizationService.delete(for: affirmation.id, modelContext: modelContext)

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
            size: CGSize(width: 512, height: 512)
        )

        do {
            let result = try await backgroundGenerator.generate(request: request)
            previewImage = UIImage(contentsOfFile: result.imagePath.path)
        } catch {
            Logger.viewModel.error("Procedural preview failed: \(error.localizedDescription)")
        }
    }

    private func generateAIPreview() async {
        if !aiModelReady {
            await loadAIModel()
            guard aiModelReady else { return }
        }

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
        } catch {
            Logger.viewModel.error("AI preview failed: \(error.localizedDescription)")
        }
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
