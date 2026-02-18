import XCTest
import SwiftData
@testable import Lumen

@MainActor
final class SettingsViewModelTests: XCTestCase {

    private final class MockPreferencesService: PreferencesServiceProtocol {
        var prefs: UserPreferences?

        func getOrCreate(modelContext: ModelContext) throws -> UserPreferences {
            if let p = prefs { return p }
            let p = UserPreferences()
            prefs = p
            return p
        }

        func save(modelContext: ModelContext) throws {}
    }

    private final class MockEntitlementService: EntitlementServiceProtocol {
        var premium = false

        func isPremium() async -> Bool { premium }
        func purchase(productId: String) async throws {}
        func restorePurchases() async throws {}
        func availableProducts() async throws -> [ProductInfo] { [] }
    }

    func test_initialState() {
        let vm = SettingsViewModel()
        XCTAssertNil(vm.preferences)
        XCTAssertFalse(vm.isPremium)
        XCTAssertNil(vm.errorMessage)
    }
}
