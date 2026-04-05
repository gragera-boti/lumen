import SwiftData
import SwiftUI

struct RemindersSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @State private var preferences: UserPreferences?
    @State private var notificationPermission: NotificationPermission = .unknown
    @State private var showTestSent = false

    private let preferencesService: PreferencesServiceProtocol = PreferencesService.shared
    private let notificationService: NotificationServiceProtocol = NotificationService.shared

    var body: some View {
        List {
            if let prefs = preferences {
                Section {
                    Stepper(
                        "reminders.perDay".localized(with: prefs.reminders.countPerDay),
                        value: Binding(
                            get: { prefs.reminders.countPerDay },
                            set: {
                                prefs.reminders.countPerDay = $0
                                save()
                            }
                        ),
                        in: 0...12
                    )

                    HStack {
                        Text("reminders.windowStart".localized)
                        Spacer()
                        Text(prefs.reminders.windowStart)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("reminders.windowEnd".localized)
                        Spacer()
                        Text(prefs.reminders.windowEnd)
                            .foregroundStyle(.secondary)
                    }
                }



                Section {
                    Button("reminders.testButton".localized) {
                        Task {
                            try? await notificationService.scheduleTestReminder(
                                id: "dummy_id",
                                text: "This is a test reminder from Lumen ✨"
                            )
                            showTestSent = true
                        }
                    }
                }

                Section {
                    HStack {
                        Text("reminders.permission".localized)
                        Spacer()
                        switch notificationPermission {
                        case .granted:
                            Text("reminders.enabled".localized)
                                .foregroundStyle(.green)
                        case .denied:
                            Text("reminders.disabled".localized)
                                .foregroundStyle(.red)
                        case .unknown:
                            Text("reminders.notSet".localized)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if notificationPermission == .unknown {
                        Button("reminders.enablePermissions".localized) {
                            Task {
                                let granted = try? await notificationService.requestPermission()
                                notificationPermission = (granted == true) ? .granted : .denied
                                if granted == true {
                                    preferences?.reminders.enabled = true
                                    save()
                                }
                            }
                        }
                    } else if notificationPermission == .denied {
                        Button("reminders.openSettings".localized) {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                openURL(url)
                            }
                        }
                    }
                }
            }
        }
        .ambientBackground()
        .navigationTitle("reminders.title".localized)
        .alert("reminders.testSent".localized, isPresented: $showTestSent) {
            Button("general.ok".localized) {}
        }
        .task {
            do {
                preferences = try preferencesService.getOrCreate(modelContext: modelContext)
            } catch {}
            notificationPermission = await notificationService.permissionStatus()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task {
                    notificationPermission = await notificationService.permissionStatus()
                }
            }
        }
    }

    private func save() {
        preferences?.updatedAt = .now
        try? preferencesService.save(modelContext: modelContext)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RemindersSettingsView()
    }
    .modelContainer(for: UserPreferences.self, inMemory: true)
}
