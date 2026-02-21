import UIKit
import SwiftData
import OSLog

// MARK: - CardEditorViewModel

/// Manages card customization state — background style, palette, font, and text.
///
/// Initializes from an existing ``CardCustomization`` if present,
/// otherwise derives sensible defaults from the affirmation itself.
@MainActor @Observable
final class CardEditorViewModel {

    // MARK: - Public State

    let affirmation: Affirmation

    var selectedStyle: GeneratorStyle
    var selectedPalette: ColorPalette
    var selectedFontStyle: AffirmationFontStyle?
    var customText: String
    var backgroundSeed: UInt32

    var previewImage: UIImage?
    var isGeneratingPreview: Bool = false

    /// Only user-authored affirmations allow text editing.
    var canEditText: Bool { affirmation.source == .user }

    /// `true` when any property differs from the initial snapshot.
    var hasChanges: Bool {
        selectedStyle != initialStyle
            || selectedPalette != initialPalette
            || selectedFontStyle != initialFontStyle
            || customText != initialCustomText
            || backgroundSeed != initialSeed
    }

    // MARK: - Private

    private let customizationService: any CardCustomizationServiceProtocol
    private let backgroundGenerator: any BackgroundGeneratorProtocol

    private let initialStyle: GeneratorStyle
    private let initialPalette: ColorPalette
    private let initialFontStyle: AffirmationFontStyle?
    private let initialCustomText: String
    private let initialSeed: UInt32

    // MARK: - Init

    init(
        affirmation: Affirmation,
        existingCustomization: CardCustomization?,
        customizationService: some CardCustomizationServiceProtocol = CardCustomizationService.shared,
        backgroundGenerator: some BackgroundGeneratorProtocol = BackgroundGeneratorService.shared
    ) {
        self.affirmation = affirmation
        self.customizationService = customizationService
        self.backgroundGenerator = backgroundGenerator

        // Derive defaults from existing customization or affirmation metadata
        let style = existingCustomization?.backgroundStyle
            .flatMap(GeneratorStyle.init(rawValue:)) ?? Self.defaultStyle(for: affirmation)
        let palette = existingCustomization?.colorPalette
            .flatMap(ColorPalette.init(rawValue:)) ?? Self.defaultPalette(for: affirmation)
        let fontStyle = existingCustomization?.fontStyleOverride
            .flatMap(AffirmationFontStyle.init(rawValue:))
            ?? affirmation.fontStyle.flatMap(AffirmationFontStyle.init(rawValue:))
        let text = existingCustomization?.customText ?? affirmation.text
        let seed = existingCustomization?.backgroundSeed ?? Self.defaultSeed(for: affirmation)

        self.selectedStyle = style
        self.selectedPalette = palette
        self.selectedFontStyle = fontStyle
        self.customText = text
        self.backgroundSeed = seed

        self.initialStyle = style
        self.initialPalette = palette
        self.initialFontStyle = fontStyle
        self.initialCustomText = text
        self.initialSeed = seed
    }

    // MARK: - Actions

    /// Generates a preview background image from the current selections.
    func generatePreview() async {
        isGeneratingPreview = true
        defer { isGeneratingPreview = false }

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
            Logger.viewModel.error("Preview generation failed: \(error.localizedDescription)")
        }
    }

    /// Persists a ``CardCustomization`` record for the current selections.
    func save(modelContext: ModelContext) throws {
        // Delete any existing customization first to avoid duplicates
        try customizationService.delete(for: affirmation.id, modelContext: modelContext)

        let customization = CardCustomization(
            affirmationId: affirmation.id,
            backgroundStyle: selectedStyle.rawValue,
            colorPalette: selectedPalette.rawValue,
            backgroundSeed: backgroundSeed,
            fontStyleOverride: selectedFontStyle?.rawValue,
            customText: canEditText ? customText : nil
        )
        try customizationService.save(customization, modelContext: modelContext)

        // Also update the affirmation's fontStyle if changed
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

        selectedStyle = Self.defaultStyle(for: affirmation)
        selectedPalette = Self.defaultPalette(for: affirmation)
        selectedFontStyle = affirmation.fontStyle.flatMap(AffirmationFontStyle.init(rawValue:))
        customText = affirmation.text
        backgroundSeed = Self.defaultSeed(for: affirmation)

        Logger.viewModel.debug("Reset card customization for \(self.affirmation.id, privacy: .private)")
    }

    /// Randomizes the background seed and triggers a preview regeneration.
    func randomizeSeed() {
        backgroundSeed = UInt32.random(in: 0...UInt32.max)
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
