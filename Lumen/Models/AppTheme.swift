import Foundation
import SwiftData
import SwiftUI

@Model
final class AppTheme {
    @Attribute(.unique) var id: String
    var name: String
    var type: ThemeType
    var isPremium: Bool
    var dataJSON: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String,
        name: String,
        type: ThemeType,
        isPremium: Bool = false,
        dataJSON: String = "{}",
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.isPremium = isPremium
        self.dataJSON = dataJSON
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
