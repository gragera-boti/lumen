import Foundation
import SwiftData

@Model
final class EntitlementState {
    var id: Int = 1
    var isPremium: Bool = false
    var productId: String?
    var expiresAt: Date?
    var updatedAt: Date = Date.now

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
