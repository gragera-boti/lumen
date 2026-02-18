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
                        "Reminders per day: \(prefs.reminders.countPerDay)",
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
                        Text("Window start")
                        Spacer()
                        Text(prefs.reminders.windowStart)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Window end")
                        Spacer()
                        Text(prefs.reminders.windowEnd)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Quiet Hours") {
                    HStack {
                        Text("Quiet start")
                        Spacer()
                        Text(prefs.reminders.quietStart)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Quiet end")
                        Spacer()
                        Text(prefs.reminders.quietEnd)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button("Send test notification") {
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
                        Text("Notification permission")
                        Spacer()
                        switch notificationPermission {
                        case .granted:
                            Text("Enabled")
                                .foregroundStyle(.green)
                        case .denied:
                            Text("Disabled")
                                .foregroundStyle(.red)
                        case .unknown:
                            Text("Not set")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Reminders")
        .alert("Test sent!", isPresented: $showTestSent) {
            Button("OK") {}
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
