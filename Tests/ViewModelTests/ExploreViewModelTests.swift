import Dependencies
import Foundation
import SwiftData
import Testing

@testable import Lumen

@Suite("ExploreViewModel Tests")
@MainActor struct ExploreViewModelTests {

    // MARK: - Mocks

    private final class MockContentService: ContentServiceProtocol, @unchecked Sendable {
        var mockCategories: [Lumen.Category] = []
        var shouldThrow = false

        func loadBundledContentIfNeeded(modelContext: ModelContext) throws {}
        func fetchCategories(modelContext: ModelContext, locale: String) throws -> [Lumen.Category] {
            if shouldThrow { throw NSError(domain: "test", code: 1) }
            return mockCategories
        }
        func fetchAffirmation(byId id: String, modelContext: ModelContext) throws -> Affirmation? { nil }
    }

    private final class MockEntitlementService: EntitlementServiceProtocol, @unchecked Sendable {
        var isPremiumValue = false

        func configure() {}
        func isPremium() async -> Bool { isPremiumValue }
        func purchase(productId: String) async throws {}
        func restorePurchases() async throws {}
        func availableProducts() async throws -> [ProductInfo] { [] }
    }

    private func createInMemoryContext() throws -> ModelContext {
        let container = try TestContainerFactory.makeContainer()
        return ModelContext(container)
    }

    // MARK: - Tests

    @Test("initial state")
    func initialState() {
        let vm = ExploreViewModel()
        #expect(vm.categories.isEmpty)
        #expect(!vm.isLoading)
        #expect(!vm.isPremium)
        #expect(vm.errorMessage == nil)
    }

    @Test("loadData success loads non-sensitive categories")
    func loadData_success() async throws {
        let contentService = MockContentService()
        let cat1 = Lumen.Category(id: "c1", name: "Normal", icon: "star")
        let cat2 = Lumen.Category(id: "c2", name: "Sensitive", icon: "star")
        cat2.isSensitive = true
        contentService.mockCategories = [cat1, cat2]

        let entitlementService = MockEntitlementService()
        entitlementService.isPremiumValue = true

        let vm = withDependencies {
            $0.contentService = contentService
            $0.entitlementService = entitlementService
        } operation: {
            ExploreViewModel()
        }

        let context = try createInMemoryContext()
        // Prefs are false by default (includeSensitiveTopics == false)

        await vm.loadData(modelContext: context)

        #expect(!vm.isLoading)
        #expect(vm.isPremium == true)
        #expect(vm.categories.count == 1)
        #expect(vm.categories.first?.id == "c1")
        #expect(vm.errorMessage == nil)
    }

    @Test("loadData success loads sensitive categories if preferences allow")
    func loadData_success_withSensitive() async throws {
        let contentService = MockContentService()
        let cat1 = Lumen.Category(id: "c1", name: "Normal", icon: "star")
        let cat2 = Lumen.Category(id: "c2", name: "Sensitive", icon: "star")
        cat2.isSensitive = true
        contentService.mockCategories = [cat1, cat2]

        let vm = withDependencies {
            $0.contentService = contentService
            $0.entitlementService = MockEntitlementService()
        } operation: {
            ExploreViewModel()
        }

        let context = try createInMemoryContext()
        let prefs = UserPreferences()
        prefs.includeSensitiveTopics = true
        context.insert(prefs)

        await vm.loadData(modelContext: context)

        #expect(vm.categories.count == 2)
    }

    @Test("loadData error state")
    func loadData_error() async throws {
        let contentService = MockContentService()
        contentService.shouldThrow = true

        let vm = withDependencies {
            $0.contentService = contentService
            $0.entitlementService = MockEntitlementService()
        } operation: {
            ExploreViewModel()
        }

        let context = try createInMemoryContext()

        await vm.loadData(modelContext: context)

        #expect(vm.categories.isEmpty)
        #expect(vm.errorMessage != nil)
    }
}
