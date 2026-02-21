import Foundation
import SwiftData

/// Service for managing the user's persistent preferences.
protocol PreferencesServiceProtocol: Sendable {
    /// Fetch the existing user preferences, or create default ones if none exist.
    /// - Parameter modelContext: The SwiftData model context to query or insert into.
    /// - Returns: The user's ``UserPreferences`` object.
    func getOrCreate(modelContext: ModelContext) throws -> UserPreferences

    /// Persist any pending changes to user preferences.
    /// - Parameter modelContext: The SwiftData model context to save.
    func save(modelContext: ModelContext) throws
}
