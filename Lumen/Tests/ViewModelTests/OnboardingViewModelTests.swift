import Testing
import SwiftData
@testable import Lumen

@Suite("OnboardingViewModel Tests")
@MainActor struct OnboardingViewModelTests {

    // MARK: - Mocks

    private final class MockContentService: ContentServiceProtocol, @unchecked Sendable {
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

    @Test("initial state is welcome step")
    func initialState_isWelcomeStep() {
        let vm = OnboardingViewModel()
        #expect(vm.currentStep == .welcome)
        #expect(vm.selectedCategoryIds.isEmpty)
        #expect(vm.selectedTone == .gentle)
    }

    @Test("advance moves step forward")
    func advance_movesStepForward() {
        let vm = OnboardingViewModel()

        vm.advance()
        #expect(vm.currentStep == .categories)

        vm.advance()
        #expect(vm.currentStep == .tone)

        vm.advance()
        #expect(vm.currentStep == .reminders)

        vm.advance()
        #expect(vm.currentStep == .done)
    }

    @Test("goBack moves step backward")
    func goBack_movesStepBackward() {
        let vm = OnboardingViewModel()
        vm.advance() // → categories
        vm.advance() // → tone

        vm.goBack()
        #expect(vm.currentStep == .categories)

        vm.goBack()
        #expect(vm.currentStep == .welcome)

        vm.goBack()
        #expect(vm.currentStep == .welcome)
    }

    @Test("toggleCategory adds and removes")
    func toggleCategory_addsAndRemoves() {
        let vm = OnboardingViewModel()

        vm.toggleCategory("cat_calm")
        #expect(vm.selectedCategoryIds.contains("cat_calm"))

        vm.toggleCategory("cat_calm")
        #expect(!vm.selectedCategoryIds.contains("cat_calm"))
    }

    @Test("canContinueFromCategories requires selection")
    func canContinueFromCategories_requiresSelection() {
        let vm = OnboardingViewModel()

        #expect(!vm.canContinueFromCategories)

        vm.toggleCategory("cat_self_love")
        #expect(vm.canContinueFromCategories)
    }

    @Test("requestNotificationPermission granted")
    func requestNotificationPermission_granted() async {
        let mockNotification = MockNotificationService()
        mockNotification.shouldGrant = true
        let vm = OnboardingViewModel(notificationService: mockNotification)

        await vm.requestNotificationPermission()

        #expect(vm.notificationPermission == .granted)
        #expect(!vm.isRequestingPermission)
    }

    @Test("requestNotificationPermission denied")
    func requestNotificationPermission_denied() async {
        let mockNotification = MockNotificationService()
        mockNotification.shouldGrant = false
        let vm = OnboardingViewModel(notificationService: mockNotification)

        await vm.requestNotificationPermission()

        #expect(vm.notificationPermission == .denied)
    }
}
