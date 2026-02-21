import Foundation
import SwiftData
import OSLog

@MainActor @Observable
final class HistoryViewModel {
    var entries: [HistoryEntry] = []
    var isLoading = false
    var errorMessage: String?

    private let logger = Logger(subsystem: "com.gragera.lumen", category: "History")

    struct HistoryEntry: Identifiable {
        let id: String
        let affirmationId: String
        let text: String
        let seenAt: Date
        let source: SeenSource
        let categoryNames: String

        init(seenEvent: SeenEvent) {
            self.affirmationId = seenEvent.affirmation?.id ?? ""
            self.id = "\(affirmationId)_\(seenEvent.seenAt.timeIntervalSince1970)"
            self.text = seenEvent.affirmation?.text ?? "Unknown"
            self.seenAt = seenEvent.seenAt
            self.source = seenEvent.source
            self.categoryNames = seenEvent.affirmation?.categories.map(\.name).joined(separator: ", ") ?? ""
        }
    }

    func loadHistory(modelContext: ModelContext) {
        isLoading = true
        defer { isLoading = false }

        do {
            var descriptor = FetchDescriptor<SeenEvent>(
                sortBy: [SortDescriptor(\.seenAt, order: .reverse)]
            )
            descriptor.fetchLimit = 200
            let events = try modelContext.fetch(descriptor)
            entries = events.map { HistoryEntry(seenEvent: $0) }
        } catch {
            logger.error("History load error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
}
