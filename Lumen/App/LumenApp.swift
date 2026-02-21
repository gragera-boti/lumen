import SwiftUI
import SwiftData
import OSLog

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
            CardCustomization.self,
        ])

        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Migration failed — delete the store and retry with a fresh database
            let logger = Logger(subsystem: "com.gragera.lumen", category: "Data")
            logger.fault("ModelContainer creation failed: \(error.localizedDescription). Resetting store.")

            let storeURL = config.url
            let storePaths = [
                storeURL,
                storeURL.deletingPathExtension().appendingPathExtension("store-shm"),
                storeURL.deletingPathExtension().appendingPathExtension("store-wal"),
            ]
            for path in storePaths {
                try? FileManager.default.removeItem(at: path)
            }

            do {
                return try ModelContainer(for: schema, configurations: [config])
            } catch {
                fatalError("Could not create ModelContainer after reset: \(error)")
            }
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
