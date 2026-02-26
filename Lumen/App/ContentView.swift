import SwiftData
import SwiftUI

extension Notification.Name {
    static let onboardingReset = Notification.Name("onboardingReset")
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppRouter.self) private var router
    @State private var hasCompletedOnboarding = false
    @State private var isLoadingContent = true
    @State private var preferences: UserPreferences?
    @State private var isPremium = false
    @State private var selectedTab: Tab = .forYou

    init() {
        // Configure tab bar and nav bar appearance once at init
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithTransparentBackground()
        tabAppearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance

        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithTransparentBackground()
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
    }

    var body: some View {
        ZStack {
            // Main content underneath
            if !isLoadingContent {
                if !hasCompletedOnboarding {
                    OnboardingView {
                        reloadPreferences()
                    }
                } else if let prefs = preferences {
                    mainTabView(preferences: prefs)
                }
            }

            // Splash overlay that fades out
            if isLoadingContent {
                launchScreen
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.4), value: isLoadingContent)
        .task {
            await bootstrap()
        }
        .sheet(
            isPresented: Binding(
                get: { router.isShowingPaywall },
                set: { router.isShowingPaywall = $0 }
            )
        ) {
            LumenPaywallView()
        }
        .sheet(
            isPresented: Binding(
                get: { router.isShowingCrisis },
                set: { router.isShowingCrisis = $0 }
            )
        ) {
            CrisisView()
        }
        .onReceive(NotificationCenter.default.publisher(for: .onboardingReset)) { _ in
            reloadPreferences()
        }
    }

    // MARK: - Launch Screen

    private var launchScreen: some View {
        ZStack {
            LinearGradient(
                colors: [LumenTheme.Colors.ambientDark, LumenTheme.Colors.ambientMid],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: LumenTheme.Spacing.md) {
                Image(systemName: "sparkle")
                    .font(.system(size: 48))
                    .foregroundStyle(.white)
                    .symbolEffect(.pulse)

                Text("app.name".localized)
                    .font(.system(.largeTitle, design: .serif, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Main Tab View

    @ViewBuilder
    private func mainTabView(preferences: UserPreferences) -> some View {
        @Bindable var router = router

        TabView(selection: $selectedTab) {
            NavigationStack(path: $router.feedPath) {
                FeedView(preferences: preferences, isPremium: isPremium)
                    .navigationDestination(for: AppDestination.self) { destination in
                        destinationView(for: destination, preferences: preferences)
                    }
            }
            .tabItem {
                Label("tab.forYou".localized, systemImage: Tab.forYou.iconName)
            }
            .tag(Tab.forYou)

            NavigationStack(path: $router.explorePath) {
                ExploreView()
                    .navigationDestination(for: AppDestination.self) { destination in
                        destinationView(for: destination, preferences: preferences)
                    }
            }
            .tabItem {
                Label("tab.explore".localized, systemImage: Tab.explore.iconName)
            }
            .tag(Tab.explore)

            NavigationStack(path: $router.favoritesPath) {
                FavoritesView()
                    .navigationDestination(for: AppDestination.self) { destination in
                        destinationView(for: destination, preferences: preferences)
                    }
            }
            .tabItem {
                Label("tab.favorites".localized, systemImage: Tab.favorites.iconName)
            }
            .tag(Tab.favorites)

            NavigationStack(path: $router.settingsPath) {
                SettingsView()
                    .navigationDestination(for: AppDestination.self) { destination in
                        destinationView(for: destination, preferences: preferences)
                    }
            }
            .tabItem {
                Label("tab.settings".localized, systemImage: Tab.settings.iconName)
            }
            .tag(Tab.settings)
        }
        .tint(LumenTheme.Colors.primary)
        .background(Color.black)
    }

    // MARK: - Destination Router

    @ViewBuilder
    private func destinationView(for destination: AppDestination, preferences: UserPreferences) -> some View {
        switch destination {
        case .categoryFeed(let categoryId):
            CategoryFeedView(categoryId: categoryId, preferences: preferences, isPremium: isPremium)
        case .affirmationDetail(let affirmationId):
            AffirmationDetailView(affirmationId: affirmationId)
        case .reminders:
            RemindersSettingsView()
        case .themes:
            ThemesSettingsView()
        case .contentFilterSettings:
            ContentFilterSettingsView()
        case .subscription:
            SubscriptionView()
        case .privacyData:
            PrivacyDataView()
        case .crisis:
            CrisisView()
        case .themeGallery:
            ThemeGalleryView()
        case .history:
            HistoryView()
        case .manageCategories:
            ManageCategoriesView()
        }
    }

    // MARK: - Bootstrap

    private func bootstrap() async {
        do {
            try ContentService.shared.loadBundledContentIfNeeded(modelContext: modelContext)
        } catch {
            // Content load failed — continue with whatever is available
        }

        reloadPreferences()
        isPremium = await EntitlementService.shared.isPremium()
        isLoadingContent = false
    }

    private func reloadPreferences() {
        do {
            let prefs = try PreferencesService.shared.getOrCreate(modelContext: modelContext)
            preferences = prefs
            hasCompletedOnboarding = prefs.hasCompletedOnboarding
        } catch {
            hasCompletedOnboarding = false
        }
    }
}
