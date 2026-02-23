import Foundation
import Testing

@testable import Lumen

@Suite("ExploreViewModel Tests")
@MainActor struct ExploreViewModelTests {

    @Test("initial state")
    func initialState() {
        let vm = ExploreViewModel()
        #expect(vm.categories.isEmpty)
        #expect(!vm.isLoading)
        #expect(!vm.isPremium)
        #expect(vm.errorMessage == nil)
    }
}
