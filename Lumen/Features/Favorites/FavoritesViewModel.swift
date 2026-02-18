import Foundation
import SwiftData
import OSLog

@MainActor @Observable
final class FavoritesViewModel {
    var favorites: [Affirmation] = []
    var isLoading = false
    var errorMessage: String?

    private let favoriteService: FavoriteServiceProtocol
    private let logger = Logger(subsystem: "com.lumen.app", category: "Favorites")

    init(favoriteService: FavoriteServiceProtocol = FavoriteService.shared) {
        self.favoriteService = favoriteService
    }

    func loadFavorites(modelContext: ModelContext) {
        isLoading = true
        defer { isLoading = false }

        do {
            favorites = try favoriteService.fetchFavorites(modelContext: modelContext)
        } catch {
            logger.error("Failed to load favorites: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func removeFavorite(_ affirmation: Affirmation, modelContext: ModelContext) {
        do {
            try favoriteService.toggleFavorite(affirmation: affirmation, modelContext: modelContext)
            favorites.removeAll { $0.id == affirmation.id }
        } catch {
            logger.error("Failed to remove favorite: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
}
