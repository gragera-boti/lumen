import Foundation
import OSLog
import WidgetKit
import UIKit

struct WidgetService: WidgetServiceProtocol {
    static let shared = WidgetService()
    private let logger = Logger(subsystem: "com.gragera.lumen", category: "WidgetService")

    private let appGroupId = "group.com.gragera.lumen"
    
    private func prepareForWidget(image: UIImage) -> UIImage {
        let maxDimension: CGFloat = 600.0
        let width = image.size.width
        let height = image.size.height
        
        let scale = min(1.0, min(maxDimension / width, maxDimension / height))
        let targetSize = CGSize(width: width * scale, height: height * scale)
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0 // Ensure 1:1 pixel mapping to save memory and normalize P3 to sRGB
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { ctx in
            // Fill background with black in case of transparency
            UIColor.black.setFill()
            ctx.fill(CGRect(origin: .zero, size: targetSize))
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    func updateWidget(entries: [(text: String, gradientColors: [String], backgroundImage: UIImage?)]) {
        guard
            let containerURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: appGroupId
            )
        else {
            logger.warning("App group container not available")
            return
        }

        var snapshots: [WidgetSnapshot] = []
        var newImageFilenames: Set<String> = []

        for (index, entry) in entries.enumerated() {
            var imageFilename: String? = nil
            if let image = entry.backgroundImage,
               let imageData = prepareForWidget(image: image).jpegData(compressionQuality: 0.8) {
                let filename = "widget_bg_\(index)_\(UUID().uuidString).jpg"
                let fileURL = containerURL.appendingPathComponent(filename)
                do {
                    try imageData.write(to: fileURL, options: .atomic)
                    imageFilename = filename
                    newImageFilenames.insert(filename)
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
            // Commit JSON first — widget always sees a consistent snapshot.
            try data.write(to: fileURL, options: .atomic)
            WidgetCenter.shared.reloadAllTimelines()
            logger.info("Widget snapshot updated with \(snapshots.count) entries")
        } catch {
            logger.error("Failed to write widget snapshot: \(error.localizedDescription)")
            // Roll back newly written images since the JSON commit failed.
            for filename in newImageFilenames {
                try? FileManager.default.removeItem(at: containerURL.appendingPathComponent(filename))
            }
            return
        }

        // Delete old images only after JSON is committed so the widget never
        // references a file that no longer exists.
        cleanupOldImages(in: containerURL, keeping: newImageFilenames)
    }

    private func cleanupOldImages(in containerURL: URL, keeping newFilenames: Set<String>) {
        let fileManager = FileManager.default
        do {
            let files = try fileManager.contentsOfDirectory(at: containerURL, includingPropertiesForKeys: nil)
            for file in files
                where file.lastPathComponent.hasPrefix("widget_bg_")
                && file.pathExtension == "jpg"
                && !newFilenames.contains(file.lastPathComponent)
            {
                try? fileManager.removeItem(at: file)
            }
        } catch {
            logger.error("Failed to clean up old widget images: \(error.localizedDescription)")
        }
    }

    private func cleanupOldFavoriteImages(in containerURL: URL, keeping newFilenames: Set<String>) {
        let fileManager = FileManager.default
        do {
            let files = try fileManager.contentsOfDirectory(at: containerURL, includingPropertiesForKeys: nil)
            for file in files
                where file.lastPathComponent.hasPrefix("fav_bg_")
                && file.pathExtension == "jpg"
                && !newFilenames.contains(file.lastPathComponent)
            {
                try? fileManager.removeItem(at: file)
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

        var entries: [FavoriteWidgetEntry] = []
        var newImageFilenames: Set<String> = []

        for (index, fav) in favorites.prefix(50).enumerated() {
            var imageFilename: String? = nil
            if let image = fav.backgroundImage,
               let imageData = prepareForWidget(image: image).jpegData(compressionQuality: 0.8) {
                let filename = "fav_bg_\(index)_\(UUID().uuidString).jpg"
                let fileURL = containerURL.appendingPathComponent(filename)
                do {
                    try imageData.write(to: fileURL, options: .atomic)
                    imageFilename = filename
                    newImageFilenames.insert(filename)
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
            // Commit JSON first — widget always sees a consistent snapshot.
            try data.write(to: fileURL, options: .atomic)
            WidgetCenter.shared.reloadTimelines(ofKind: "FavoritesWidget")
            logger.info("Favorites widget updated with \(entries.count) entries")
        } catch {
            logger.error("Failed to write favorites widget: \(error.localizedDescription)")
            for filename in newImageFilenames {
                try? FileManager.default.removeItem(at: containerURL.appendingPathComponent(filename))
            }
            return
        }

        // Delete old images only after JSON is committed.
        cleanupOldFavoriteImages(in: containerURL, keeping: newImageFilenames)
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
