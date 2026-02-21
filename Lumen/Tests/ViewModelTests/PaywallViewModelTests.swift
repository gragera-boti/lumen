import XCTest
@testable import Lumen

@MainActor
final class PaywallViewModelTests: XCTestCase {

    // MARK: - Mock

    private final class MockEntitlementService: EntitlementServiceProtocol, @unchecked Sendable {
        var premium = false
        var products: [ProductInfo] = []
        var shouldThrow = false
        var purchaseCalled = false
        var restoreCalled = false

        func isPremium() async -> Bool { premium }

        func purchase(productId: String) async throws {
            if shouldThrow { throw EntitlementError.productNotFound }
            purchaseCalled = true
            premium = true
        }

        func restorePurchases() async throws {
            restoreCalled = true
        }

        func availableProducts() async throws -> [ProductInfo] {
            if shouldThrow { throw EntitlementError.productNotFound }
            return products
        }
    }

    // MARK: - Tests

    func test_initialState() {
        let vm = PaywallViewModel()
        XCTAssertTrue(vm.products.isEmpty)
        XCTAssertFalse(vm.isLoading)
        XCTAssertFalse(vm.isPurchasing)
        XCTAssertFalse(vm.purchaseSuccess)
        XCTAssertNil(vm.errorMessage)
    }

    func test_loadProducts_populatesList() async {
        let mock = MockEntitlementService()
        mock.products = [
            ProductInfo(id: "monthly", displayName: "Monthly", displayPrice: "$4.99", isSubscription: true, trialDuration: "7 days"),
        ]
        let vm = PaywallViewModel(entitlementService: mock)

        await vm.loadProducts()

        XCTAssertEqual(vm.products.count, 1)
        XCTAssertEqual(vm.products.first?.displayPrice, "$4.99")
        XCTAssertFalse(vm.isLoading)
    }

    func test_loadProducts_setsErrorOnFailure() async {
        let mock = MockEntitlementService()
        mock.shouldThrow = true
        let vm = PaywallViewModel(entitlementService: mock)

        await vm.loadProducts()

        XCTAssertTrue(vm.products.isEmpty)
        XCTAssertNotNil(vm.errorMessage)
    }

    func test_purchase_setsPurchaseSuccess() async {
        let mock = MockEntitlementService()
        let product = ProductInfo(id: "monthly", displayName: "Monthly", displayPrice: "$4.99", isSubscription: true, trialDuration: nil)
        let vm = PaywallViewModel(entitlementService: mock)

        await vm.purchase(product)

        XCTAssertTrue(mock.purchaseCalled)
        XCTAssertTrue(vm.purchaseSuccess)
    }

    func test_purchase_setsErrorOnFailure() async {
        let mock = MockEntitlementService()
        mock.shouldThrow = true
        let product = ProductInfo(id: "monthly", displayName: "Monthly", displayPrice: "$4.99", isSubscription: true, trialDuration: nil)
        let vm = PaywallViewModel(entitlementService: mock)

        await vm.purchase(product)

        XCTAssertFalse(vm.purchaseSuccess)
        XCTAssertNotNil(vm.errorMessage)
    }

    func test_restore_callsService() async {
        let mock = MockEntitlementService()
        mock.premium = true
        let vm = PaywallViewModel(entitlementService: mock)

        await vm.restore()

        XCTAssertTrue(mock.restoreCalled)
        XCTAssertTrue(vm.purchaseSuccess)
    }
}
