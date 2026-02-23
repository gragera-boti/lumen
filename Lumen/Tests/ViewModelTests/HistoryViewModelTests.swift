import Foundation
import Testing

@testable import Lumen

@Suite("HistoryViewModel Tests")
@MainActor struct HistoryViewModelTests {

    @Test("initial state")
    func initialState() {
        let vm = HistoryViewModel()
        #expect(vm.entries.isEmpty)
        #expect(!vm.isLoading)
        #expect(vm.errorMessage == nil)
    }

    @Test("HistoryEntry is Identifiable")
    func historyEntry_isIdentifiable() {
        let entryType = HistoryViewModel.HistoryEntry.self
        #expect(entryType == entryType)
    }
}
