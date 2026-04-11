import Dependencies
import OSLog
import SwiftData
import SwiftUI
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
        let fullImagePath: URL?
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
    var selectedTextColor: Color
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

    /// Raw data for the custom photo to save directly without compression.
    var customPhotoData: Data?
    var newlySelectedPhoto: Bool = false
    var isCurrentSelectionCustomPhoto: Bool = false

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
            || selectedTextColor != initialTextColor
            || customText != initialCustomText
            || backgroundSeed != initialSeed
            || selectedPrompt?.id != initialPromptId
            || selectedSavedBackground?.id != initialSavedThemeId
            || isCurrentSelectionCustomPhoto != initialIsCustomPhoto
            || newlySelectedPhoto
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
    private let initialTextColor: Color
    private let initialCustomText: String
    private let initialSeed: UInt32
    private let initialPromptId: String?
    private let initialSavedThemeId: String?
    private let initialIsCustomPhoto: Bool

    // MARK: - Init

    init(
        affirmation: Affirmation,
        existingCustomization: CardCustomization?,
        isCreatingNew: Bool = false
    ) {
        self.affirmation = affirmation
        self.isCreatingNew = isCreatingNew

        let usesAI = existingCustomization?.usesAIBackground ?? false
        let isCustomPhoto = existingCustomization?.isCustomPhoto ?? false
        let savedThemeId = existingCustomization?.savedThemeId
        let mode: BackgroundMode = (isCustomPhoto || savedThemeId != nil) ? .saved : (usesAI ? .ai : .procedural)
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

        let textColor = existingCustomization?.textColor.map { Color(hex: $0) } ?? .white
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
        self.selectedTextColor = textColor
        self.customText = text
        self.backgroundSeed = seed
        self.selectedPrompt = resolvedPrompt
        if let resolvedPrompt {
            self.selectedPromptCategory = resolvedPrompt.category
        }
        self.isCurrentSelectionCustomPhoto = isCustomPhoto

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
        self.initialTextColor = textColor
        self.initialCustomText = text
        self.initialSeed = seed
        self.initialPromptId = promptId
        self.initialSavedThemeId = savedThemeId
        self.initialIsCustomPhoto = isCustomPhoto
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

    /// Load saved backgrounds from the database and resolve their image paths.
    func loadSavedBackgrounds(modelContext: ModelContext) async {
        do {
            let descriptor = FetchDescriptor<AppTheme>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            let allThemes = try modelContext.fetch(descriptor)
            let themes = allThemes.filter { $0.type == .curatedImage || $0.type == .generatedImage || $0.type == .customPhoto }
            
            // Extract lightweight values to avoid Swift 6 concurrency boundary checking errors with AppTheme models
            let themeData = themes.map { (id: $0.id, isCurated: $0.type == .curatedImage) }

            let items = await Task.detached { () -> [SavedBackgroundItem] in
                var results: [SavedBackgroundItem] = []
                let fm = FileManager.default

                let dirs: [URL] = [
                    fm.containerURL(forSecurityApplicationGroupIdentifier: "group.com.gragera.lumen")?
                        .appendingPathComponent("themes/ai"),
                    fm.containerURL(forSecurityApplicationGroupIdentifier: "group.com.gragera.lumen")?
                        .appendingPathComponent("themes/generated"),
                    fm.containerURL(forSecurityApplicationGroupIdentifier: "group.com.gragera.lumen")?
                        .appendingPathComponent("themes/photos"),
                    fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
                        .appendingPathComponent("themes/ai"),
                    fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
                        .appendingPathComponent("themes/generated"),
                    fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
                        .appendingPathComponent("themes/photos"),
                ].compactMap { $0 }

                for data in themeData {
                    // Try to load a bundled asset if it's curated
                    if data.isCurated, let image = UIImage(named: data.id) {
                        // For curated images, just pass down the original image. The view can use it directly.
                        results.append(SavedBackgroundItem(id: data.id, thumbnail: image, fullImagePath: nil))
                        continue
                    }

                    // For generated themes, find the file on disk
                    var resolvedURL: URL? = nil
                    var thumbnailImg: UIImage? = nil

                    for dir in dirs {
                        let jpgFile = dir.appendingPathComponent("\(data.id).jpg")
                        let pngFile = dir.appendingPathComponent("\(data.id).png")

                        if fm.fileExists(atPath: jpgFile.path) { resolvedURL = jpgFile }
                        else if fm.fileExists(atPath: pngFile.path) { resolvedURL = pngFile }

                        if let url = resolvedURL {
                            let thumbJpg = dir.appendingPathComponent("\(data.id)_thumb.jpg")
                            let thumbPng = dir.appendingPathComponent("\(data.id)_thumb.png")

                            if fm.fileExists(atPath: thumbJpg.path), let t = UIImage(contentsOfFile: thumbJpg.path) {
                                thumbnailImg = t
                            } else if fm.fileExists(atPath: thumbPng.path), let t = UIImage(contentsOfFile: thumbPng.path) {
                                thumbnailImg = t
                            } else if let data = try? Data(contentsOf: url), let full = UIImage(data: data) {
                                thumbnailImg = full.preparingThumbnail(of: CGSize(width: 120, height: 120))
                            }
                            break // Found the file
                        }
                    }

                    if let thumb = thumbnailImg {
                        results.append(SavedBackgroundItem(id: data.id, thumbnail: thumb, fullImagePath: resolvedURL))
                    }
                }
                return results
            }.value

            savedBackgrounds = items

            // Restore selection if editing an existing customization with a saved theme
            if let savedId = initialSavedThemeId {
                selectedSavedBackground = items.first { $0.id == savedId }
            }
        } catch {
            Logger.viewModel.error("Failed to load AppThemes for My Backgrounds: \(error.localizedDescription)")
        }
    }

    /// Select a saved background as the card's background.
    func selectSavedBackground(_ item: SavedBackgroundItem) {
        selectedSavedBackground = item
        isCurrentSelectionCustomPhoto = false
        customPhotoData = nil
        newlySelectedPhoto = false
        
        if let path = item.fullImagePath {
            if let image = UIImage(contentsOfFile: path.path) {
                previewImage = image
                lastGeneratedImagePath = path
            }
        } else {
            // Treat as bundled curated image
            if let image = UIImage(named: item.id) {
                previewImage = image
                lastGeneratedImagePath = nil
            }
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
            break  // Saved or photo backgrounds are loaded directly, no generation needed
        case .ai:
            await generateAIPreview()
        }
    }

    /// Persists a ``CardCustomization`` record and caches the background image.
    func save(modelContext: ModelContext) throws {
        try customizationService.delete(for: affirmation.id, modelContext: modelContext)

        // Cache the preview image to persistent storage
        var relativePath: String?
        if backgroundMode == .saved, isCurrentSelectionCustomPhoto, let customData = customPhotoData {
            relativePath = try Self.cacheRawData(customData, for: affirmation.id)
            
            // If it's a completely new photo, save it as a global Theme as well!
            if newlySelectedPhoto {
                let themeId = "photo_\(UUID().uuidString)"
                generatedThemeId = themeId
                
                if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.gragera.lumen") {
                    let photosDir = appGroupURL.appendingPathComponent("themes").appendingPathComponent("photos")
                    try? FileManager.default.createDirectory(at: photosDir, withIntermediateDirectories: true)
                    let imagePath = photosDir.appendingPathComponent("\(themeId).jpg")
                    try? customData.write(to: imagePath)
                    
                    if let img = UIImage(data: customData), let thumbData = img.preparingThumbnail(of: CGSize(width: 120, height: 120))?.jpegData(compressionQuality: 0.7) {
                        let thumbPath = photosDir.appendingPathComponent("\(themeId)_thumb.jpg")
                        try? thumbData.write(to: thumbPath)
                    }
                }
            }
        } else if let _ = previewImage, let lastPath = lastGeneratedImagePath {
            relativePath = try Self.cacheImage(from: lastPath, for: affirmation.id)
        } else if let image = previewImage {
            // Fallback: save from UIImage directly
            relativePath = try Self.cacheImageData(image, for: affirmation.id)
        }

        let textColorHex = selectedTextColor == .white ? nil : selectedTextColor.hexString
        let customization = CardCustomization(
            affirmationId: affirmation.id,
            backgroundStyle: selectedStyle.rawValue,
            colorPalette: selectedPalette.rawValue,
            backgroundSeed: backgroundSeed,
            fontStyleOverride: selectedFontStyle?.rawValue,
            aiPromptId: selectedPrompt?.id,
            usesAIBackground: backgroundMode == .ai,
            isCustomPhoto: backgroundMode == .saved && isCurrentSelectionCustomPhoto,
            customText: canEditText ? customText : nil,
            textColor: textColorHex
        )
        customization.cachedImagePath = relativePath
        customization.savedThemeId = (backgroundMode == .saved && !isCurrentSelectionCustomPhoto) ? selectedSavedBackground?.id : nil
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
        
        // Also save to global Themes if this is a newly generated AI background or custom photo!
        if let themeId = generatedThemeId {
            if backgroundMode == .ai {
                let prompt = selectedPrompt ?? .random(category: selectedPromptCategory)
                var imgData: Data?
                var thumbData: Data?
                if let path = lastGeneratedImagePath, let data = try? Data(contentsOf: path) {
                    imgData = data
                    if let img = UIImage(data: data) {
                        thumbData = img.preparingThumbnail(of: CGSize(width: 120, height: 120))?.jpegData(compressionQuality: 0.7)
                    }
                }
                
                let theme = AppTheme(
                    id: themeId,
                    name: "AI Background",
                    type: .generatedImage,
                    isPremium: true,
                    dataJSON: "{\"promptId\":\"\(prompt.id)\"}",
                    isActive: true,
                    imageData: imgData,
                    thumbnailData: thumbData
                )
                modelContext.insert(theme)
                customization.savedThemeId = themeId
            } else if backgroundMode == .saved && isCurrentSelectionCustomPhoto {
                var thumbData: Data?
                if let customData = customPhotoData, let img = UIImage(data: customData) {
                    thumbData = img.preparingThumbnail(of: CGSize(width: 120, height: 120))?.jpegData(compressionQuality: 0.7)
                }
                
                let theme = AppTheme(
                    id: themeId,
                    name: "Custom Photo",
                    type: .customPhoto,
                    isPremium: false,
                    dataJSON: "{}",
                    isActive: true,
                    imageData: customPhotoData,
                    thumbnailData: thumbData
                )
                modelContext.insert(theme)
                customization.savedThemeId = themeId
                customization.isCustomPhoto = false
            }
        }

        try? modelContext.save()

        Logger.viewModel.debug("Saved card customization for \(self.affirmation.id, privacy: .private)")
    }

    /// Removes the customization record, reverting the card to defaults.
    func resetToDefaults(modelContext: ModelContext) throws {
        try customizationService.delete(for: affirmation.id, modelContext: modelContext)

        backgroundMode = .procedural
        selectedStyle = Self.defaultStyle(for: affirmation)
        selectedPalette = Self.defaultPalette(for: affirmation)
        selectedFontStyle = affirmation.fontStyle.flatMap(AffirmationFontStyle.init(rawValue:))
        selectedTextColor = .white
        customText = affirmation.text
        backgroundSeed = Self.defaultSeed(for: affirmation)
        selectedPrompt = nil
        previewImage = nil
        lastGeneratedImagePath = nil
        customPhotoData = nil
        newlySelectedPhoto = false
        isCurrentSelectionCustomPhoto = false

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
        if ProcessInfo.processInfo.arguments.contains("-UITesting") {
            if let image = UIImage(named: "ai_bg_pastel_skies") {
                self.previewImage = image
                self.lastGeneratedImagePath = nil
                self.isGeneratingPreview = false
                return
            }
        }
        
        // AI backgrounds are premium-only
        let isPremium = await entitlementService.isPremium()
        if !isPremium && !ProcessInfo.processInfo.arguments.contains("-UITesting") {
            showPaywallPrompt = true
            return
        }

        guard isModelReady || ProcessInfo.processInfo.arguments.contains("-UITesting") else { return }

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

    /// Loads custom photo data directly, preserving its raw image bytes.
    func loadCustomPhoto(data: Data) {
        if let image = UIImage(data: data) {
            previewImage = image
            lastGeneratedImagePath = nil
            customPhotoData = data
            newlySelectedPhoto = true
            isCurrentSelectionCustomPhoto = true
            selectedSavedBackground = nil
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

    private static func cacheRawData(_ data: Data, for affirmationId: String) throws -> String {
        let filename = "\(affirmationId)_\(Int(Date().timeIntervalSince1970)).png"
        let destPath = customizationImagesDir.appendingPathComponent(filename)
        cleanOldCaches(for: affirmationId)
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

        do {
            let favDescriptor = FetchDescriptor<Favorite>(
                sortBy: [SortDescriptor(\.favoritedAt, order: .reverse)]
            )
            let favorites = try modelContext.fetch(favDescriptor)
            
            let favoriteAffirmations = favorites.compactMap { $0.affirmation }
            let favoriteIDs = Set(favoriteAffirmations.map { $0.id })
            
            // Gather most common tags from favorites
            var tagCounts: [String: Int] = [:]
            for aff in favoriteAffirmations {
                for tag in aff.tags {
                    tagCounts[tag, default: 0] += 1
                }
            }
            
            let topTags = Set(tagCounts.sorted { $0.value > $1.value }.prefix(5).map { $0.key })
            
            // Fetch curated affirmations to find matches
            let allAffDescriptor = FetchDescriptor<Affirmation>()
            let allAffirmations = try modelContext.fetch(allAffDescriptor)
            
            var rankedSuggestions: [(text: String, score: Int)] = []
            var fallbackSuggestions: [String] = []
            
            for aff in allAffirmations {
                // Must be curated and not already favorited
                guard aff.source == .curated, !favoriteIDs.contains(aff.id) else { continue }
                fallbackSuggestions.append(aff.text)
                
                let matches = Set(aff.tags).intersection(topTags)
                if !matches.isEmpty {
                    rankedSuggestions.append((text: aff.text, score: matches.count))
                }
            }
            
            // Sort by score, then slightly shuffle top ones
            rankedSuggestions.sort { $0.score > $1.score }
            let bestMatches = rankedSuggestions.prefix(15)
            
            var chosen = Array(bestMatches.map { $0.text }.shuffled().prefix(5))
            
            if chosen.isEmpty {
                // If no tag matches, provide random fallback ones
                chosen = Array(fallbackSuggestions.shuffled().prefix(5))
            }
            
            self.suggestions = chosen
        } catch {
            Logger.viewModel.error("Failed to load ML suggestions: \(error.localizedDescription)")
        }
    }
}
