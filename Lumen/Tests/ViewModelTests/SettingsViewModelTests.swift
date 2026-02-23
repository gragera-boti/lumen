import Foundation
import SwiftData
import Testing

@testable import Lumen

@Suite("SettingsViewModel Tests")
@MainActor struct SettingsViewModelTests {

    private final class MockPreferencesService: PreferencesServiceProtocol, @unchecked Sendable {
        var prefs: UserPreferences?

        func getOrCreate(modelContext: ModelContext) throws -> UserPreferences {
            if let existing = prefs { return existing }
            let newPrefs = UserPreferences()
            prefs = newPrefs
            return newPrefs
        }

        func save(modelContext: ModelContext) throws {}
    }

    private final class MockEntitlementService: EntitlementServiceProtocol, @unchecked Sendable {
        var premium = false

        func configure() {}
        func isPremium() async -> Bool { premium }
        func purchase(productId: String) async throws {}
        func restorePurchases() async throws {}
        func availableProducts() async throws -> [ProductInfo] { [] }
    }

    private final class MockCloudSyncService: CloudSyncServiceProtocol, @unchecked Sendable {
        func isSyncEnabled() -> Bool { false }
        func setSyncEnabled(_ enabled: Bool) {}
        func syncStatus() async -> CloudSyncStatus { .disabled }
        func markSynced() {}
    }

    @Test("initial state")
    func initialState() {
        let vm = SettingsViewModel()
        #expect(vm.preferences == nil)
        #expect(!vm.isPremium)
        #expect(vm.errorMessage == nil)
    }
}
