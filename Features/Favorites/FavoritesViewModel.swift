import Dependencies
import Foundation
import OSLog
import SwiftData
import UIKit

@MainActor @Observable
final class FavoritesViewModel {
    var userCreated: [Affirmation] = []
    var curatedFavorites: [Affirmation] = []
    var isLoading = false
    var errorMessage: String?

    /// Card customizations keyed by affirmation id.
    var customizations: [String: CardCustomization] = [:]

    /// Background images keyed by affirmation id for random rotation.
    var cardBackgrounds: [String: UIImage] = [:]
    /// Active theme IDs for rotation.
    private var activeThemeIds: [String] = []

    /// All favorites combined (for slideshow).
    var allFavorites: [Affirmation] {
        userCreated + curatedFavorites
    }

    // Keep backwards compat for any code referencing .favorites
    var favorites: [Affirmation] { allFavorites }

    @ObservationIgnored @Dependency(\.favoriteService) private var favoriteService
    @ObservationIgnored @Dependency(\.widgetService) private var widgetService
    @ObservationIgnored @Dependency(\.cardCustomizationService) private var customizationService
    private let logger = Logger(subsystem: "com.gragera.lumen", category: "Favorites")

    func loadFavorites(modelContext: ModelContext) async {
        await loadActiveThemes(modelContext: modelContext)

        isLoading = true
        defer { isLoading = false }

        do {
            let all = try favoriteService.fetchFavorites(modelContext: modelContext)

            // Split into user-created and curated
            userCreated = all.filter { $0.source == .user }
            curatedFavorites = all.filter { $0.source != .user }

            syncFavoritesWidget()
            loadCustomizations(for: all, modelContext: modelContext)
            await assignBackgrounds(for: all)
        } catch {
            logger.error("Failed to load favorites: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    private func syncFavoritesWidget() {
        let entries = allFavorites.map { aff -> (text: String, gradientColors: [String], backgroundImage: UIImage?) in
            let index = abs(aff.id.hashValue) % LumenTheme.Colors.gradients.count
            let colors = LumenTheme.Colors.gradients[index].map { $0.hexString }
            return (text: aff.text, gradientColors: colors, backgroundImage: self.backgroundImage(for: aff))
        }
        widgetService.updateFavoritesWidget(favorites: entries)
    }

    func toggleFavorite(_ affirmation: Affirmation, modelContext: ModelContext) async {
        do {
            try favoriteService.toggleFavorite(affirmation: affirmation, modelContext: modelContext)
            await loadFavorites(modelContext: modelContext)
        } catch {
            logger.error("Failed to toggle favorite: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func removeFavorite(_ affirmation: Affirmation, modelContext: ModelContext) {
        do {
            try favoriteService.toggleFavorite(affirmation: affirmation, modelContext: modelContext)
            curatedFavorites.removeAll { $0.id == affirmation.id }
            userCreated.removeAll { $0.id == affirmation.id }
        } catch {
            logger.error("Failed to remove favorite: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func deleteUserAffirmation(_ affirmation: Affirmation, modelContext: ModelContext) {
        do {
            modelContext.delete(affirmation)
            try modelContext.save()
            userCreated.removeAll { $0.id == affirmation.id }
            logger.info("Deleted user affirmation: \(affirmation.id)")
        } catch {
            logger.error("Failed to delete affirmation: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Card Customizations

    func loadCustomizations(for affirmations: [Affirmation], modelContext: ModelContext) {
        do {
            let all = try customizationService.allCustomizations(modelContext: modelContext)
            let ids = Set(affirmations.map(\.id))
            var map: [String: CardCustomization] = [:]
            for c in all where ids.contains(c.affirmationId) {
                map[c.affirmationId] = c
            }
            customizations = map
        } catch {
            logger.error("Failed to load customizations: \(error.localizedDescription)")
        }
    }

    func reloadCustomizations(modelContext: ModelContext) {
        loadCustomizations(for: allFavorites, modelContext: modelContext)
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
