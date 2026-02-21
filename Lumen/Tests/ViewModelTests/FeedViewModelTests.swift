import XCTest
import SwiftUI
import SwiftData
@testable import Lumen

@MainActor
final class FeedViewModelTests: XCTestCase {

    // MARK: - Mocks

    private final class MockFeedService: FeedServiceProtocol, @unchecked Sendable {
        var affirmations: [Affirmation] = []
        var dailyResult: Affirmation?
        var callCount = 0

        func nextAffirmation(preferences: UserPreferences, isPremium: Bool, mood: Mood?, modelContext: ModelContext) throws -> Affirmation? {
            defer { callCount += 1 }
            guard callCount < affirmations.count else { return nil }
            return affirmations[callCount]
        }

        func dailyAffirmation(preferences: UserPreferences, isPremium: Bool, mood: Mood?, modelContext: ModelContext) throws -> Affirmation? {
            dailyResult
        }

        func loadBatch(count: Int, preferences: UserPreferences, isPremium: Bool, mood: Mood?, modelContext: ModelContext) throws -> (daily: Affirmation?, feed: [Affirmation]) {
            (dailyResult, affirmations)
        }

        func recordSeen(affirmation: Affirmation, source: SeenSource, modelContext: ModelContext) throws {}
    }

    private final class MockFavoriteService: FavoriteServiceProtocol, @unchecked Sendable {
        var toggleCalled = false

        func toggleFavorite(affirmation: Affirmation, modelContext: ModelContext) throws {
            toggleCalled = true
        }

        func fetchFavorites(modelContext: ModelContext) throws -> [Affirmation] { [] }
    }

    private final class MockShareService: ShareServiceProtocol, @unchecked Sendable {
        @MainActor func renderShareImage(text: String, gradientColors: [SwiftUI.Color], size: CGSize, showWatermark: Bool) -> UIImage? {
            UIImage()
        }
    }

    // MARK: - Tests

    func test_initialState() {
        let vm = FeedViewModel()
        XCTAssertTrue(vm.cards.isEmpty)
        XCTAssertEqual(vm.currentIndex, 0)
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.errorMessage)
    }

    func test_swipeToNext_incrementsIndex() {
        let vm = FeedViewModel()
        // Simulate cards loaded
        let a1 = Affirmation(id: "a1", text: "First")
        let a2 = Affirmation(id: "a2", text: "Second")
        vm.cards = [a1, a2]
        vm.currentIndex = 0

        vm.swipeToNext()
        XCTAssertEqual(vm.currentIndex, 1)
    }

    func test_swipeToNext_doesNotExceedBounds() {
        let vm = FeedViewModel()
        let a1 = Affirmation(id: "a1", text: "Only one")
        vm.cards = [a1]
        vm.currentIndex = 0

        vm.swipeToNext()
        XCTAssertEqual(vm.currentIndex, 0)
    }

    func test_swipeToPrevious_decrementsIndex() {
        let vm = FeedViewModel()
        vm.cards = [
            Affirmation(id: "a1", text: "First"),
            Affirmation(id: "a2", text: "Second"),
        ]
        vm.currentIndex = 1

        vm.swipeToPrevious()
        XCTAssertEqual(vm.currentIndex, 0)
    }

    func test_swipeToPrevious_doesNotGoBelowZero() {
        let vm = FeedViewModel()
        vm.cards = [Affirmation(id: "a1", text: "First")]
        vm.currentIndex = 0

        vm.swipeToPrevious()
        XCTAssertEqual(vm.currentIndex, 0)
    }

    func test_currentCard_returnsCorrectCard() {
        let vm = FeedViewModel()
        let a1 = Affirmation(id: "a1", text: "First")
        let a2 = Affirmation(id: "a2", text: "Second")
        vm.cards = [a1, a2]
        vm.currentIndex = 1

        XCTAssertEqual(vm.currentCard?.id, "a2")
    }

    func test_currentCard_returnsNilWhenEmpty() {
        let vm = FeedViewModel()
        XCTAssertNil(vm.currentCard)
    }
}
