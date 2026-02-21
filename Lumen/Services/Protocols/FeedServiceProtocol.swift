import Foundation
import SwiftData

protocol FeedServiceProtocol: Sendable {
    func nextAffirmation(
        preferences: UserPreferences,
        isPremium: Bool,
        mood: Mood?,
        modelContext: ModelContext
    ) throws -> Affirmation?

    func dailyAffirmation(
        preferences: UserPreferences,
        isPremium: Bool,
        mood: Mood?,
        modelContext: ModelContext
    ) throws -> Affirmation?

    func loadBatch(
        count: Int,
        preferences: UserPreferences,
        isPremium: Bool,
        mood: Mood?,
        modelContext: ModelContext
    ) throws -> (daily: Affirmation?, feed: [Affirmation])

    func recordSeen(
        affirmation: Affirmation,
        source: SeenSource,
        modelContext: ModelContext
    ) throws
}
