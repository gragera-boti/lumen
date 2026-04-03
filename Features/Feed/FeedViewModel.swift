import Dependencies
import Foundation
import OSLog
import SwiftData
import SwiftUI
import UIKit

@MainActor @Observable
final class FeedViewModel {
    // MARK: - State

    var cards: [Affirmation] = []
    var currentIndex: Int = 0
    var dailyAffirmation: Affirmation?
    var isLoading = false
    var errorMessage: String?
    var showRelaxFiltersPrompt = false
    var favoritedIds: Set<String> = []

    /// Background images keyed by affirmation id for random rotation.
    var cardBackgrounds: [String: UIImage] = [:]
    /// Active theme IDs for rotation.
    private var activeThemeIds: [String] = []

    /// The affirmation currently being edited in the CardEditor sheet.
    var editingAffirmation: Affirmation?

    /// Card customizations keyed by affirmation id.
    var customizations: [String: CardCustomization] = [:]

    var currentCard: Affirmation? {
        guard currentIndex >= 0, currentIndex < cards.count else { return nil }
        return cards[currentIndex]
    }

    // MARK: - Dependencies

    @ObservationIgnored @Dependency(\.feedService) private var feedService
    @ObservationIgnored @Dependency(\.favoriteService) private var favoriteService
    @ObservationIgnored @Dependency(\.shareService) private var shareService
    @ObservationIgnored @Dependency(\.cardCustomizationService) private var customizationService
    @ObservationIgnored @Dependency(\.backgroundGenerator) private var backgroundGenerator
    @ObservationIgnored @Dependency(\.widgetService) private var widgetService
    private let logger = Logger(subsystem: "com.gragera.lumen", category: "Feed")

    // MARK: - Actions

