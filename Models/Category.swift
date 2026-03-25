import Foundation
import SwiftData

@Model
final class Category {
    @Attribute(.unique) var id: String = ""
    var locale: String = "en-GB"
    var name: String = ""
    var categoryDescription: String = ""
    var icon: String = "sparkles"
    var isPremium: Bool = false
    var isSensitive: Bool = false
    var sortOrder: Int = 0
    var updatedAt: Date = Date.now

    @Relationship(inverse: \Affirmation.categories)
    var affirmations: [Affirmation]?

    init(
        id: String,
        locale: String = "en-GB",
        name: String,
        categoryDescription: String = "",
        icon: String = "sparkles",
        isPremium: Bool = false,
        isSensitive: Bool = false,
        sortOrder: Int = 0,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.locale = locale
        self.name = name
        self.categoryDescription = categoryDescription
        self.icon = icon
        self.isPremium = isPremium
        self.isSensitive = isSensitive
        self.sortOrder = sortOrder
        self.updatedAt = updatedAt
        self.affirmations = []
    }
}
