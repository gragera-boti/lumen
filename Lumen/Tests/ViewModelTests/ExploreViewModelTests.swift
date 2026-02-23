import Foundation
import SwiftData
import Testing

@testable import Lumen

@Suite("ExploreViewModel Tests")
@MainActor struct ExploreViewModelTests {

    private final class MockContentService: ContentServiceProtocol, @unchecked Sendable {
        var categories: [Lumen.Category] = []
        var shouldThrow = false

        func loadBundledContentIfNeeded(modelContext: ModelContext) throws {}

        func fetchCategories(modelContext: ModelContext, locale: String) throws -> [Lumen.Category] {
            if shouldThrow { throw ContentServiceError.bundleNotFound("test") }
            return categories
        }

        func fetchAffirmation(byId id: String, modelContext: ModelContext) throws -> Affirmation? { nil }
    }

    private final class MockEntitlementService: EntitlementServiceProtocol, @unchecked Sendable {
        var premium = false
        func configure() {}
        func isPremium() async -> Bool { premium }
        func purchase(productId: String) async throws {}
        func restorePurchases() async throws {}
        func availableProducts() async throws -> [ProductInfo] { [] }
    }

    @Test("initial state")
    func initialState() {
        let vm = ExploreViewModel()
        #expect(vm.categories.isEmpty)
        #expect(!vm.isLoading)
        #expect(!vm.isPremium)
        #expect(vm.errorMessage == nil)
    }
}
