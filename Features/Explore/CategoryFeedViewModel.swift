import Dependencies
import Foundation
import OSLog
import SwiftData
import SwiftUI
import UIKit

@MainActor @Observable
final class CategoryFeedViewModel {
    // MARK: - State

    var cards: [Affirmation] = []
    var currentIndex: Int = 0
    var categoryName: String = ""
    var isLoading = false
    var errorMessage: String?
    var editingAffirmation: Affirmation?
    var customizations: [String: CardCustomization] = [:]

    /// Background images keyed by affirmation id for random rotation.
    var cardBackgrounds: [String: UIImage] = [:]
    /// Active theme IDs for rotation.
    private var activeThemeIds: [String] = []

    var currentCard: Affirmation? {
        guard currentIndex >= 0, currentIndex < cards.count else { return nil }
        return cards[currentIndex]
    }

    // MARK: - Dependencies

    @ObservationIgnored @Dependency(\.favoriteService) private var favoriteService
    @ObservationIgnored @Dependency(\.shareService) private var shareService
    @ObservationIgnored @Dependency(\.cardCustomizationService) private var customizationService
    @ObservationIgnored @Dependency(\.feedService) private var feedService
    @ObservationIgnored @Dependency(\.backgroundGenerator) private var backgroundGenerator
    @ObservationIgnored @Dependency(\.widgetService) private var widgetService
    private let logger = Logger(subsystem: "com.gragera.lumen", category: "CategoryFeed")

    // MARK: - Actions

