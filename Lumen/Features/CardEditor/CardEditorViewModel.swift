import Dependencies
import NaturalLanguage
import OSLog
import SwiftData
import UIKit

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
        case saved = "My Backgrounds"
        case ai = "AI ✨"

        var id: String { rawValue }
    }

    /// A saved background thumbnail for the picker.
    struct SavedBackgroundItem: Identifiable {
        let id: String  // themeId
        let thumbnail: UIImage
        let fullImagePath: URL
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
    let isCreatingNew: Bool

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
    var errorMessage: String?
    var savedBackgrounds: [SavedBackgroundItem] = []
    var selectedSavedBackground: SavedBackgroundItem?
    
    // Paywall trigger
    var showPaywallPrompt = false
    
    // ML Suggestions
    var suggestions: [String] = []
    var isLoadingSuggestions = false

    /// Path to the last generated image (for caching on save).
    private var lastGeneratedImagePath: URL?
    private var generatedThemeId: String?

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
            || selectedSavedBackground?.id != initialSavedThemeId
    }

    // MARK: - Private

    @ObservationIgnored @Dependency(\.cardCustomizationService) private var customizationService
    @ObservationIgnored @Dependency(\.backgroundGenerator) private var backgroundGenerator
    @ObservationIgnored @Dependency(\.aiBackgroundService) private var aiGenerator
    @ObservationIgnored @Dependency(\.entitlementService) private var entitlementService

    private let initialMode: BackgroundMode
    private let initialStyle: GeneratorStyle
    private let initialPalette: ColorPalette
    private let initialFontStyle: AffirmationFontStyle?
    private let initialCustomText: String
    private let initialSeed: UInt32
    private let initialPromptId: String?
    private let initialSavedThemeId: String?

    // MARK: - Init

    init(
        affirmation: Affirmation,
        existingCustomization: CardCustomization?,
        isCreatingNew: Bool = false
    ) {
        self.affirmation = affirmation
        self.isCreatingNew = isCreatingNew

        let usesAI = existingCustomization?.usesAIBackground ?? false
        let savedThemeId = existingCustomization?.savedThemeId
        let mode: BackgroundMode = savedThemeId != nil ? .saved : (usesAI ? .ai : .procedural)
        let style =
            existingCustomization?.backgroundStyle
            .flatMap(GeneratorStyle.init(rawValue:)) ?? Self.defaultStyle(for: affirmation)
        let palette =
            existingCustomization?.colorPalette
            .flatMap(ColorPalette.init(rawValue:)) ?? Self.defaultPalette(for: affirmation)
        let fontStyle =
            existingCustomization?.fontStyleOverride
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
        self.initialSavedThemeId = savedThemeId
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

    /// Load saved backgrounds from the themes directories.
    func loadSavedBackgrounds() async {
        let items = await Task.detached { () -> [SavedBackgroundItem] in
            var items: [SavedBackgroundItem] = []

            let searchDirs: [URL] = [
                FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
                    .appendingPathComponent("themes/generated"),
                FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
                    .appendingPathComponent("themes/ai"),
                FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.gragera.lumen")?
                    .appendingPathComponent("themes/generated"),
                FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.gragera.lumen")?
                    .appendingPathComponent("themes/ai"),
            ].compactMap { $0 }

            let fm = FileManager.default
            for dir in searchDirs {
                guard let files = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else { continue }
                for file in files where file.pathExtension == "png" || file.pathExtension == "jpg" {
                    let themeId = file.deletingPathExtension().lastPathComponent
                    // Skip thumbnails
                    guard !themeId.hasSuffix("_thumb") else { continue }
                    // Load thumbnail if exists, else use full image scaled down
                    let thumbFilename = "\(themeId)_thumb.\(file.pathExtension)"
                    let thumbPath = file.deletingLastPathComponent().appendingPathComponent(thumbFilename)
                    let thumb: UIImage?
                    if fm.fileExists(atPath: thumbPath.path), let t = UIImage(contentsOfFile: thumbPath.path) {
                        thumb = t
                    } else if let data = try? Data(contentsOf: file),
                        let full = UIImage(data: data)
                    {
                        thumb = full.preparingThumbnail(of: CGSize(width: 120, height: 120))
                    } else {
                        continue
                    }
                    guard let thumbnail = thumb else { continue }
                    items.append(SavedBackgroundItem(id: themeId, thumbnail: thumbnail, fullImagePath: file))
                }
            }
            return items
        }.value

        savedBackgrounds = items

        // Restore selection if editing an existing customization with a saved theme
        if let savedId = initialSavedThemeId {
            selectedSavedBackground = items.first { $0.id == savedId }
        }
    }

    /// Select a saved background as the card's background.
    func selectSavedBackground(_ item: SavedBackgroundItem) {
        selectedSavedBackground = item
        if let image = UIImage(contentsOfFile: item.fullImagePath.path) {
            previewImage = image
            lastGeneratedImagePath = item.fullImagePath
        }
    }

    /// Generates a preview background image from the current selections.
    func generatePreview() async {
        isGeneratingPreview = true
        defer { isGeneratingPreview = false }

        switch backgroundMode {
        case .procedural:
            await generateProceduralPreview()
        case .saved:
            break  // Saved backgrounds are loaded directly, no generation needed
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
        customization.savedThemeId = backgroundMode == .saved ? selectedSavedBackground?.id : nil
        try customizationService.save(customization, modelContext: modelContext)

        if let fontStyle = selectedFontStyle {
            affirmation.fontStyle = fontStyle.rawValue
        }
        if canEditText {
            affirmation.text = customText
        }
        
        // If creating a brand new affirmation, insert it and favorite it!
        if isCreatingNew {
            modelContext.insert(affirmation)
            let favorite = Favorite(affirmation: affirmation)
            modelContext.insert(favorite)
        }
        
        // Also save to global Themes if this is a newly generated AI background!
        if backgroundMode == .ai, let themeId = generatedThemeId {
            let prompt = selectedPrompt ?? .random(category: selectedPromptCategory)
            let theme = AppTheme(
                id: themeId,
                name: "AI Background",
                type: .generatedImage,
                isPremium: true,
                dataJSON: "{\"promptId\":\"\(prompt.id)\"}",
                isActive: true
            )
            modelContext.insert(theme)
            customization.savedThemeId = themeId
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
        // AI backgrounds are premium-only
        let isPremium = await entitlementService.isPremium()
        if !isPremium {
            showPaywallPrompt = true
            return
        }

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
            generatedThemeId = result.themeId
            Logger.viewModel.info("Generated AI preview (ID: \(result.themeId, privacy: .private))")
        } catch is CancellationError {
            Logger.viewModel.info("AI preview cancelled")
        } catch {
            Logger.viewModel.error("AI preview failed: \(error.localizedDescription)")
            let desc = String(describing: error)
            errorMessage = "AI generation failed: \(desc.prefix(200))"
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
        guard let contents = try? fm.contentsOfDirectory(at: customizationImagesDir, includingPropertiesForKeys: nil)
        else { return }
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

    // MARK: - ML Suggestions

    func loadSuggestions(modelContext: ModelContext) async {
        guard isCreatingNew else { return }
        isLoadingSuggestions = true
        defer { isLoadingSuggestions = false }

        // Fetch favorited affirmation texts
        let favoriteTexts = fetchFavoriteTexts(modelContext: modelContext)
        guard favoriteTexts.count >= 3 else { return }

        // Use NaturalLanguage embedding to find themes in favorites
        await generateSuggestions(from: favoriteTexts)
    }

    private func fetchFavoriteTexts(modelContext: ModelContext) -> [String] {
        do {
            let descriptor = FetchDescriptor<Favorite>(
                sortBy: [SortDescriptor(\.favoritedAt, order: .reverse)]
            )
            let favorites = try modelContext.fetch(descriptor)
            return favorites.compactMap { $0.affirmation?.text }.prefix(20).map { $0 }
        } catch {
            return []
        }
    }

    private func generateSuggestions(from favoriteTexts: [String]) async {
        var starters: [String: Int] = [:]
        var themes: [String] = []
        let tagger = NLTagger(tagSchemes: [.lemma, .nameType])

        for text in favoriteTexts {
            let words = text.split(separator: " ").prefix(3).joined(separator: " ")
            if words.count > 2 {
                starters[words, default: 0] += 1
            }

            tagger.string = text
            tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lemma) { tag, range in
                if let lemma = tag?.rawValue, lemma.count > 3 {
                    let word = String(text[range]).lowercased()
                    if !Self.stopWords.contains(word) && !Self.stopWords.contains(lemma.lowercased()) {
                        themes.append(lemma)
                    }
                }
                return true
            }
        }

        let themeCounts = Dictionary(themes.map { ($0, 1) }, uniquingKeysWith: +)
        let topThemes = themeCounts.sorted { $0.value > $1.value }.prefix(5).map { $0.key }
        var generated: [String] = []

        let templates = [
            "I embrace my {theme} with gratitude",
            "Every day, my {theme} grows stronger",
            "I am worthy of {theme} and joy",
            "My {theme} inspires those around me",
            "I choose {theme} in every moment",
        ]

        for (i, theme) in topThemes.prefix(3).enumerated() {
            if i < templates.count {
                let suggestion = templates[i].replacingOccurrences(of: "{theme}", with: theme.lowercased())
                generated.append(suggestion)
            }
        }

        let topStarters = starters.sorted { $0.value > $1.value }.prefix(2)
        for starter in topStarters {
            if !generated.contains(where: { $0.hasPrefix(starter.key) }) {
                if let theme = topThemes.first {
                    generated.append("\(starter.key) \(theme.lowercased()) guides my path")
                }
            }
        }

        suggestions = Array(generated.prefix(5))
    }

    private static let stopWords: Set<String> = [
        "i", "my", "me", "am", "is", "are", "the", "a", "an", "and", "or",
        "to", "in", "of", "for", "with", "that", "this", "have", "has",
        "can", "will", "do", "be", "it", "not", "but", "all", "each",
        "every", "from", "into", "through", "than", "more", "most",
        "own", "being", "been", "was", "were", "their", "them", "they",
    ]
}
