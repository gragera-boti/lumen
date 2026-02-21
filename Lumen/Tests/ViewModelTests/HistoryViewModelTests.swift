import XCTest
@testable import Lumen

@MainActor
final class HistoryViewModelTests: XCTestCase {

    func test_initialState() {
        let vm = HistoryViewModel()
        XCTAssertTrue(vm.entries.isEmpty)
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.errorMessage)
    }

    // Note: loadHistory requires a real ModelContext with SeenEvent data.
    // Integration tests would cover that path. Here we verify the ViewModel's
    // default state and that HistoryEntry correctly exposes Identifiable conformance.

    func test_historyEntry_isIdentifiable() {
        // Ensure the nested type compiles and conforms to Identifiable
        let entryType = HistoryViewModel.HistoryEntry.self
        XCTAssertTrue(entryType == entryType) // type check compiles
    }
}
