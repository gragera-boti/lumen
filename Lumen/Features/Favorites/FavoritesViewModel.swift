import Foundation
import SwiftData
import OSLog

@MainActor @Observable
final class FavoritesViewModel {
    var userCreated: [Affirmation] = []
    var curatedFavorites: [Affirmation] = []
    var isLoading = false
    var errorMessage: String?

    /// All favorites combined (for slideshow).
    var allFavorites: [Affirmation] {
        userCreated + curatedFavorites
    }

    // Keep backwards compat for any code referencing .favorites
    var favorites: [Affirmation] { allFavorites }

    private let favoriteService: FavoriteServiceProtocol
    private let widgetService: WidgetServiceProtocol
    private let logger = Logger(subsystem: "com.gragera.lumen", category: "Favorites")

    init(
        favoriteService: FavoriteServiceProtocol = FavoriteService.shared,
        widgetService: WidgetServiceProtocol = WidgetService.shared
    ) {
        self.favoriteService = favoriteService
        self.widgetService = widgetService
    }

    func loadFavorites(modelContext: ModelContext) {
        isLoading = true
        defer { isLoading = false }

        do {
            let all = try favoriteService.fetchFavorites(modelContext: modelContext)

            // Split into user-created and curated
            userCreated = all.filter { $0.source == .user }
            curatedFavorites = all.filter { $0.source != .user }

            syncFavoritesWidget()
        } catch {
            logger.error("Failed to load favorites: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    private func syncFavoritesWidget() {
        let entries = allFavorites.map { aff in
            let index = abs(aff.id.hashValue) % LumenTheme.Colors.gradients.count
            let colors = LumenTheme.Colors.gradients[index].map { $0.hexString }
            return (text: aff.text, gradientColors: colors)
        }
        widgetService.updateFavoritesWidget(favorites: entries)
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
}
