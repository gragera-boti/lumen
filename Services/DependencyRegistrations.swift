import Dependencies
import UIKit
import Foundation

// MARK: - Service Dependency Keys

// Each service protocol gets a DependencyKey + DependencyValues extension.
// ViewModels access services via @Dependency(\.serviceName).

// MARK: ContentService

private enum ContentServiceKey: DependencyKey {
    static let liveValue: any ContentServiceProtocol = {
        MainActor.assumeIsolated { ContentService.shared }
    }()
}

extension DependencyValues {
    var contentService: any ContentServiceProtocol {
        get { self[ContentServiceKey.self] }
        set { self[ContentServiceKey.self] = newValue }
    }
}

// MARK: FeedService

private enum FeedServiceKey: DependencyKey {
    static let liveValue: any FeedServiceProtocol = FeedService.shared
}

extension DependencyValues {
    var feedService: any FeedServiceProtocol {
        get { self[FeedServiceKey.self] }
        set { self[FeedServiceKey.self] = newValue }
    }
}

// MARK: FavoriteService

private enum FavoriteServiceKey: DependencyKey {
    static let liveValue: any FavoriteServiceProtocol = FavoriteService.shared
}

extension DependencyValues {
    var favoriteService: any FavoriteServiceProtocol {
        get { self[FavoriteServiceKey.self] }
        set { self[FavoriteServiceKey.self] = newValue }
    }
}

// MARK: DislikeService

// periphery:ignore - registered for completeness, not yet consumed by any ViewModel
private enum DislikeServiceKey: DependencyKey {
    static let liveValue: any DislikeServiceProtocol = DislikeService.shared
}

extension DependencyValues {
    var dislikeService: any DislikeServiceProtocol {
        get { self[DislikeServiceKey.self] }
        set { self[DislikeServiceKey.self] = newValue }
    }
}

// MARK: ShareService

private enum ShareServiceKey: DependencyKey {
    static let liveValue: any ShareServiceProtocol = ShareService.shared
}

extension DependencyValues {
    var shareService: any ShareServiceProtocol {
        get { self[ShareServiceKey.self] }
        set { self[ShareServiceKey.self] = newValue }
    }
}

// MARK: PreferencesService

private enum PreferencesServiceKey: DependencyKey {
    static let liveValue: any PreferencesServiceProtocol = PreferencesService.shared
}

extension DependencyValues {
    var preferencesService: any PreferencesServiceProtocol {
        get { self[PreferencesServiceKey.self] }
        set { self[PreferencesServiceKey.self] = newValue }
    }
}

// MARK: EntitlementService

private enum EntitlementServiceKey: DependencyKey {
    static let liveValue: any EntitlementServiceProtocol = EntitlementService.shared
}

extension DependencyValues {
    var entitlementService: any EntitlementServiceProtocol {
        get { self[EntitlementServiceKey.self] }
        set { self[EntitlementServiceKey.self] = newValue }
    }
}

// MARK: NotificationService

private enum NotificationServiceKey: DependencyKey {
    static let liveValue: any NotificationServiceProtocol = {
        MainActor.assumeIsolated { NotificationService.shared }
    }()
}

extension DependencyValues {
    var notificationService: any NotificationServiceProtocol {
        get { self[NotificationServiceKey.self] }
        set { self[NotificationServiceKey.self] = newValue }
    }
}

// MARK: AnalyticsService

private enum AnalyticsServiceKey: DependencyKey {
    static let liveValue: any AnalyticsServiceProtocol = AnalyticsService.shared
}

extension DependencyValues {
    var analyticsService: any AnalyticsServiceProtocol {
        get { self[AnalyticsServiceKey.self] }
        set { self[AnalyticsServiceKey.self] = newValue }
    }
}

// MARK: CloudSyncService

private enum CloudSyncServiceKey: DependencyKey {
    static let liveValue: any CloudSyncServiceProtocol = {
        MainActor.assumeIsolated { CloudSyncService.shared }
    }()
}

extension DependencyValues {
    var cloudSyncService: any CloudSyncServiceProtocol {
        get { self[CloudSyncServiceKey.self] }
        set { self[CloudSyncServiceKey.self] = newValue }
    }
}

// MARK: BackgroundGeneratorService

private enum BackgroundGeneratorServiceKey: DependencyKey {
    static let liveValue: any BackgroundGeneratorProtocol = BackgroundGeneratorService.shared
}

extension DependencyValues {
    var backgroundGenerator: any BackgroundGeneratorProtocol {
        get { self[BackgroundGeneratorServiceKey.self] }
        set { self[BackgroundGeneratorServiceKey.self] = newValue }
    }
}

// MARK: AIBackgroundService

private enum AIBackgroundServiceKey: DependencyKey {
    static let liveValue: any AIBackgroundServiceProtocol = AIBackgroundService.shared
}

extension DependencyValues {
    var aiBackgroundService: any AIBackgroundServiceProtocol {
        get { self[AIBackgroundServiceKey.self] }
        set { self[AIBackgroundServiceKey.self] = newValue }
    }
}

// MARK: CardCustomizationService

private enum CardCustomizationServiceKey: DependencyKey {
    static let liveValue: any CardCustomizationServiceProtocol = CardCustomizationService.shared
}

extension DependencyValues {
    var cardCustomizationService: any CardCustomizationServiceProtocol {
        get { self[CardCustomizationServiceKey.self] }
        set { self[CardCustomizationServiceKey.self] = newValue }
    }
}

// MARK: WidgetService

private enum WidgetServiceKey: DependencyKey {
    static let liveValue: any WidgetServiceProtocol = WidgetService.shared
    static let testValue: any WidgetServiceProtocol = UnimplementedWidgetService()
}

struct UnimplementedWidgetService: WidgetServiceProtocol {
    func updateWidget(entries: [(text: String, gradientColors: [String], backgroundImage: UIImage?, textColor: String?, textOutline: Bool)]) {}
    func updateFavoritesWidget(favorites: [(text: String, gradientColors: [String], backgroundImage: UIImage?, textColor: String?, textOutline: Bool)]) {}
}

extension DependencyValues {
    var widgetService: any WidgetServiceProtocol {
        get { self[WidgetServiceKey.self] }
        set { self[WidgetServiceKey.self] = newValue }
    }
}