    func loadFeed(preferences: UserPreferences, isPremium: Bool, modelContext: ModelContext) async {
        guard cards.isEmpty else { return }

        // Only show loading spinner on first load (no existing cards)
        let isFirstLoad = cards.isEmpty
        if isFirstLoad { isLoading = true }
        defer { if isFirstLoad { isLoading = false } }

        // Load active theme IDs for rotation
        await loadActiveThemes(modelContext: modelContext)

        // Single-pass batch load (one fetch of all data instead of 20+ repeated queries)
        do {
            let result = try feedService.loadBatch(
                count: 20,
                preferences: preferences,
                isPremium: isPremium,
                modelContext: modelContext
            )

            dailyAffirmation = result.daily

            if result.feed.isEmpty {
                showRelaxFiltersPrompt = true
            } else {
                cards = result.feed
                currentIndex = 0
                showRelaxFiltersPrompt = false
                favoritedIds = Set(result.feed.filter { $0.isFavorited }.map { $0.id })

                // Assign random backgrounds from active themes
                await assignBackgrounds(for: result.feed)

                // Load card customizations
                applyCustomizations(to: result.feed, modelContext: modelContext)
            }
        } catch {
            logger.error("Feed load error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func loadMoreIfNeeded(preferences: UserPreferences, isPremium: Bool, modelContext: ModelContext) {
        guard currentIndex >= cards.count - 5 else { return }

        do {
            for _ in 0..<10 {
                if let next = try feedService.nextAffirmation(
                    preferences: preferences,
                    isPremium: isPremium,
                    modelContext: modelContext
                ) {
                    cards.append(next)
                }
            }
        } catch {
            logger.error("Load more error: \(error.localizedDescription)")
        }
    }

    func recordSeen(modelContext: ModelContext) {
        guard let card = currentCard else { return }
        do {
            try feedService.recordSeen(affirmation: card, source: .feed, modelContext: modelContext)
        } catch {
            logger.error("Record seen error: \(error.localizedDescription)")
        }
    }

    func isFavorited(_ affirmation: Affirmation) -> Bool {
        favoritedIds.contains(affirmation.id)
    }

    func toggleFavorite(modelContext: ModelContext) {
        guard let card = currentCard else { return }
        do {
            try favoriteService.toggleFavorite(affirmation: card, modelContext: modelContext)
            if favoritedIds.contains(card.id) {
                favoritedIds.remove(card.id)
            } else {
                favoritedIds.insert(card.id)
            }
            
            let allFavs = try favoriteService.fetchFavorites(modelContext: modelContext)
            let entries = allFavs.map { aff -> (text: String, gradientColors: [String], backgroundImage: UIImage?) in
                let index = abs(aff.id.hashValue) % LumenTheme.Colors.gradients.count
                let colors = LumenTheme.Colors.gradients[index].map { $0.hexString }
                return (text: aff.text, gradientColors: colors, backgroundImage: self.backgroundImage(for: aff))
            }
            widgetService.updateFavoritesWidget(favorites: entries)
        } catch {
            logger.error("Favorite error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
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

    // MARK: - Card Customizations

    /// Loads the customization for a single affirmation, if one exists.
    /// Bulk-loads all customizations and indexes them by affirmation id.
    func applyCustomizations(to cards: [Affirmation], modelContext: ModelContext) {
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

    /// Reloads customizations for the current card set and regenerates backgrounds for customized cards.
    func reloadCustomizations(modelContext: ModelContext) {
        let previousCustomizations = customizations
        applyCustomizations(to: cards, modelContext: modelContext)

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
        }
    }

    /// Regenerate a procedural background from a card's customization.
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

    // MARK: - Auto Advance

    /// Insert the most recently created user affirmation right after the current card and navigate to it.
    func insertLatestUserAffirmation(modelContext: ModelContext) {
        do {
            let userSource = AffirmationSource.user
            var descriptor = FetchDescriptor<Affirmation>(
                predicate: #Predicate<Affirmation> { $0.source == userSource },
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            descriptor.fetchLimit = 1

            guard let newest = try modelContext.fetch(descriptor).first else { return }

            // Don't insert if already in the feed
            guard !cards.contains(where: { $0.id == newest.id }) else { return }

            // Insert right after current position
            let insertIndex = min(currentIndex + 1, cards.count)
            cards.insert(newest, at: insertIndex)
            currentIndex = insertIndex
            
            // Reload customizations to ensure newly created typography/backgrounds apply
            reloadCustomizations(modelContext: modelContext)
        } catch {
            logger.error("Failed to insert user affirmation: \(error.localizedDescription)")
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

    // MARK: - Theme Rotation

    /// Load active theme IDs from SwiftData.
    private func loadActiveThemes(modelContext: ModelContext) async {
        do {
            let descriptor = FetchDescriptor<AppTheme>(
                predicate: #Predicate<AppTheme> { $0.isActive == true || $0.isActive == nil }
            )
            let themes = try modelContext.fetch(descriptor)
            activeThemeIds = themes.map(\.id)
            logger.info("Loaded \(themes.count) active themes for rotation")
        } catch {
            logger.error("Failed to load active themes: \(error.localizedDescription)")
            activeThemeIds = []
        }
    }

    /// Assign a random background image to each card from the active theme pool.
    private func assignBackgrounds(for affirmations: [Affirmation]) async {
        if ProcessInfo.processInfo.arguments.contains("-UITesting") {
            let mockThemeId = "ai_bg_autumn_leaves"
            if let mockImage = Self.loadThemeImage(themeId: mockThemeId) {
                var backgrounds: [String: UIImage] = [:]
                for aff in affirmations {
                    backgrounds[aff.id] = mockImage
                }
                cardBackgrounds = backgrounds
            }
            return
        }
        
        guard !activeThemeIds.isEmpty else {
            cardBackgrounds = [:]
            return
        }

        let themeIds = activeThemeIds
        let assignments: [(String, String)] = affirmations.map { aff in
            let themeId = themeIds[abs(aff.id.hashValue) % themeIds.count]
            return (aff.id, themeId)
        }

        // Load images off main thread
        let loaded: [(String, UIImage)] = await Task.detached {
            assignments.compactMap { (affId, themeId) in
                guard let image = Self.loadThemeImage(themeId: themeId) else { return nil }
                return (affId, image)
            }
        }.value

        var backgrounds: [String: UIImage] = [:]
        for (affId, image) in loaded {
            backgrounds[affId] = image
        }
        cardBackgrounds = backgrounds
    }

    /// Resolve a theme image from disk (generated or AI).
    private nonisolated static func loadThemeImage(themeId: String) -> UIImage? {
        let searchDirs: [URL] = [
            FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.gragera.lumen")?
                .appendingPathComponent("themes/generated"),
            FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.gragera.lumen")?
                .appendingPathComponent("themes/ai"),
            FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
                .appendingPathComponent("themes/generated"),
            FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
                .appendingPathComponent("themes/ai"),
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

    /// Get the background image for a specific affirmation card.
    func backgroundImage(for affirmation: Affirmation) -> UIImage? {
        cardBackgrounds[affirmation.id]
    }
}
