import SwiftUI

@MainActor @Observable
final class AppRouter {
    var selectedTab: Tab = .forYou
    var feedTargetAffirmationId: String?
    var feedPath = NavigationPath()
    var explorePath = NavigationPath()
    var favoritesPath = NavigationPath()
    var settingsPath = NavigationPath()

    var isShowingPaywall = false
    var isShowingCrisis = false

    func navigate(to destination: AppDestination, in tab: Tab) {
        switch tab {
        case .forYou: feedPath.append(destination)
        case .explore: explorePath.append(destination)
        case .favorites: favoritesPath.append(destination)
        case .settings: settingsPath.append(destination)
        }
    }

    func popToRoot(tab: Tab) {
        switch tab {
        case .forYou: feedPath = NavigationPath()
        case .explore: explorePath = NavigationPath()
        case .favorites: favoritesPath = NavigationPath()
        case .settings: settingsPath = NavigationPath()
        }
    }
}

enum Tab: String, CaseIterable, Identifiable {
    case forYou = "For You"
    case explore = "Explore"
    case favorites = "Favorites"
    case settings = "Settings"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .forYou: "sparkle"
        case .explore: "square.grid.2x2"
        case .favorites: "heart.fill"
        case .settings: "gearshape.fill"
        }
    }
}

enum AppDestination: Hashable {
    case categoryFeed(categoryId: String)
    case affirmationDetail(affirmationId: String)
    case reminders
    case themes
    case contentFilterSettings
    case subscription
    case privacyData
    case crisis
    case themeGallery
    case history
    case manageCategories(isPremium: Bool)
}
