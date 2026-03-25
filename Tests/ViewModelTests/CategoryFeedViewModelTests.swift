import Foundation
import SwiftData
import SwiftUI
import Testing

@testable import Lumen

@Suite("CategoryFeedViewModel Tests")
@MainActor struct CategoryFeedViewModelTests {

    // MARK: - Mocks

    private final class MockFavoriteService: FavoriteServiceProtocol, @unchecked Sendable {
        var toggleCalled = false
        func toggleFavorite(affirmation: Affirmation, modelContext: ModelContext) throws {
            toggleCalled = true
        }
        func fetchFavorites(modelContext: ModelContext) throws -> [Affirmation] { [] }
    }

    private final class MockShareService: ShareServiceProtocol, @unchecked Sendable {
        @MainActor func renderShareImage(
            text: String,
            gradientColors: [Color],
            size: CGSize,
            showWatermark: Bool
        ) -> UIImage? {
            UIImage()
        }
    }

    // MARK: - Tests

    @Test("initial state")
    func initialState() {
        let vm = CategoryFeedViewModel()
        #expect(vm.cards.isEmpty)
        #expect(vm.currentIndex == 0)
        #expect(vm.currentCard == nil)
        #expect(!vm.isLoading)
    }

    @Test("currentCard out of bounds returns nil")
    func currentCard_outOfBounds_returnsNil() {
        let vm = CategoryFeedViewModel()
        vm.currentIndex = 5
        #expect(vm.currentCard == nil)
    }
}
