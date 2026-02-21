import Foundation
import SwiftData

@Model
final class MoodEntry {
    @Attribute(.unique) var id: String
    var mood: Mood
    var date: Date

    /// Calendar day as "yyyy-MM-dd" for quick lookups
    var dayKey: String

    init(mood: Mood, date: Date = .now) {
        self.id = UUID().uuidString
        self.mood = mood
        self.date = date

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        self.dayKey = formatter.string(from: date)
    }
}
