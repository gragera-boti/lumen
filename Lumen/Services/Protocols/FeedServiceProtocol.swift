import Foundation
import SwiftData

/// Service for selecting and delivering affirmations to the user's feed.
///
/// Uses weighted scoring based on user preferences, tone affinity,
/// and favorite history to surface the most relevant content.
protocol FeedServiceProtocol: Sendable {
    /// Select the next affirmation for the user based on preferences.
    func nextAffirmation(
        preferences: UserPreferences,
        isPremium: Bool,
        modelContext: ModelContext
    ) throws -> Affirmation?

    /// Return a deterministic "affirmation of the day" that stays consistent for the calendar day.
    func dailyAffirmation(
        preferences: UserPreferences,
        isPremium: Bool,
        modelContext: ModelContext
    ) throws -> Affirmation?

    /// Load a batch of affirmations in a single pass, including the daily pick.
    func loadBatch(
        count: Int,
        preferences: UserPreferences,
        isPremium: Bool,
        modelContext: ModelContext
    ) throws -> (daily: Affirmation?, feed: [Affirmation])

    /// Record that an affirmation was seen by the user.
    func recordSeen(
        affirmation: Affirmation,
        source: SeenSource,
        modelContext: ModelContext
    ) throws
}
