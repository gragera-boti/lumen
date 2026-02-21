import XCTest
import SwiftData
@testable import Lumen

@MainActor
final class ExploreViewModelTests: XCTestCase {

    @MainActor
    private final class MockContentService: ContentServiceProtocol {
        var categories: [Lumen.Category] = []
        var shouldThrow = false

        func loadBundledContentIfNeeded(modelContext: ModelContext) throws {}

        func fetchCategories(modelContext: ModelContext, locale: String) throws -> [Lumen.Category] {
            if shouldThrow { throw ContentServiceError.bundleNotFound("test") }
            return categories
        }

        func fetchAffirmation(byId id: String, modelContext: ModelContext) throws -> Affirmation? { nil }
    }

    @MainActor
    private final class MockEntitlementService: EntitlementServiceProtocol {
        var premium = false
        func isPremium() async -> Bool { premium }
        func purchase(productId: String) async throws {}
        func restorePurchases() async throws {}
        func availableProducts() async throws -> [ProductInfo] { [] }
    }

    func test_initialState() {
        let vm = ExploreViewModel()
        XCTAssertTrue(vm.categories.isEmpty)
        XCTAssertFalse(vm.isLoading)
        XCTAssertFalse(vm.isPremium)
        XCTAssertNil(vm.errorMessage)
    }
}
