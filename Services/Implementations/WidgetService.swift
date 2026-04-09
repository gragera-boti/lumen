import Foundation
import OSLog
import WidgetKit
import UIKit

struct WidgetService: WidgetServiceProtocol {
    static let shared = WidgetService()
    private let logger = Logger(subsystem: "com.gragera.lumen", category: "WidgetService")

    private let appGroupId = "group.com.gragera.lumen"

    func updateWidget(entries: [(text: String, gradientColors: [String], backgroundImage: UIImage?)]) {
        guard
            let containerURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: appGroupId
            )
        else {
            logger.warning("App group container not available")
            return
        }

        cleanupOldImages(in: containerURL)

        var snapshots: [WidgetSnapshot] = []

        for (index, entry) in entries.enumerated() {
            var imageFilename: String? = nil
            if let image = entry.backgroundImage,
               let imageData = image.jpegData(compressionQuality: 0.8) {
                let filename = "widget_bg_\(index)_\(UUID().uuidString).jpg"
                let fileURL = containerURL.appendingPathComponent(filename)
                do {
                    try imageData.write(to: fileURL, options: .atomic)
                    imageFilename = filename
                } catch {
                    logger.error("Failed to save background image: \(error.localizedDescription)")
                }
            }

            let snapshot = WidgetSnapshot(
                id: UUID().uuidString,
                text: entry.text,
                gradientColors: entry.gradientColors,
                backgroundImageFilename: imageFilename,
                updatedAt: .now
            )
            snapshots.append(snapshot)
        }

        let fileURL = containerURL.appendingPathComponent("widget_snapshot.json")
        do {
            let list = WidgetSnapshotList(entries: snapshots, updatedAt: .now)
            let data = try JSONEncoder().encode(list)
            try data.write(to: fileURL, options: .atomic)
            WidgetCenter.shared.reloadAllTimelines()
            logger.info("Widget snapshot updated with \(snapshots.count) entries")
        } catch {
            logger.error("Failed to write widget snapshot: \(error.localizedDescription)")
        }
    }

    private func cleanupOldImages(in containerURL: URL) {
        let fileManager = FileManager.default
        do {
            let files = try fileManager.contentsOfDirectory(at: containerURL, includingPropertiesForKeys: nil)
            for file in files where file.lastPathComponent.hasPrefix("widget_bg_") && file.pathExtension == "jpg" {
                try fileManager.removeItem(at: file)
            }
        } catch {
            logger.error("Failed to clean up old widget images: \(error.localizedDescription)")
        }
    }
    private func cleanupOldFavoriteImages(in containerURL: URL) {
        let fileManager = FileManager.default
        do {
            let files = try fileManager.contentsOfDirectory(at: containerURL, includingPropertiesForKeys: nil)
            for file in files where file.lastPathComponent.hasPrefix("fav_bg_") && file.pathExtension == "jpg" {
                try fileManager.removeItem(at: file)
            }
        } catch {
            logger.error("Failed to clean up old favorite images: \(error.localizedDescription)")
        }
    }

    func updateFavoritesWidget(favorites: [(text: String, gradientColors: [String], backgroundImage: UIImage?)]) {
        guard
            let containerURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: appGroupId
            )
        else {
            logger.warning("App group container not available")
            return
        }

        cleanupOldFavoriteImages(in: containerURL)

        var entries: [FavoriteWidgetEntry] = []
        for (index, fav) in favorites.prefix(50).enumerated() {
            var imageFilename: String? = nil
            if let image = fav.backgroundImage,
               let imageData = image.jpegData(compressionQuality: 0.8) {
                let filename = "fav_bg_\(index)_\(UUID().uuidString).jpg"
                let fileURL = containerURL.appendingPathComponent(filename)
                do {
                    try imageData.write(to: fileURL, options: .atomic)
                    imageFilename = filename
                } catch {
                    logger.error("Failed to save favorite background image: \(error.localizedDescription)")
                }
            }
            entries.append(FavoriteWidgetEntry(text: fav.text, gradientColors: fav.gradientColors, backgroundImageFilename: imageFilename))
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
    let backgroundImageFilename: String?
    let updatedAt: Date
}

private struct WidgetSnapshotList: Codable {
    let entries: [WidgetSnapshot]
    let updatedAt: Date
}

struct FavoriteWidgetEntry: Codable {
    let text: String
    let gradientColors: [String]
    let backgroundImageFilename: String?
}

struct FavoritesWidgetSnapshot: Codable {
    let favorites: [FavoriteWidgetEntry]
    let updatedAt: Date
}
