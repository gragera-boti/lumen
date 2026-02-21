import Foundation
import SwiftData

protocol MoodServiceProtocol: Sendable {
    func recordMood(_ mood: Mood, modelContext: ModelContext) throws
    func todaysMood(modelContext: ModelContext) throws -> MoodEntry?
    func recentMoods(days: Int, modelContext: ModelContext) throws -> [MoodEntry]
}
