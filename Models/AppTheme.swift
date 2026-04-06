import Foundation
import SwiftData
import SwiftUI

@Model
final class AppTheme {
    @Attribute(.unique) var id: String = ""
    var name: String = ""
    var type: ThemeType = ThemeType.curatedImage
    var isPremium: Bool = false
    var dataJSON: String = ""
    /// Whether this theme is in the active rotation shown in the feed.
    /// Uses optional to allow lightweight migration from older schema.
    var isActive: Bool?
    @Attribute(.externalStorage) var imageData: Data?
    @Attribute(.externalStorage) var thumbnailData: Data?
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    /// Whether this theme participates in feed rotation. Defaults to true for migrated rows.
    var isInRotation: Bool {
        get { isActive ?? true }
        set { isActive = newValue }
    }

    init(
        id: String,
        name: String,
        type: ThemeType,
        isPremium: Bool = false,
        dataJSON: String = "{}",
        isActive: Bool? = true,
        imageData: Data? = nil,
        thumbnailData: Data? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.isPremium = isPremium
        self.dataJSON = dataJSON
        self.isActive = isActive
        self.imageData = imageData
        self.thumbnailData = thumbnailData
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Gradient theme data

struct GradientData: Codable {
    let colors: [String]
    let angleDeg: Double
    let noise: Double

    var swiftUIColors: [Color] {
        colors.map { Color(hex: $0) }
    }
}
