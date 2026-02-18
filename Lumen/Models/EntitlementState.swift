import Foundation
import SwiftData

@Model
final class EntitlementState {
    @Attribute(.unique) var id: Int = 1
    var isPremium: Bool
    var productId: String?
    var expiresAt: Date?
    var updatedAt: Date

    init(
        isPremium: Bool = false,
        productId: String? = nil,
        expiresAt: Date? = nil
    ) {
        self.isPremium = isPremium
        self.productId = productId
        self.expiresAt = expiresAt
        self.updatedAt = .now
    }
}
