import Foundation
import SwiftData

/// Service for managing the user's favorited affirmations.
protocol FavoriteServiceProtocol: Sendable {
    /// Toggle the favorite state of an affirmation.
    /// If already favorited, removes the favorite; otherwise creates one.
    /// - Parameters:
    ///   - affirmation: The affirmation to favorite or unfavorite.
    ///   - modelContext: The SwiftData model context to persist the change.
    func toggleFavorite(affirmation: Affirmation, modelContext: ModelContext) throws

    /// Fetch all favorited affirmations, ordered by most recently favorited first.
    /// - Parameter modelContext: The SwiftData model context to query.
    /// - Returns: An array of favorited ``Affirmation`` objects.
    func fetchFavorites(modelContext: ModelContext) throws -> [Affirmation]
}
