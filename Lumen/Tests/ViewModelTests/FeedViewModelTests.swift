import Testing
import SwiftUI
import SwiftData
@testable import Lumen

@Suite("FeedViewModel Tests")
@MainActor struct FeedViewModelTests {

    // MARK: - Mocks

    private final class MockFeedService: FeedServiceProtocol, @unchecked Sendable {
        var affirmations: [Affirmation] = []
        var dailyResult: Affirmation?
        var callCount = 0

        func nextAffirmation(preferences: UserPreferences, isPremium: Bool, modelContext: ModelContext) throws -> Affirmation? {
            defer { callCount += 1 }
            guard callCount < affirmations.count else { return nil }
            return affirmations[callCount]
        }

        func dailyAffirmation(preferences: UserPreferences, isPremium: Bool, modelContext: ModelContext) throws -> Affirmation? {
            dailyResult
        }

        func loadBatch(count: Int, preferences: UserPreferences, isPremium: Bool, modelContext: ModelContext) throws -> (daily: Affirmation?, feed: [Affirmation]) {
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

    @Test("initial state")
    func initialState() {
        let vm = FeedViewModel()
        #expect(vm.cards.isEmpty)
        #expect(vm.currentIndex == 0)
        #expect(!vm.isLoading)
        #expect(vm.errorMessage == nil)
    }

    @Test("swipeToNext increments index")
    func swipeToNext_incrementsIndex() {
        let vm = FeedViewModel()
        let a1 = Affirmation(id: "a1", text: "First")
        let a2 = Affirmation(id: "a2", text: "Second")
        vm.cards = [a1, a2]
        vm.currentIndex = 0

        vm.swipeToNext()
        #expect(vm.currentIndex == 1)
    }

    @Test("swipeToNext does not exceed bounds")
    func swipeToNext_doesNotExceedBounds() {
        let vm = FeedViewModel()
        let a1 = Affirmation(id: "a1", text: "Only one")
        vm.cards = [a1]
        vm.currentIndex = 0

        vm.swipeToNext()
        #expect(vm.currentIndex == 0)
    }

    @Test("swipeToPrevious decrements index")
    func swipeToPrevious_decrementsIndex() {
        let vm = FeedViewModel()
        vm.cards = [
            Affirmation(id: "a1", text: "First"),
            Affirmation(id: "a2", text: "Second"),
        ]
        vm.currentIndex = 1

        vm.swipeToPrevious()
        #expect(vm.currentIndex == 0)
    }

    @Test("swipeToPrevious does not go below zero")
    func swipeToPrevious_doesNotGoBelowZero() {
        let vm = FeedViewModel()
        vm.cards = [Affirmation(id: "a1", text: "First")]
        vm.currentIndex = 0

        vm.swipeToPrevious()
        #expect(vm.currentIndex == 0)
    }

    @Test("currentCard returns correct card")
    func currentCard_returnsCorrectCard() {
        let vm = FeedViewModel()
        let a1 = Affirmation(id: "a1", text: "First")
        let a2 = Affirmation(id: "a2", text: "Second")
        vm.cards = [a1, a2]
        vm.currentIndex = 1

        #expect(vm.currentCard?.id == "a2")
    }

    @Test("currentCard returns nil when empty")
    func currentCard_returnsNilWhenEmpty() {
        let vm = FeedViewModel()
        #expect(vm.currentCard == nil)
    }
}
