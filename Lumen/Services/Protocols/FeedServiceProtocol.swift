import Foundation
import SwiftData

/// Service for selecting and delivering affirmations to the user's feed.
///
/// Uses weighted scoring based on user preferences, mood, tone affinity,
/// and favorite history to surface the most relevant content.
protocol FeedServiceProtocol: Sendable {
    /// Select the next affirmation for the user based on preferences and mood.
    /// - Parameters:
    ///   - preferences: The user's content preferences and filters.
    ///   - isPremium: Whether the user has premium access.
    ///   - mood: The user's current mood, if recorded today.
    ///   - modelContext: The SwiftData model context to query.
    /// - Returns: A single affirmation, or `nil` if no candidates match.
    func nextAffirmation(
        preferences: UserPreferences,
        isPremium: Bool,
        mood: Mood?,
        modelContext: ModelContext
    ) throws -> Affirmation?

    /// Return a deterministic "affirmation of the day" that stays consistent for the calendar day.
    /// - Parameters:
    ///   - preferences: The user's content preferences and filters.
    ///   - isPremium: Whether the user has premium access.
    ///   - mood: The user's current mood, if recorded today.
    ///   - modelContext: The SwiftData model context to query.
    /// - Returns: The daily affirmation, or `nil` if no candidates match.
    func dailyAffirmation(
        preferences: UserPreferences,
        isPremium: Bool,
        mood: Mood?,
        modelContext: ModelContext
    ) throws -> Affirmation?

    /// Load a batch of affirmations in a single pass, including the daily pick.
    /// - Parameters:
    ///   - count: The number of feed affirmations to return.
    ///   - preferences: The user's content preferences and filters.
    ///   - isPremium: Whether the user has premium access.
    ///   - mood: The user's current mood, if recorded today.
    ///   - modelContext: The SwiftData model context to query.
    /// - Returns: A tuple containing the daily affirmation and the feed batch.
    func loadBatch(
        count: Int,
        preferences: UserPreferences,
        isPremium: Bool,
        mood: Mood?,
        modelContext: ModelContext
    ) throws -> (daily: Affirmation?, feed: [Affirmation])

    /// Record that an affirmation was seen by the user.
    /// - Parameters:
    ///   - affirmation: The affirmation that was viewed.
    ///   - source: Where the affirmation was seen (feed, widget, notification, etc.).
    ///   - modelContext: The SwiftData model context to persist the event.
    func recordSeen(
        affirmation: Affirmation,
        source: SeenSource,
        modelContext: ModelContext
    ) throws
}
