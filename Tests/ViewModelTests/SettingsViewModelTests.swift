import Foundation
import Testing

@testable import Lumen

@Suite("SettingsViewModel Tests")
@MainActor struct SettingsViewModelTests {

    @Test("initial state")
    func initialState() {
        let vm = SettingsViewModel()
        #expect(vm.preferences == nil)
        #expect(!vm.isPremium)
        #expect(vm.errorMessage == nil)
    }
}
