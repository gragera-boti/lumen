import Dependencies
import Foundation
import OSLog
import SwiftData

@MainActor @Observable
final class OnboardingViewModel {
    // MARK: - State

    var currentStep: OnboardingStep = .welcome
    var categories: [Category] = []
    var selectedCategoryIds: Set<String> = []
    var includeSensitiveTopics = false
    var selectedTone: Tone = .gentle
    var remindersPerDay = 3
    var windowStart = "09:00"
    var windowEnd = "21:00"
    var notificationPermission: NotificationPermission = .unknown
    var isRequestingPermission = false
    var errorMessage: String?

    var canContinueFromCategories: Bool {
        !selectedCategoryIds.isEmpty
    }

    // MARK: - Dependencies

    @ObservationIgnored @Dependency(\.contentService) private var contentService
    @ObservationIgnored @Dependency(\.preferencesService) private var preferencesService
    @ObservationIgnored @Dependency(\.notificationService) private var notificationService
    private let logger = Logger(subsystem: "com.gragera.lumen", category: "Onboarding")

    // MARK: - Actions

    func loadCategories(modelContext: ModelContext) {
        do {
            categories = try contentService.fetchCategories(modelContext: modelContext, locale: "en-GB")
        } catch {
            logger.error("Failed to load categories: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func toggleCategory(_ id: String) {
        if selectedCategoryIds.contains(id) {
            selectedCategoryIds.remove(id)
        } else {
            selectedCategoryIds.insert(id)
        }
    }

    func advance() {
        switch currentStep {
        case .welcome:
            currentStep = .categories
        case .categories:
            currentStep = .tone
        case .tone:
            currentStep = .reminders
        case .reminders:
            currentStep = .done
        case .done:
            break
        }
    }

    func goBack() {
        switch currentStep {
        case .welcome: break
        case .categories: currentStep = .welcome
        case .tone: currentStep = .categories
        case .reminders: currentStep = .tone
        case .done: currentStep = .reminders
        }
    }

    func requestNotificationPermission() async {
        isRequestingPermission = true
        defer { isRequestingPermission = false }

        do {
            let granted = try await notificationService.requestPermission()
            notificationPermission = granted ? .granted : .denied
        } catch {
            logger.error("Notification permission error: \(error.localizedDescription)")
            notificationPermission = .denied
        }
    }

    func completeOnboarding(modelContext: ModelContext) {
        do {
            let prefs = try preferencesService.getOrCreate(modelContext: modelContext)
            prefs.selectedCategoryIds = Array(selectedCategoryIds)
            prefs.includeSensitiveTopics = includeSensitiveTopics
            prefs.tonePreset = selectedTone
            prefs.reminders = ReminderSettings(
                enabled: notificationPermission == .granted && remindersPerDay > 0,
                countPerDay: remindersPerDay,
                windowStart: windowStart,
                windowEnd: windowEnd,
                quietStart: "22:00",
                quietEnd: "07:00"
            )
            prefs.hasCompletedOnboarding = true
            prefs.updatedAt = .now
            try preferencesService.save(modelContext: modelContext)
            logger.info("Onboarding completed")
        } catch {
            logger.error("Failed to save onboarding: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
}

enum OnboardingStep: Int, CaseIterable {
    case welcome
    case categories
    case tone
    case reminders
    case done
}
