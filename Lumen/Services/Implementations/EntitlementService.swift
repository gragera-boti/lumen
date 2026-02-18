import Foundation
import StoreKit
import SwiftData
import OSLog

final class EntitlementService: EntitlementServiceProtocol, @unchecked Sendable {
    static let shared = EntitlementService()
    private let logger = Logger(subsystem: "com.lumen.app", category: "EntitlementService")

    private let productIds = [
        "lumen.premium.monthly",
        "lumen.premium.yearly",
        "lumen.premium.lifetime",
    ]

    func isPremium() async -> Bool {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if productIds.contains(transaction.productID) {
                    return true
                }
            }
        }
        return false
    }

    func purchase(productId: String) async throws {
        let products = try await Product.products(for: [productId])
        guard let product = products.first else {
            throw EntitlementError.productNotFound
        }

        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            if case .verified(let transaction) = verification {
                await transaction.finish()
                logger.info("Purchase successful: \(productId)")
            }
        case .userCancelled:
            logger.info("User cancelled purchase")
        case .pending:
            logger.info("Purchase pending")
        @unknown default:
            break
        }
    }

    func restorePurchases() async throws {
        try await AppStore.sync()
        logger.info("Purchases restored")
    }

    func availableProducts() async throws -> [ProductInfo] {
        let products = try await Product.products(for: Set(productIds))
        return products.map { product in
            ProductInfo(
                id: product.id,
                displayName: product.displayName,
                displayPrice: product.displayPrice,
                isSubscription: product.type == .autoRenewable,
                trialDuration: product.subscription?.introductoryOffer?.period.debugDescription
            )
        }
    }
}

enum EntitlementError: Error, LocalizedError {
    case productNotFound

    var errorDescription: String? {
        switch self {
        case .productNotFound: "Product not found in the App Store."
        }
    }
}
