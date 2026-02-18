import SwiftUI
import SwiftData

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @Environment(\.modelContext) private var modelContext
    @Environment(AppRouter.self) private var router
    @State private var showDeleteConfirmation = false

    var body: some View {
        List {
            if let prefs = viewModel.preferences {
                contentSection(prefs)
                remindersSection(prefs)
                appearanceSection
                voiceSection
                subscriptionSection
                historySection
                dataSection
                helpSection
            }
        }
        .navigationTitle("Settings")
        .task {
            await viewModel.load(modelContext: modelContext)
        }
        .alert("Delete all data?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                viewModel.deleteAllData(modelContext: modelContext)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will reset the app to its initial state. This cannot be undone.")
        }
    }

    // MARK: - Sections

    private func contentSection(_ prefs: UserPreferences) -> some View {
        Section("Content") {
            NavigationLink(value: AppDestination.contentFilterSettings) {
                Label("Content Filters", systemImage: "slider.horizontal.3")
            }

            Toggle("Gentle Mode", isOn: Binding(
                get: { prefs.gentleMode },
                set: {
                    prefs.gentleMode = $0
                    viewModel.save(modelContext: modelContext)
                }
            ))

            Picker("Tone", selection: Binding(
                get: { prefs.tonePreset },
                set: {
                    prefs.tonePreset = $0
                    viewModel.save(modelContext: modelContext)
                }
            )) {
                ForEach(Tone.allCases) { tone in
                    Text(tone.displayName).tag(tone)
                }
            }
        }
    }

    private func remindersSection(_ prefs: UserPreferences) -> some View {
        Section("Reminders") {
            NavigationLink(value: AppDestination.reminders) {
                Label("Reminder Schedule", systemImage: "bell.fill")
            }
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            NavigationLink(value: AppDestination.themes) {
                Label("Themes & Backgrounds", systemImage: "paintpalette.fill")
            }
        }
    }

    private var voiceSection: some View {
        Section("Voice") {
            NavigationLink(value: AppDestination.voiceSettings) {
                Label("Voice Settings", systemImage: "speaker.wave.2.fill")
            }
        }
    }

    private var subscriptionSection: some View {
        Section("Subscription") {
            NavigationLink(value: AppDestination.subscription) {
                HStack {
                    Label("Manage Subscription", systemImage: "star.fill")
                    Spacer()
                    if viewModel.isPremium {
                        Text("Premium")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
    }

    private var historySection: some View {
        Section("History") {
            NavigationLink(value: AppDestination.history) {
                Label("Recently Viewed", systemImage: "clock.fill")
            }
        }
    }

    private var dataSection: some View {
        Section("Data & Privacy") {
            NavigationLink(value: AppDestination.privacyData) {
                Label("Privacy & Data", systemImage: "lock.fill")
            }

            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("Delete All Data", systemImage: "trash.fill")
            }
        }
    }

    private var helpSection: some View {
        Section("Help") {
            Button {
                router.isShowingCrisis = true
            } label: {
                Label("Get help now", systemImage: "heart.text.square.fill")
                    .foregroundStyle(.red)
            }
        }
    }
}
