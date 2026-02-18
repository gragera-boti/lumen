import XCTest
import SwiftData
@testable import Lumen

@MainActor
final class ExploreViewModelTests: XCTestCase {

    private final class MockContentService: ContentServiceProtocol {
        var categories: [Category] = []
        var shouldThrow = false

        func loadBundledContentIfNeeded(modelContext: ModelContext) async throws {}

        func fetchCategories(modelContext: ModelContext, locale: String) throws -> [Category] {
            if shouldThrow { throw ContentServiceError.bundleNotFound("test") }
            return categories
        }

        func fetchAffirmation(byId id: String, modelContext: ModelContext) throws -> Affirmation? { nil }
    }

    func test_initialState() {
        let vm = ExploreViewModel()
        XCTAssertTrue(vm.categories.isEmpty)
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.errorMessage)
    }
}
