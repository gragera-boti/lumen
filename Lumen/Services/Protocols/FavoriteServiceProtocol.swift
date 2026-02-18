import Foundation
import SwiftData

protocol FavoriteServiceProtocol: Sendable {
    func toggleFavorite(affirmation: Affirmation, modelContext: ModelContext) throws
    func fetchFavorites(modelContext: ModelContext) throws -> [Affirmation]
}
