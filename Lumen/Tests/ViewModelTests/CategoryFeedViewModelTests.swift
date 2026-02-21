import XCTest
import SwiftUI
import SwiftData
@testable import Lumen

@MainActor
final class CategoryFeedViewModelTests: XCTestCase {

    // MARK: - Mocks

    private final class MockFavoriteService: FavoriteServiceProtocol, @unchecked Sendable {
        var toggleCalled = false
        func toggleFavorite(affirmation: Affirmation, modelContext: ModelContext) throws {
            toggleCalled = true
        }
        func fetchFavorites(modelContext: ModelContext) throws -> [Affirmation] { [] }
    }

    private final class MockShareService: ShareServiceProtocol, @unchecked Sendable {
        @MainActor func renderShareImage(text: String, gradientColors: [Color], size: CGSize, showWatermark: Bool) -> UIImage? {
            UIImage()
        }
    }

    // MARK: - Tests

    func test_initialState() {
        let vm = CategoryFeedViewModel()
        XCTAssertTrue(vm.cards.isEmpty)
        XCTAssertEqual(vm.currentIndex, 0)
        XCTAssertNil(vm.currentCard)
        XCTAssertFalse(vm.isLoading)
    }

    func test_currentCard_outOfBounds_returnsNil() {
        let vm = CategoryFeedViewModel()
        vm.currentIndex = 5
        XCTAssertNil(vm.currentCard)
    }
}
