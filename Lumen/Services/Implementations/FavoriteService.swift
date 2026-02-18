import Foundation
import SwiftData

final class FavoriteService: FavoriteServiceProtocol, @unchecked Sendable {
    static let shared = FavoriteService()

    func toggleFavorite(affirmation: Affirmation, modelContext: ModelContext) throws {
        if let existing = affirmation.favorite {
            modelContext.delete(existing)
            affirmation.favorite = nil
        } else {
            let favorite = Favorite(affirmation: affirmation)
            modelContext.insert(favorite)
        }
        try modelContext.save()
    }

    func fetchFavorites(modelContext: ModelContext) throws -> [Affirmation] {
        let descriptor = FetchDescriptor<Favorite>(
            sortBy: [SortDescriptor(\.favoritedAt, order: .reverse)]
        )
        let favorites = try modelContext.fetch(descriptor)
        return favorites.compactMap { $0.affirmation }
    }
}
