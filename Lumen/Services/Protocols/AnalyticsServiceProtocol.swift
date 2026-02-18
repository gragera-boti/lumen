import Foundation

/// Analytics event logging with privacy-first defaults.
/// Never logs custom affirmation text or sensitive personal data.
protocol AnalyticsServiceProtocol: Sendable {
    func log(event: AnalyticsEvent)
    func setOptOut(_ optOut: Bool)
}

enum AnalyticsEvent: Sendable {
    // Onboarding
    case onboardingStarted
    case onboardingCategoriesSelected(count: Int, includeSensitive: Bool)
    case onboardingToneSelected(tone: String)
    case onboardingRemindersSetup(enabled: Bool, countPerDay: Int)
    case onboardingCompleted

    // Feed
    case affirmationViewed(affirmationId: String, source: String)
    case favoriteToggled(affirmationId: String, isFavorited: Bool)
    case ttsPlayed(affirmationId: String)
    case shareStarted(affirmationId: String)

    // Content
    case categoryTapped(categoryId: String)
    case gentleModeToggled(enabled: Bool)
    case contentFilterChanged(filter: String, enabled: Bool)

    // Generation
    case backgroundGenerationStarted(style: String)
    case backgroundGenerationCompleted(durationMs: Int)
    case backgroundGenerationCancelled

    // Monetization
    case paywallViewed(trigger: String)
    case purchaseStarted(productId: String)
    case purchaseCompleted(productId: String)
    case purchaseRestored

    // App lifecycle
    case appOpened
    case sessionStarted
}
