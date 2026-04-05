import Dependencies
import Foundation
import Testing

@testable import Lumen

@Suite("OnboardingViewModel Tests")
@MainActor struct OnboardingViewModelTests {

    // MARK: - Mocks

    private final class MockNotificationService: NotificationServiceProtocol, @unchecked Sendable {
        var shouldGrant = true

        func requestPermission() async throws -> Bool { shouldGrant }
        func scheduleReminders(settings: ReminderSettings, affirmations: [(id: String, text: String)]) async throws {}
        func scheduleTestReminder(id: String, text: String) async throws {}
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
        vm.advance()  // → categories
        vm.advance()  // → tone

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
        let vm = withDependencies {
            $0.notificationService = mockNotification
        } operation: {
            OnboardingViewModel()
        }

        await vm.requestNotificationPermission()

        #expect(vm.notificationPermission == .granted)
        #expect(!vm.isRequestingPermission)
    }

    @Test("requestNotificationPermission denied")
    func requestNotificationPermission_denied() async {
        let mockNotification = MockNotificationService()
        mockNotification.shouldGrant = false
        let vm = withDependencies {
            $0.notificationService = mockNotification
        } operation: {
            OnboardingViewModel()
        }

        await vm.requestNotificationPermission()

        #expect(vm.notificationPermission == .denied)
    }
}
