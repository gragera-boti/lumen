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
            PaywallView()
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

                Text("Lumen")
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
                Label(Tab.forYou.rawValue, systemImage: Tab.forYou.iconName)
            }
            .tag(Tab.forYou)

            NavigationStack(path: $router.explorePath) {
                ExploreView()
                    .navigationDestination(for: AppDestination.self) { destination in
                        destinationView(for: destination, preferences: preferences)
                    }
            }
            .tabItem {
                Label(Tab.explore.rawValue, systemImage: Tab.explore.iconName)
            }
            .tag(Tab.explore)

            NavigationStack(path: $router.favoritesPath) {
                FavoritesView()
                    .navigationDestination(for: AppDestination.self) { destination in
                        destinationView(for: destination, preferences: preferences)
                    }
            }
            .tabItem {
                Label(Tab.favorites.rawValue, systemImage: Tab.favorites.iconName)
            }
            .tag(Tab.favorites)

            NavigationStack(path: $router.settingsPath) {
                SettingsView()
                    .navigationDestination(for: AppDestination.self) { destination in
                        destinationView(for: destination, preferences: preferences)
                    }
            }
            .tabItem {
                Label(Tab.settings.rawValue, systemImage: Tab.settings.iconName)
            }
            .tag(Tab.settings)
        }
        .tint(LumenTheme.Colors.primary)
    }

    // MARK: - Destination Router

    @ViewBuilder
    private func destinationView(for destination: AppDestination, preferences: UserPreferences) -> some View {
        switch destination {
        case .categoryFeed(let categoryId):
            CategoryFeedView(categoryId: categoryId, preferences: preferences, isPremium: isPremium)
        case .affirmationDetail:
            EmptyView()
        case .reminders:
            RemindersSettingsView()
        case .themes:
            ThemesSettingsView()
        case .voiceSettings:
            VoiceSettingsView()
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
        case .history:
            HistoryView()
        }
    }

    // MARK: - Bootstrap

    private func bootstrap() async {
        do {
            try await ContentService.shared.loadBundledContentIfNeeded(modelContext: modelContext)
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
