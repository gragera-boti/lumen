import SwiftUI
import SwiftData

struct RemindersSettingsView: View {
    @Environment(\.modelContext) private var modelContext
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
                    HStack {
                        Text("reminders.quietStart".localized)
                        Spacer()
                        Text(prefs.reminders.quietStart)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("reminders.quietEnd".localized)
                        Spacer()
                        Text(prefs.reminders.quietEnd)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button("reminders.testButton".localized) {
                        Task {
                            try? await notificationService.scheduleReminders(
                                settings: ReminderSettings(
                                    enabled: true,
                                    countPerDay: 1,
                                    windowStart: "00:00",
                                    windowEnd: "23:59",
                                    quietStart: "00:00",
                                    quietEnd: "00:00"
                                ),
                                affirmationTexts: ["This is a test reminder from Lumen ✨"]
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
