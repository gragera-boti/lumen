import Foundation
import SwiftData
import SwiftUI
import Testing

@testable import Lumen

@Suite("FeedViewModel Tests")
@MainActor struct FeedViewModelTests {

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
