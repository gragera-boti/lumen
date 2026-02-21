import XCTest
import SwiftData
@testable import Lumen

@MainActor
final class FavoritesViewModelTests: XCTestCase {

    // MARK: - Mock

    private final class MockFavoriteService: FavoriteServiceProtocol, @unchecked Sendable {
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

    private final class MockWidgetService: WidgetServiceProtocol, @unchecked Sendable {
        func updateWidget(affirmationText: String, gradientColors: [String]) {}
        func updateFavoritesWidget(favorites: [(text: String, gradientColors: [String])]) {}
    }

    // MARK: - Tests

    func test_initialState() {
        let vm = FavoritesViewModel(widgetService: MockWidgetService())
        XCTAssertTrue(vm.favorites.isEmpty)
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.errorMessage)
    }
}
