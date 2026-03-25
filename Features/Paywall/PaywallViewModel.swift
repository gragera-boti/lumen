import Dependencies
import Foundation
import OSLog

/// Retained for test compatibility. The live paywall uses RevenueCatUI.
@MainActor @Observable
final class PaywallViewModel {
    var products: [ProductInfo] = []
    var isLoading = false
    var isPurchasing = false
    var errorMessage: String?
    var purchaseSuccess = false

    @ObservationIgnored @Dependency(\.entitlementService) private var entitlementService
    private let logger = Logger(subsystem: "com.gragera.lumen", category: "Paywall")

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            products = try await entitlementService.availableProducts()
        } catch {
            logger.error("Failed to load products: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func purchase(_ product: ProductInfo) async {
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            try await entitlementService.purchase(productId: product.id)
            purchaseSuccess = true
        } catch {
            logger.error("Purchase failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func restore() async {
        do {
            try await entitlementService.restorePurchases()
            purchaseSuccess = await entitlementService.isPremium()
        } catch {
            logger.error("Restore failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
}
