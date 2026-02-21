import XCTest
import SwiftData
@testable import Lumen

@MainActor
final class OnboardingViewModelTests: XCTestCase {

    // MARK: - Mocks

    @MainActor
    private final class MockContentService: ContentServiceProtocol {
        var categories: [Lumen.Category] = []

        func loadBundledContentIfNeeded(modelContext: ModelContext) throws {}

        func fetchCategories(modelContext: ModelContext, locale: String) throws -> [Lumen.Category] {
            categories
        }

        func fetchAffirmation(byId id: String, modelContext: ModelContext) throws -> Affirmation? {
            nil
        }
    }

    private final class MockPreferencesService: PreferencesServiceProtocol, @unchecked Sendable {
        var savedPreferences: UserPreferences?

        func getOrCreate(modelContext: ModelContext) throws -> UserPreferences {
            if let existing = savedPreferences { return existing }
            let prefs = UserPreferences()
            savedPreferences = prefs
            return prefs
        }

        func save(modelContext: ModelContext) throws {}
    }

    private final class MockNotificationService: NotificationServiceProtocol, @unchecked Sendable {
        var shouldGrant = true

        func requestPermission() async throws -> Bool { shouldGrant }
        func scheduleReminders(settings: ReminderSettings, affirmationTexts: [String]) async throws {}
        func cancelAllReminders() async {}
        func permissionStatus() async -> NotificationPermission { shouldGrant ? .granted : .denied }
    }

    // MARK: - Tests

    func test_initialState_isWelcomeStep() {
        let vm = OnboardingViewModel()
        XCTAssertEqual(vm.currentStep, .welcome)
        XCTAssertTrue(vm.selectedCategoryIds.isEmpty)
        XCTAssertEqual(vm.selectedTone, .gentle)
    }

    func test_advance_movesStepForward() {
        let vm = OnboardingViewModel()

        vm.advance()
        XCTAssertEqual(vm.currentStep, .categories)

        vm.advance()
        XCTAssertEqual(vm.currentStep, .tone)

        vm.advance()
        XCTAssertEqual(vm.currentStep, .reminders)

        vm.advance()
        XCTAssertEqual(vm.currentStep, .done)
    }

    func test_goBack_movesStepBackward() {
        let vm = OnboardingViewModel()
        vm.advance() // → categories
        vm.advance() // → tone

        vm.goBack()
        XCTAssertEqual(vm.currentStep, .categories)

        vm.goBack()
        XCTAssertEqual(vm.currentStep, .welcome)

        vm.goBack()
        XCTAssertEqual(vm.currentStep, .welcome) // stays at welcome
    }

    func test_toggleCategory_addsAndRemoves() {
        let vm = OnboardingViewModel()

        vm.toggleCategory("cat_calm")
        XCTAssertTrue(vm.selectedCategoryIds.contains("cat_calm"))

        vm.toggleCategory("cat_calm")
        XCTAssertFalse(vm.selectedCategoryIds.contains("cat_calm"))
    }

    func test_canContinueFromCategories_requiresSelection() {
        let vm = OnboardingViewModel()

        XCTAssertFalse(vm.canContinueFromCategories)

        vm.toggleCategory("cat_self_love")
        XCTAssertTrue(vm.canContinueFromCategories)
    }

    func test_requestNotificationPermission_granted() async {
        let mockNotification = MockNotificationService()
        mockNotification.shouldGrant = true
        let vm = OnboardingViewModel(notificationService: mockNotification)

        await vm.requestNotificationPermission()

        XCTAssertEqual(vm.notificationPermission, .granted)
        XCTAssertFalse(vm.isRequestingPermission)
    }

    func test_requestNotificationPermission_denied() async {
        let mockNotification = MockNotificationService()
        mockNotification.shouldGrant = false
        let vm = OnboardingViewModel(notificationService: mockNotification)

        await vm.requestNotificationPermission()

        XCTAssertEqual(vm.notificationPermission, .denied)
    }
}
