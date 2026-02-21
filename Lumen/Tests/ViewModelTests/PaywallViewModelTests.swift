import Testing
@testable import Lumen

@Suite("PaywallViewModel Tests")
@MainActor struct PaywallViewModelTests {

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

    @Test("initial state")
    func initialState() {
        let vm = PaywallViewModel()
        #expect(vm.products.isEmpty)
        #expect(!vm.isLoading)
        #expect(!vm.isPurchasing)
        #expect(!vm.purchaseSuccess)
        #expect(vm.errorMessage == nil)
    }

    @Test("loadProducts populates list")
    func loadProducts_populatesList() async {
        let mock = MockEntitlementService()
        mock.products = [
            ProductInfo(id: "monthly", displayName: "Monthly", displayPrice: "$4.99", isSubscription: true, trialDuration: "7 days"),
        ]
        let vm = PaywallViewModel(entitlementService: mock)

        await vm.loadProducts()

        #expect(vm.products.count == 1)
        #expect(vm.products.first?.displayPrice == "$4.99")
        #expect(!vm.isLoading)
    }

    @Test("loadProducts sets error on failure")
    func loadProducts_setsErrorOnFailure() async {
        let mock = MockEntitlementService()
        mock.shouldThrow = true
        let vm = PaywallViewModel(entitlementService: mock)

        await vm.loadProducts()

        #expect(vm.products.isEmpty)
        #expect(vm.errorMessage != nil)
    }

    @Test("purchase sets purchase success")
    func purchase_setsPurchaseSuccess() async {
        let mock = MockEntitlementService()
        let product = ProductInfo(id: "monthly", displayName: "Monthly", displayPrice: "$4.99", isSubscription: true, trialDuration: nil)
        let vm = PaywallViewModel(entitlementService: mock)

        await vm.purchase(product)

        #expect(mock.purchaseCalled)
        #expect(vm.purchaseSuccess)
    }

    @Test("purchase sets error on failure")
    func purchase_setsErrorOnFailure() async {
        let mock = MockEntitlementService()
        mock.shouldThrow = true
        let product = ProductInfo(id: "monthly", displayName: "Monthly", displayPrice: "$4.99", isSubscription: true, trialDuration: nil)
        let vm = PaywallViewModel(entitlementService: mock)

        await vm.purchase(product)

        #expect(!vm.purchaseSuccess)
        #expect(vm.errorMessage != nil)
    }

    @Test("restore calls service")
    func restore_callsService() async {
        let mock = MockEntitlementService()
        mock.premium = true
        let vm = PaywallViewModel(entitlementService: mock)

        await vm.restore()

        #expect(mock.restoreCalled)
        #expect(vm.purchaseSuccess)
    }
}
