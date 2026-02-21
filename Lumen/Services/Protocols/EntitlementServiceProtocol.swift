import Foundation

/// Service for managing premium entitlements and in-app purchases via RevenueCat.
protocol EntitlementServiceProtocol: Sendable {
    /// Configure the RevenueCat SDK. Call once at app launch.
    func configure()

    /// Check whether the current user has an active premium entitlement.
    /// - Returns: `true` if the user is a premium subscriber.
    func isPremium() async -> Bool

    /// Initiate a purchase for the given product identifier.
    /// - Parameter productId: The App Store product identifier to purchase.
    func purchase(productId: String) async throws

    /// Restore previously completed purchases from the App Store.
    func restorePurchases() async throws

    /// Fetch the list of available products from the current RevenueCat offering.
    /// - Returns: An array of ``ProductInfo`` describing each available product.
    func availableProducts() async throws -> [ProductInfo]
}

struct ProductInfo: Identifiable, Sendable {
    let id: String
    let displayName: String
    let displayPrice: String
    let isSubscription: Bool
    let trialDuration: String?
}
