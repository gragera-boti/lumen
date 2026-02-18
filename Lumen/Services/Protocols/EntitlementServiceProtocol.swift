import Foundation

protocol EntitlementServiceProtocol: Sendable {
    func isPremium() async -> Bool
    func purchase(productId: String) async throws
    func restorePurchases() async throws
    func availableProducts() async throws -> [ProductInfo]
}

struct ProductInfo: Identifiable, Sendable {
    let id: String
    let displayName: String
    let displayPrice: String
    let isSubscription: Bool
    let trialDuration: String?
}
