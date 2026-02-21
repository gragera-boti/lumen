import Foundation
import SwiftData
import OSLog

struct MoodService: MoodServiceProtocol {
    static let shared = MoodService()
    private let logger = Logger(subsystem: "com.gragera.lumen", category: "MoodService")

    func recordMood(_ mood: Mood, modelContext: ModelContext) throws {
        let todayKey = Self.dayKey(for: .now)

        // Replace existing entry for today
        if let existing = try fetchEntry(dayKey: todayKey, modelContext: modelContext) {
            existing.mood = mood
            existing.date = .now
        } else {
            let entry = MoodEntry(mood: mood)
            modelContext.insert(entry)
        }

        try modelContext.save()
        logger.info("Mood recorded: \(mood.rawValue)")
    }

    func todaysMood(modelContext: ModelContext) throws -> MoodEntry? {
        let todayKey = Self.dayKey(for: .now)
        return try fetchEntry(dayKey: todayKey, modelContext: modelContext)
    }

    func recentMoods(days: Int, modelContext: ModelContext) throws -> [MoodEntry] {
        var descriptor = FetchDescriptor<MoodEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = days
        return try modelContext.fetch(descriptor)
    }

    // MARK: - Private

    private func fetchEntry(dayKey: String, modelContext: ModelContext) throws -> MoodEntry? {
        var descriptor = FetchDescriptor<MoodEntry>(
            predicate: #Predicate { $0.dayKey == dayKey }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private static func dayKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
