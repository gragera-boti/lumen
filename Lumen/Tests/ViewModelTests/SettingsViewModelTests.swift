import XCTest
import SwiftData
@testable import Lumen

@MainActor
final class SettingsViewModelTests: XCTestCase {

    private final class MockPreferencesService: PreferencesServiceProtocol, @unchecked Sendable {
        var prefs: UserPreferences?

        func getOrCreate(modelContext: ModelContext) throws -> UserPreferences {
            if let p = prefs { return p }
            let p = UserPreferences()
            prefs = p
            return p
        }

        func save(modelContext: ModelContext) throws {}
    }

    private final class MockEntitlementService: EntitlementServiceProtocol, @unchecked Sendable {
        var premium = false

        func isPremium() async -> Bool { premium }
        func purchase(productId: String) async throws {}
        func restorePurchases() async throws {}
        func availableProducts() async throws -> [ProductInfo] { [] }
    }

    private final class MockCloudSyncService: CloudSyncServiceProtocol, @unchecked Sendable {
        func isSyncEnabled() -> Bool { false }
        func setSyncEnabled(_ enabled: Bool) {}
        func syncStatus() async -> CloudSyncStatus { .disabled }
    }

    func test_initialState() {
        let vm = SettingsViewModel()
        XCTAssertNil(vm.preferences)
        XCTAssertFalse(vm.isPremium)
        XCTAssertNil(vm.errorMessage)
    }
}
