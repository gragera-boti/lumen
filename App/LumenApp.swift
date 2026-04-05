import OSLog
import SwiftData
import SwiftUI

@main
struct LumenApp: App {
    @State private var router = AppRouter()
    @State private var deepLinkHandler = DeepLinkHandler()

    init() {
        EntitlementService.shared.configure()
        UNUserNotificationCenter.current().delegate = NotificationService.shared
    }

    static let appSchema = Schema([
        Affirmation.self,
        Category.self,
        Favorite.self,
        SeenEvent.self,
        Dislike.self,
        AppTheme.self,
        UserPreferences.self,
        EntitlementState.self,
        CardCustomization.self,
    ])

    @State private var sharedModelContainer: ModelContainer? = Self.createModelContainer()

    static func createModelContainer() -> ModelContainer? {
        let schema = appSchema

        let isSyncEnabled = UserDefaults.standard.bool(forKey: "lumen.cloudSync.enabled")
        let cloudConfig: ModelConfiguration.CloudKitDatabase = isSyncEnabled ? .automatic : .none

        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: cloudConfig
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
    }

    var body: some Scene {
        WindowGroup {
            if let container = sharedModelContainer {
                ContentView()
                    .environment(router)
                    .preferredColorScheme(.dark)
                    .onOpenURL { url in
                        deepLinkHandler.handle(url: url, router: router)
                    }
                    .modelContainer(container)
                    .onReceive(NotificationCenter.default.publisher(for: .cloudSyncToggled)) { _ in
                        sharedModelContainer = nil
                        // Allow SwiftUI to run one layout cycle with `nil` container
                        // to tear down the old CloudKit observer, before building the new one.
                        DispatchQueue.main.async {
                            sharedModelContainer = Self.createModelContainer()
                        }
                    }
            }
        }
    }
}
