import Foundation
import SwiftData

/// Service for recording and querying the user's daily mood check-ins.
protocol MoodServiceProtocol: Sendable {
    /// Record the user's mood for today. Replaces any existing entry for the same day.
    /// - Parameters:
    ///   - mood: The mood to record.
    ///   - modelContext: The SwiftData model context to persist the entry.
    func recordMood(_ mood: Mood, modelContext: ModelContext) throws

    /// Fetch today's mood entry, if one has been recorded.
    /// - Parameter modelContext: The SwiftData model context to query.
    /// - Returns: The ``MoodEntry`` for today, or `nil` if none exists.
    func todaysMood(modelContext: ModelContext) throws -> MoodEntry?

    /// Fetch recent mood entries, ordered by most recent first.
    /// - Parameters:
    ///   - days: The maximum number of entries to return.
    ///   - modelContext: The SwiftData model context to query.
    /// - Returns: An array of recent ``MoodEntry`` objects.
    func recentMoods(days: Int, modelContext: ModelContext) throws -> [MoodEntry]
}
