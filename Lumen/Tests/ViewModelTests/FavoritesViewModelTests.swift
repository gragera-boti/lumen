import XCTest
import SwiftData
@testable import Lumen

@MainActor
final class FavoritesViewModelTests: XCTestCase {

    // MARK: - Mock

    private final class MockFavoriteService: FavoriteServiceProtocol {
        var favorites: [Affirmation] = []
        var toggleCalledWith: String?
        var shouldThrow = false

        func toggleFavorite(affirmation: Affirmation, modelContext: ModelContext) throws {
            if shouldThrow { throw NSError(domain: "test", code: 1) }
            toggleCalledWith = affirmation.id
        }

        func fetchFavorites(modelContext: ModelContext) throws -> [Affirmation] {
            if shouldThrow { throw NSError(domain: "test", code: 1) }
            return favorites
        }
    }

    // MARK: - Tests

    func test_initialState() {
        let vm = FavoritesViewModel()
        XCTAssertTrue(vm.favorites.isEmpty)
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.errorMessage)
    }
}
