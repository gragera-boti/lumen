import SwiftUI
import SwiftData

@main
struct LumenApp: App {
    @State private var router = AppRouter()
    @State private var deepLinkHandler = DeepLinkHandler()

    init() {
        EntitlementService.shared.configure()
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Affirmation.self,
            Category.self,
            Favorite.self,
            SeenEvent.self,
            Dislike.self,
            AppTheme.self,
            UserPreferences.self,
            EntitlementState.self,
            MoodEntry.self,
        ])

        // CloudKit sync requires iCloud container entitlement in the provisioning profile.
        // Once configured in ASC + Xcode, change .none → .automatic here.
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(router)
                .onOpenURL { url in
                    deepLinkHandler.handle(url: url, router: router)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
