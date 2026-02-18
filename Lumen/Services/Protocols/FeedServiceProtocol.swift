import Foundation
import SwiftData

protocol FeedServiceProtocol: Sendable {
    func nextAffirmation(
        preferences: UserPreferences,
        isPremium: Bool,
        modelContext: ModelContext
    ) throws -> Affirmation?

    func dailyAffirmation(
        preferences: UserPreferences,
        isPremium: Bool,
        modelContext: ModelContext
    ) throws -> Affirmation?

    func recordSeen(
        affirmation: Affirmation,
        source: SeenSource,
        modelContext: ModelContext
    ) throws
}
