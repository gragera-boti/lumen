import Foundation
import WidgetKit
import OSLog

final class WidgetService: WidgetServiceProtocol, @unchecked Sendable {
    static let shared = WidgetService()
    private let logger = Logger(subsystem: "com.gragera.lumen", category: "WidgetService")

    private let appGroupId = "group.com.gragera.lumen"

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
    func updateFavoritesWidget(favorites: [(text: String, gradientColors: [String])]) {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupId
        ) else {
            logger.warning("App group container not available")
            return
        }

        let entries = favorites.prefix(50).map { fav in
            FavoriteWidgetEntry(text: fav.text, gradientColors: fav.gradientColors)
        }

        let snapshot = FavoritesWidgetSnapshot(
            favorites: Array(entries),
            updatedAt: .now
        )

        let fileURL = containerURL.appendingPathComponent("favorites_widget.json")
        do {
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: fileURL, options: .atomic)
            WidgetCenter.shared.reloadTimelines(ofKind: "FavoritesWidget")
            logger.info("Favorites widget updated with \(entries.count) entries")
        } catch {
            logger.error("Failed to write favorites widget: \(error.localizedDescription)")
        }
    }
}

private struct WidgetSnapshot: Codable {
    let id: String
    let text: String
    let gradientColors: [String]
    let updatedAt: Date
}

struct FavoriteWidgetEntry: Codable {
    let text: String
    let gradientColors: [String]
}

struct FavoritesWidgetSnapshot: Codable {
    let favorites: [FavoriteWidgetEntry]
    let updatedAt: Date
}
