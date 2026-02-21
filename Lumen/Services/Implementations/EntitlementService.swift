import Foundation
import RevenueCat
import OSLog

final class EntitlementService: EntitlementServiceProtocol, @unchecked Sendable {
    static let shared = EntitlementService()

    private let logger = Logger(subsystem: "com.gragera.lumen", category: "EntitlementService")

    /// The RevenueCat entitlement identifier configured in the dashboard
    private let entitlementId = "Lumen Pro"

    // MARK: - Configuration

    /// Call once at app launch to configure RevenueCat
    func configure() {
        #if DEBUG
        Purchases.logLevel = .debug
        #endif
        #if DEBUG
        let apiKey = "test_VfvOKeRUGqMRSBEwwWCpVStTmkG"  // RC Test Store
        #else
        let apiKey = "appl_NXFeBNuRZMdVjWeWoxbwmiOfYCK"   // Production App Store
        #endif
        Purchases.configure(withAPIKey: apiKey)
        logger.info("RevenueCat configured")
    }

    // MARK: - Protocol

    func isPremium() async -> Bool {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            let active = customerInfo.entitlements[entitlementId]?.isActive == true
            logger.info("Premium check: \(active)")
            return active
        } catch {
            logger.error("Failed to check premium: \(error.localizedDescription)")
            return false
        }
    }

    func purchase(productId: String) async throws {
        // RevenueCat purchase flow is handled by RevenueCatUI paywall
        // This is a fallback for manual purchases
        let products = await Purchases.shared.products([productId])
        guard let product = products.first else {
            throw EntitlementError.productNotFound
        }

        let (_, customerInfo, _) = try await Purchases.shared.purchase(product: product)

        if customerInfo.entitlements[entitlementId]?.isActive == true {
            logger.info("Purchase successful: \(productId)")
        }
    }

    func restorePurchases() async throws {
        let customerInfo = try await Purchases.shared.restorePurchases()
        let active = customerInfo.entitlements[entitlementId]?.isActive == true
        logger.info("Restore complete, premium: \(active)")
    }

    func availableProducts() async throws -> [ProductInfo] {
        let offerings = try await Purchases.shared.offerings()
        guard let current = offerings.current else {
            return []
        }

        return current.availablePackages.map { package in
            ProductInfo(
                id: package.storeProduct.productIdentifier,
                displayName: package.storeProduct.localizedTitle,
                displayPrice: package.localizedPriceString,
                isSubscription: package.packageType != .lifetime,
                trialDuration: package.storeProduct.introductoryDiscount?.subscriptionPeriod.debugDescription
            )
        }
    }
}

enum EntitlementError: Error, LocalizedError {
    case productNotFound

    var errorDescription: String? {
        switch self {
        case .productNotFound: "Product not found."
        }
    }
}
