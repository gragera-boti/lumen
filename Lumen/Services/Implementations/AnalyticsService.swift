import Foundation
import OSLog

/// Local analytics service. Logs events to os_log and an optional local store.
/// Pluggable: replace with Firebase, Amplitude, etc. by conforming to protocol.
final class AnalyticsService: AnalyticsServiceProtocol, @unchecked Sendable {
    static let shared = AnalyticsService()

    private let logger = Logger(subsystem: "com.gragera.lumen", category: "Analytics")
    private var isOptedOut = false

    func log(event: AnalyticsEvent) {
        guard !isOptedOut else { return }

        let name = eventName(for: event)
        let properties = eventProperties(for: event)

        logger.info("📊 \(name): \(properties)")

        // TODO: Forward to external analytics provider if configured
    }

    func setOptOut(_ optOut: Bool) {
        isOptedOut = optOut
        logger.info("Analytics opt-out: \(optOut)")
    }

    // MARK: - Event mapping

    private func eventName(for event: AnalyticsEvent) -> String {
        switch event {
        case .onboardingStarted: "onboarding_started"
        case .onboardingCategoriesSelected: "onboarding_categories_selected"
        case .onboardingToneSelected: "onboarding_tone_selected"
        case .onboardingRemindersSetup: "onboarding_reminders_setup"
        case .onboardingCompleted: "onboarding_completed"
        case .affirmationViewed: "affirmation_viewed"
        case .favoriteToggled: "favorite_toggled"
        case .ttsPlayed: "tts_played"
        case .shareStarted: "share_started"
        case .categoryTapped: "category_tapped"
        case .gentleModeToggled: "gentle_mode_toggled"
        case .contentFilterChanged: "content_filter_changed"
        case .backgroundGenerationStarted: "bg_generation_started"
        case .backgroundGenerationCompleted: "bg_generation_completed"
        case .backgroundGenerationCancelled: "bg_generation_cancelled"
        case .paywallViewed: "paywall_viewed"
        case .purchaseStarted: "purchase_started"
        case .purchaseCompleted: "purchase_completed"
        case .purchaseRestored: "purchase_restored"
        case .appOpened: "app_opened"
        case .sessionStarted: "session_started"
        }
    }

    private func eventProperties(for event: AnalyticsEvent) -> String {
        switch event {
        case .onboardingCategoriesSelected(let count, let sensitive):
            "count=\(count), includeSensitive=\(sensitive)"
        case .onboardingToneSelected(let tone):
            "tone=\(tone)"
        case .onboardingRemindersSetup(let enabled, let count):
            "enabled=\(enabled), countPerDay=\(count)"
        case .affirmationViewed(let id, let source):
            "id=\(id), source=\(source)"
        case .favoriteToggled(let id, let fav):
            "id=\(id), favorited=\(fav)"
        case .ttsPlayed(let id):
            "id=\(id)"
        case .shareStarted(let id):
            "id=\(id)"
        case .categoryTapped(let id):
            "id=\(id)"
        case .gentleModeToggled(let enabled):
            "enabled=\(enabled)"
        case .contentFilterChanged(let filter, let enabled):
            "filter=\(filter), enabled=\(enabled)"
        case .backgroundGenerationStarted(let style):
            "style=\(style)"
        case .backgroundGenerationCompleted(let ms):
            "durationMs=\(ms)"
        case .paywallViewed(let trigger):
            "trigger=\(trigger)"
        case .purchaseStarted(let id):
            "productId=\(id)"
        case .purchaseCompleted(let id):
            "productId=\(id)"
        default:
            ""
        }
    }
}
