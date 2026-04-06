import Dependencies
import Foundation
import SwiftData
import Testing

@testable import Lumen

@Suite("SettingsViewModel Tests")
@MainActor struct SettingsViewModelTests {

    // MARK: - Mocks

    private final class MockPreferencesService: PreferencesServiceProtocol, @unchecked Sendable {
        var mockedPrefs = UserPreferences()
        var saveCallCount = 0

        func getOrCreate(modelContext: ModelContext) throws -> UserPreferences {
            mockedPrefs
        }
        func save(modelContext: ModelContext) throws {
            saveCallCount += 1
        }
    }

    private final class MockEntitlementService: EntitlementServiceProtocol, @unchecked Sendable {
        var isPremiumValue = false

        func configure() {}
        func isPremium() async -> Bool { isPremiumValue }
        func purchase(productId: String) async throws {}
        func restorePurchases() async throws {}
        func availableProducts() async throws -> [ProductInfo] { [] }
    }

    private final class MockCloudSyncService: CloudSyncServiceProtocol, @unchecked Sendable {
        var syncEnabled = false
        var syncStatusValue = CloudSyncStatus.disabled

        func isSyncEnabled() -> Bool { syncEnabled }
        func setSyncEnabled(_ enabled: Bool) { syncEnabled = enabled }
        func syncStatus() async -> CloudSyncStatus { syncStatusValue }
        func markSynced() {}
    }

    private func createInMemoryContext() throws -> ModelContext {
        let container = try TestContainerFactory.makeContainer()
        return ModelContext(container)
    }

    // MARK: - Tests

    @Test("initial state")
    func initialState() {
        let vm = SettingsViewModel()
        #expect(vm.preferences == nil)
        #expect(!vm.isPremium)
        #expect(vm.errorMessage == nil)
    }

    @Test("load populates properties correctly")
    func load_success() async throws {
        let prefsService = MockPreferencesService()
        let entService = MockEntitlementService()
        entService.isPremiumValue = true
        let syncService = MockCloudSyncService()
        syncService.syncEnabled = true
        syncService.syncStatusValue = .synced(lastSync: .distantPast)

        let vm = withDependencies {
            $0.preferencesService = prefsService
            $0.entitlementService = entService
            $0.cloudSyncService = syncService
        } operation: {
            SettingsViewModel()
        }

        let context = try createInMemoryContext()
        await vm.load(modelContext: context)

        #expect(vm.preferences != nil)
        #expect(vm.isPremium == true)
        #expect(vm.isCloudSyncEnabled == true)
        #expect(vm.cloudSyncStatusText.contains("Synced"))
    }

    @Test("save sets updatedAt and invokes service")
    func save() throws {
        let prefsService = MockPreferencesService()
        let vm = withDependencies {
            $0.preferencesService = prefsService
        } operation: {
            SettingsViewModel()
        }

        vm.preferences = UserPreferences()
        let oldDate = Date.distantPast
        vm.preferences?.updatedAt = oldDate

        let context = try createInMemoryContext()
        vm.save(modelContext: context)

        #expect(prefsService.saveCallCount == 1)
        #expect(vm.preferences?.updatedAt != oldDate)
    }

    @Test("resetOnboarding clears properties")
    func resetOnboarding() throws {
        let prefsService = MockPreferencesService()
        let vm = withDependencies {
            $0.preferencesService = prefsService
        } operation: {
            SettingsViewModel()
        }

        let prefs = UserPreferences()
        prefs.hasCompletedOnboarding = true
        prefs.selectedCategoryIds = ["cat1"]
        vm.preferences = prefs

        let context = try createInMemoryContext()
        vm.resetOnboarding(modelContext: context)

        #expect(prefs.hasCompletedOnboarding == false)
        #expect(prefs.selectedCategoryIds.isEmpty)
        #expect(prefsService.saveCallCount == 1)
    }

    @Test("deleteAllData removes specified models and re-creates preferences")
    func deleteAllData() throws {
        let vm = SettingsViewModel()
        let context = try createInMemoryContext()

        // Insert some initial data
        context.insert(UserPreferences())
        let affirmation = Affirmation(id: "A", text: "Test Affirmation")
        context.insert(affirmation)
        context.insert(Favorite(affirmation: affirmation))
        try context.save()

        // Verify inserted
        #expect(try context.fetchCount(FetchDescriptor<UserPreferences>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<Favorite>()) == 1)

        vm.deleteAllData(modelContext: context)

        // After deletion, old favorites should be gone, but 1 new UserPreferences is recreated
        #expect(try context.fetchCount(FetchDescriptor<Favorite>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<UserPreferences>()) == 1)
        #expect(vm.preferences != nil)
    }

    @Test("toggleCloudSync enables or disables appropriately")
    func toggleCloudSync() {
        let syncService = MockCloudSyncService()
        let vm = withDependencies {
            $0.cloudSyncService = syncService
        } operation: {
            SettingsViewModel()
        }

        vm.toggleCloudSync(true)
        #expect(vm.isCloudSyncEnabled == true)
        #expect(syncService.syncEnabled == true)
        #expect(vm.cloudSyncStatusText.contains("syncing now"))

        vm.toggleCloudSync(false)
        #expect(vm.isCloudSyncEnabled == false)
        #expect(syncService.syncEnabled == false)
        #expect(vm.cloudSyncStatusText == CloudSyncStatus.disabled.displayText)
    }
}