    func loadCategory(
        categoryId: String,
        preferences: UserPreferences,
        isPremium: Bool,
        modelContext: ModelContext
    ) async {
        // Load active theme IDs for rotation
        await loadActiveThemes(modelContext: modelContext)

        isLoading = true
        defer { isLoading = false }

        do {
            // Fetch category
            var catDescriptor = FetchDescriptor<Category>(
                predicate: #Predicate { $0.id == categoryId }
            )
            catDescriptor.fetchLimit = 1
            if let category = try modelContext.fetch(catDescriptor).first {
                categoryName = category.name
            }

            // Fetch affirmations for this category
            let gentleMode = preferences.gentleMode
            let includeSensitive = preferences.includeSensitiveTopics
            let descriptor = FetchDescriptor<Affirmation>()
            let allAffirmations = try modelContext.fetch(descriptor)

            cards = allAffirmations.filter { affirmation in
                let belongsToCategory = affirmation.categories?.contains { $0.id == categoryId } ?? false
                guard belongsToCategory else { return false }

                if affirmation.isSensitiveTopic && !includeSensitive { return false }
                if gentleMode && (affirmation.intensity == .high || affirmation.isAbsolute) { return false }
                if affirmation.isPremium && !isPremium { return false }

                return true
            }.shuffled()

            currentIndex = 0

            // Assign random backgrounds from active themes
            await assignBackgrounds(for: cards)
        } catch {
            logger.error("Category feed load error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func recordSeen(modelContext: ModelContext) {
        guard let card = currentCard else { return }
        do {
            try feedService.recordSeen(affirmation: card, source: .category, modelContext: modelContext)
        } catch {
            logger.error("Record seen error: \(error.localizedDescription)")
        }
    }

    func toggleFavorite(modelContext: ModelContext) {
        guard let card = currentCard else { return }
        do {
            try favoriteService.toggleFavorite(affirmation: card, modelContext: modelContext)
            let allFavs = try favoriteService.fetchFavorites(modelContext: modelContext)
            Task { await syncFavoritesWidgetBackground(modelContext: modelContext, allFavs: allFavs) }
        } catch {
            logger.error("Favorite error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func swipeToNext() {
        if currentIndex < cards.count - 1 {
            currentIndex += 1
        }
    }

    func swipeToPrevious() {
        if currentIndex > 0 {
            currentIndex -= 1
        }
    }

    // MARK: - Card Customizations

    func loadCustomizations(modelContext: ModelContext) {
        do {
            let all = try customizationService.allCustomizations(modelContext: modelContext)
            let cardIds = Set(cards.map(\.id))
            var map: [String: CardCustomization] = [:]
            for c in all where cardIds.contains(c.affirmationId) {
                map[c.affirmationId] = c
            }
            customizations = map
        } catch {
            logger.error("Failed to load customizations: \(error.localizedDescription)")
        }
    }

    func reloadCustomizations(modelContext: ModelContext) {
        let previousCustomizations = customizations
        loadCustomizations(modelContext: modelContext)

        // Regenerate backgrounds for cards whose customizations changed
        Task {
            for (affId, customization) in customizations {
                let changed =
                    previousCustomizations[affId]?.updatedAt != customization.updatedAt
                    || previousCustomizations[affId] == nil
                if changed {
                    await regenerateBackground(for: affId, customization: customization)
                }
            }
            // Also clear backgrounds for cards whose customizations were removed
            for affId in previousCustomizations.keys where customizations[affId] == nil {
                cardBackgrounds.removeValue(forKey: affId)
            }

            // Sync the favorites widget — a customization change in any feed may
            // affect a card that is also saved as a favorite.
            let descriptor = FetchDescriptor<Favorite>(sortBy: [SortDescriptor(\.favoritedAt, order: .reverse)])
            if let favorites = try? modelContext.fetch(descriptor) {
                let allFavs = favorites.compactMap { $0.affirmation }
                if !allFavs.isEmpty {
                    await syncFavoritesWidgetBackground(modelContext: modelContext, allFavs: allFavs)
                }
            }
        }
    }

    private func syncFavoritesWidgetBackground(modelContext: ModelContext, allFavs: [Affirmation]) async {
        let allCustoms = try? customizationService.allCustomizations(modelContext: modelContext)
        var map: [String: CardCustomization] = [:]
        if let allCustoms {
            for c in allCustoms { map[c.affirmationId] = c }
        }

        let themeDescriptor = FetchDescriptor<AppTheme>(
            predicate: #Predicate<AppTheme> { $0.isActive == true || $0.isActive == nil }
        )
        let themes = try? modelContext.fetch(themeDescriptor)
        let activeThemeIds = themes?.map(\.id) ?? []

        let loadRequests: [(affId: String, cachedPath: String?, themeId: String?)] = allFavs.map { aff in
            let custom = map[aff.id]
            if let cachedPath = custom?.cachedImagePath {
                return (aff.id, cachedPath, nil)
            }
            if let savedThemeId = custom?.savedThemeId {
                return (aff.id, nil, savedThemeId)
            }
            guard !activeThemeIds.isEmpty else { return (aff.id, nil, nil) }
            let themeId = activeThemeIds[abs(aff.id.hashValue) % activeThemeIds.count]
            return (aff.id, nil, themeId)
        }

        let customImageDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CardCustomizations", isDirectory: true)

        let backgrounds: [String: UIImage] = await Task.detached {
            var bgs: [String: UIImage] = [:]
            for req in loadRequests {
                if let cachedPath = req.cachedPath {
                    let fullPath = customImageDir.appendingPathComponent(cachedPath)
                    if let image = UIImage(contentsOfFile: fullPath.path) {
                        bgs[req.affId] = image
                        continue
                    }
                }
                if let themeId = req.themeId {
                    if let image = Self.loadThemeImage(themeId: themeId) {
                        bgs[req.affId] = image
                    }
                }
            }
            return bgs
        }.value

        let entries = allFavs.map { aff -> (text: String, fontStyle: String?, gradientColors: [String], backgroundImage: UIImage?, textColor: String?) in
            let custom = map[aff.id]
            let textToUse = (custom?.customText?.isEmpty == false) ? custom!.customText! : aff.text
            let index = abs(aff.id.hashValue) % LumenTheme.Colors.gradients.count
            let colors = LumenTheme.Colors.gradients[index].map { $0.hexString }
            let fontStyle = custom?.fontStyleOverride ?? aff.fontStyle
            return (text: textToUse, fontStyle: fontStyle, gradientColors: colors, backgroundImage: backgrounds[aff.id], textColor: custom?.textColor)
        }
        widgetService.updateFavoritesWidget(favorites: entries)
    }

    private func regenerateBackground(for affirmationId: String, customization: CardCustomization) async {
        // Check for a cached image first (from AI or procedural saves)
        if let cachedPath = customization.cachedImagePath {
            let fullPath = CardEditorViewModel.customizationImagesDir.appendingPathComponent(cachedPath)
            if let image = UIImage(contentsOfFile: fullPath.path) {
                cardBackgrounds[affirmationId] = image
                return
            }
        }

        // Fallback: regenerate procedurally
        guard let styleRaw = customization.backgroundStyle,
            let style = GeneratorStyle(rawValue: styleRaw),
            let paletteRaw = customization.colorPalette,
            let palette = ColorPalette(rawValue: paletteRaw)
        else { return }

        let seed = customization.backgroundSeed ?? 0
        let request = BackgroundRequest(
            style: style,
            palette: palette,
            mood: .calm,
            complexity: 0.5,
            seed: seed,
            size: CGSize(width: 1080, height: 1920)
        )

        do {
            let result = try await backgroundGenerator.generate(request: request)
            if let image = UIImage(contentsOfFile: result.imagePath.path) {
                cardBackgrounds[affirmationId] = image
            }
        } catch {
            logger.error(
                "Failed to regenerate background for \(affirmationId, privacy: .private): \(error.localizedDescription)"
            )
        }
    }

    func shareImage(isPremium: Bool) -> UIImage? {
        guard let card = currentCard else { return nil }
        let customization = customizations[card.id]
        
        let text = customization?.customText?.isEmpty == false ? customization!.customText! : card.text
        let bgImage = backgroundImage(for: card)
        
        // Gradient colors fallback
        let colors: [Color]
        if let paletteRaw = customization?.colorPalette, let palette = ColorPalette(rawValue: paletteRaw) {
            colors = palette.cgColors.map { Color(cgColor: $0) }
        } else {
            let index = abs(card.id.hashValue) % LumenTheme.Colors.gradients.count
            colors = LumenTheme.Colors.gradients[index]
        }

        // Font
        let fontStyle: AffirmationFontStyle
        if let overrideRaw = customization?.fontStyleOverride, let style = AffirmationFontStyle.from(overrideRaw) {
            fontStyle = style
        } else if let fontRaw = card.fontStyle, let style = AffirmationFontStyle.from(fontRaw) {
            fontStyle = style
        } else {
            // Deterministic random fallback matching FeedView
            let roll = abs(card.id.hashValue) % 10
            switch roll {
            case 0...3: fontStyle = .playfair
            case 4...5: fontStyle = .cormorant
            case 6: fontStyle = .zilla
            case 7: fontStyle = .abril
            case 8: fontStyle = .rounded
            default: fontStyle = .josefin
            }
        }
        let font = fontStyle.cardFont(textLength: text.count)
        
        // Letter spacing
        let letterSpacing: CGFloat
        switch fontStyle {
        case .josefin: letterSpacing = 1.5
        case .abril, .playfair: letterSpacing = 0.3
        case .zilla: letterSpacing = 0.2
        default: letterSpacing = 0.5
        }

        return shareService.renderShareImage(
            text: text,
            font: font,
            letterSpacing: letterSpacing,
            gradientColors: colors,
            backgroundImage: bgImage,
            size: CGSize(width: 360, height: 640),
            showWatermark: !isPremium
        )
    }

    func backgroundImage(for affirmation: Affirmation) -> UIImage? {
        cardBackgrounds[affirmation.id]
    }

    // MARK: - Theme Rotation

    /// Load active theme IDs from SwiftData.
    private func loadActiveThemes(modelContext: ModelContext) async {
        do {
            let descriptor = FetchDescriptor<AppTheme>(
                predicate: #Predicate<AppTheme> { $0.isActive == true || $0.isActive == nil }
            )
            let themes = try modelContext.fetch(descriptor)
            ThemeSyncService.syncToDisk(themes: themes)
            activeThemeIds = themes.map(\.id)
            logger.info("Loaded \(themes.count) active themes for rotation")
        } catch {
            logger.error("Failed to load active themes: \(error.localizedDescription)")
            activeThemeIds = []
        }
    }

    /// Assign a background image to each card, preferring customizations.
    private func assignBackgrounds(for affirmations: [Affirmation]) async {
        guard !activeThemeIds.isEmpty else {
            cardBackgrounds = [:]
            return
        }

        let themeIds = activeThemeIds
        let loadRequests: [(affId: String, cachedPath: String?, themeId: String?)] = affirmations.map { aff in
            let custom = customizations[aff.id]
            if let cachedPath = custom?.cachedImagePath {
                return (aff.id, cachedPath, nil)
            }
            if let savedThemeId = custom?.savedThemeId {
                return (aff.id, nil, savedThemeId)
            }
            let themeId = themeIds[abs(aff.id.hashValue) % themeIds.count]
            return (aff.id, nil, themeId)
        }

        // Load images off main thread
        let loaded: [String: UIImage] = await Task.detached {
            var backgrounds: [String: UIImage] = [:]
            let customImageDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("CardCustomizations", isDirectory: true)

            for req in loadRequests {
                if let cachedPath = req.cachedPath {
                    let fullPath = customImageDir.appendingPathComponent(cachedPath)
                    if let image = UIImage(contentsOfFile: fullPath.path) {
                        backgrounds[req.affId] = image
                        continue
                    }
                }
                if let themeId = req.themeId {
                    if let image = Self.loadThemeImage(themeId: themeId) {
                        backgrounds[req.affId] = image
                    }
                }
            }
            return backgrounds
        }.value

        cardBackgrounds = loaded
    }

    /// Resolve a theme image from disk (generated or AI).
    private nonisolated static func loadThemeImage(themeId: String) -> UIImage? {
        let searchDirs: [URL] = [
            FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.gragera.lumen")?
                .appendingPathComponent("themes/generated"),
            FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.gragera.lumen")?
                .appendingPathComponent("themes/ai"),
            FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.gragera.lumen")?
                .appendingPathComponent("themes/photos"),
            FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
                .appendingPathComponent("themes/generated"),
            FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
                .appendingPathComponent("themes/ai"),
            FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
                .appendingPathComponent("themes/photos"),
        ].compactMap { $0 }

        let extensions = ["png", "jpg"]

        for dir in searchDirs {
            for ext in extensions {
                let imagePath = dir.appendingPathComponent("\(themeId).\(ext)")
                if let data = try? Data(contentsOf: imagePath), let image = UIImage(data: data) {
                    // Downscale to screen size
                    let screenScale = 2.0
                    let targetWidth = 430.0 * screenScale
                    let scale = targetWidth / image.size.width
                    let targetSize = CGSize(width: targetWidth, height: image.size.height * scale)
                    let renderer = UIGraphicsImageRenderer(size: targetSize)
                    return renderer.image { _ in
                        image.draw(in: CGRect(origin: .zero, size: targetSize))
                    }
                }
            }
        }

        // Fallback for bundled curated backgrounds like 'ai_bg_morning_veil'
        if let bundled = UIImage(named: themeId) {
            return bundled
        }

        return nil
    }
}
