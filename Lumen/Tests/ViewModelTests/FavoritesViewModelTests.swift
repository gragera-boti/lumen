import Testing
import SwiftData
@testable import Lumen

@Suite("FavoritesViewModel Tests")
@MainActor struct FavoritesViewModelTests {

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

    @Test("initial state")
    func initialState() {
        let vm = FavoritesViewModel(widgetService: MockWidgetService())
        #expect(vm.favorites.isEmpty)
        #expect(!vm.isLoading)
        #expect(vm.errorMessage == nil)
    }
}
