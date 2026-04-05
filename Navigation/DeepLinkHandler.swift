import Foundation
import OSLog

@MainActor @Observable
final class DeepLinkHandler {
    private let logger = Logger(subsystem: "com.gragera.lumen", category: "DeepLink")

    func handle(url: URL, router: AppRouter) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            components.scheme == "lumen"
        else { return }

        let pathParts = components.path.split(separator: "/").map(String.init)

        switch components.host {
        case "affirmation":
            if let id = pathParts.first {
                router.selectedTab = .forYou
                router.feedTargetAffirmationId = id
            }
        case "category":
            if let id = pathParts.first {
                router.navigate(to: .categoryFeed(categoryId: id), in: .explore)
            }
        case "favorites":
            break  // Tab switch handled externally
        case "settings":
            if pathParts.first == "reminders" {
                router.navigate(to: .reminders, in: .settings)
            }
        case "paywall":
            router.isShowingPaywall = true
        case "help":
            if pathParts.first == "crisis" {
                router.isShowingCrisis = true
            }
        default:
            logger.warning("Unhandled deep link: \(url.absoluteString)")
        }
    }
}
