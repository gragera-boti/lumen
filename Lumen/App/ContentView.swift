import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppRouter.self) private var router
    @State private var hasCompletedOnboarding = false
    @State private var isLoadingContent = true
    @State private var preferences: UserPreferences?
    @State private var isPremium = false
    @State private var selectedTab: Tab = .forYou

    var body: some View {
        Group {
            if isLoadingContent {
                launchScreen
            } else if !hasCompletedOnboarding {
                OnboardingView {
                    reloadPreferences()
                }
            } else if let prefs = preferences {
                mainTabView(preferences: prefs)
            }
        }
        .task {
            await bootstrap()
        }
        .sheet(isPresented: Binding(
            get: { router.isShowingPaywall },
            set: { router.isShowingPaywall = $0 }
        )) {
            LumenPaywallView()
        }
        .sheet(isPresented: Binding(
            get: { router.isShowingCrisis },
            set: { router.isShowingCrisis = $0 }
        )) {
            CrisisView()
        }
    }

    // MARK: - Launch Screen

    private var launchScreen: some View {
        ZStack {
            AnimatedGradientBackground(colors: [
                LumenTheme.Colors.gentleAccent,
                LumenTheme.Colors.softPurple,
            ])

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
        .onAppear {
            // Glass tab bar that floats over feed content
            let tabAppearance = UITabBarAppearance()
            tabAppearance.configureWithTransparentBackground()
            tabAppearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
            UITabBar.appearance().standardAppearance = tabAppearance
            UITabBar.appearance().scrollEdgeAppearance = tabAppearance

            // Transparent navigation bar so feed extends edge-to-edge
            let navAppearance = UINavigationBarAppearance()
            navAppearance.configureWithTransparentBackground()
            UINavigationBar.appearance().standardAppearance = navAppearance
            UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
            UINavigationBar.appearance().compactAppearance = navAppearance
        }
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
        case .themeGenerator:
            ThemeGeneratorView()
        case .themeGallery:
            ThemeGalleryView()
        case .history:
            HistoryView()
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
