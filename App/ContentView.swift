import SwiftData
import SwiftUI

extension Notification.Name {
    static let onboardingReset = Notification.Name("onboardingReset")
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(AppRouter.self) private var router
    @State private var hasCompletedOnboarding = false
    @State private var isLoadingContent = true
    @State private var preferences: UserPreferences?
    @State private var isPremium = false

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
        .onChange(of: router.isShowingPaywall) { _, isShowing in
            if !isShowing {
                Task {
                    isPremium = await EntitlementService.shared.isPremium()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .onboardingReset)) { _ in
            reloadPreferences()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                scheduleNotificationsIfNeeded()
            }
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

        TabView(selection: $router.selectedTab) {
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
        case .manageCategories(let isPremium):
            ManageCategoriesView(isPremium: isPremium)
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
        syncFavoritesWidgetOnLaunch()
        isLoadingContent = false
    }

    private func syncFavoritesWidgetOnLaunch() {
        let descriptor = FetchDescriptor<Favorite>(sortBy: [SortDescriptor(\.favoritedAt, order: .reverse)])
        guard let favorites = try? modelContext.fetch(descriptor) else { return }
        let allFavs = favorites.compactMap { $0.affirmation }
        let allCustoms = try? CardCustomizationService.shared.allCustomizations(modelContext: modelContext)
        let customMap = Dictionary(uniqueKeysWithValues: (allCustoms ?? []).map { ($0.affirmationId, $0) })
        let entries = allFavs.map { aff in
            let index = abs(aff.id.hashValue) % LumenTheme.Colors.gradients.count
            let colors = LumenTheme.Colors.gradients[index].map { $0.hexString }
            let custom = customMap[aff.id]
            return (text: aff.text, gradientColors: colors, backgroundImage: nil as UIImage?, textColor: custom?.textColor, textOutline: custom?.textOutline ?? false)
        }
        WidgetService.shared.updateFavoritesWidget(favorites: entries)
    }

    private func reloadPreferences() {
        do {
            let prefs = try PreferencesService.shared.getOrCreate(modelContext: modelContext)
            preferences = prefs
            hasCompletedOnboarding = prefs.hasCompletedOnboarding
            if ProcessInfo.processInfo.arguments.contains("-UITesting") {
                hasCompletedOnboarding = true
                prefs.hasCompletedOnboarding = true
                if prefs.selectedCategoryIds.isEmpty {
                    prefs.selectedCategoryIds = ["cat_self_love", "cat_confidence", "cat_calm", "cat_motivation"]
                }
            }
        } catch {
            hasCompletedOnboarding = ProcessInfo.processInfo.arguments.contains("-UITesting")
        }
    }

    private func scheduleNotificationsIfNeeded() {
        guard let prefs = preferences, prefs.reminders.enabled else { return }
        
        let context = modelContext
        let reminderSettings = prefs.reminders
        let selectedCategoryIds = prefs.selectedCategoryIds
        
        Task {
            do {
                let permissionStatus = await NotificationService.shared.permissionStatus()
                guard permissionStatus == .granted else { return }
                
                let descriptor = FetchDescriptor<Affirmation>()
                let allAffirmations = try context.fetch(descriptor)
                
                let selectedCatIds = Set(selectedCategoryIds)
                var validAffirmations = allAffirmations
                if !selectedCatIds.isEmpty {
                    validAffirmations = allAffirmations.filter { aff in
                        let catIds = Set(aff.categories?.compactMap { $0.id } ?? [])
                        return !catIds.isDisjoint(with: selectedCatIds)
                    }
                }
                
                if validAffirmations.isEmpty {
                    validAffirmations = allAffirmations
                }
                
                var texts = validAffirmations.map { (id: $0.id, text: $0.text) }
                texts.shuffle()
                
                let neededCount = max(reminderSettings.countPerDay * 7, 7)
                var selectedAffirmations: [(id: String, text: String)] = []
                if !texts.isEmpty {
                    for i in 0..<neededCount {
                        selectedAffirmations.append(texts[i % texts.count])
                    }
                }
                
                guard !selectedAffirmations.isEmpty else { return }
                
                try await NotificationService.shared.scheduleReminders(
                    settings: reminderSettings, 
                    affirmations: selectedAffirmations
                )
            } catch {
                // Automatically fail gracefully
            }
        }
    }
}
