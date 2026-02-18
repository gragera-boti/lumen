import Foundation
import WidgetKit
import OSLog

final class WidgetService: @unchecked Sendable {
    static let shared = WidgetService()
    private let logger = Logger(subsystem: "com.lumen.app", category: "WidgetService")

    private let appGroupId = "group.com.lumen.app"

    func updateWidget(affirmationText: String, gradientColors: [String]) {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupId
        ) else {
            logger.warning("App group container not available")
            return
        }

        let snapshot = WidgetSnapshot(
            id: UUID().uuidString,
            text: affirmationText,
            gradientColors: gradientColors,
            updatedAt: .now
        )

        let fileURL = containerURL.appendingPathComponent("widget_snapshot.json")
        do {
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: fileURL, options: .atomic)
            WidgetCenter.shared.reloadAllTimelines()
            logger.info("Widget snapshot updated")
        } catch {
            logger.error("Failed to write widget snapshot: \(error.localizedDescription)")
        }
    }
}

private struct WidgetSnapshot: Codable {
    let id: String
    let text: String
    let gradientColors: [String]
    let updatedAt: Date
}
