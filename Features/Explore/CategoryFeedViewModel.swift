import Dependencies
import Foundation
import OSLog
import SwiftData
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

    func loadCustomizations(modelContext: ModelContext) {
        do {
            let all = try customizationService.allCustomizations(modelContext: modelContext)
            customizations = Dictionary(uniqueKeysWithValues: all.map { ($0.affirmationId, $0) })
        } catch {
            logger.error("Load customizations error: \(error.localizedDescription)")
        }
    }

    func reloadCustomizations(modelContext: ModelContext) {
        loadCustomizations(modelContext: modelContext)
    }

    func shareImage(isPremium: Bool) -> UIImage? {
        guard let card = currentCard else { return nil }
        let gradientIndex = abs(card.id.hashValue) % LumenTheme.Colors.gradients.count
        let colors = LumenTheme.Colors.gradients[gradientIndex]
        return shareService.renderShareImage(
            text: card.text,
            gradientColors: colors,
            size: CGSize(width: 1080, height: 1920),
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
            activeThemeIds = themes.map(\.id)
            logger.info("Loaded \(themes.count) active themes for rotation")
        } catch {
            logger.error("Failed to load active themes: \(error.localizedDescription)")
            activeThemeIds = []
        }
    }

    /// Assign a random background image to each card from the active theme pool.
    private func assignBackgrounds(for affirmations: [Affirmation]) async {
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
}
