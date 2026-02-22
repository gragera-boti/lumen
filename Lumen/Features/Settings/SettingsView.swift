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
                subscriptionSection
                // cloudSyncSection — hidden until CloudKit container is configured in ASC
                historySection
                helpSection
                developerSection
            }
        }
        .navigationTitle("settings.title".localized)
        .task {
            await viewModel.load(modelContext: modelContext)
        }
        .alert("settings.deleteConfirm.title".localized, isPresented: $showDeleteConfirmation) {
            Button("general.delete".localized, role: .destructive) {
                viewModel.deleteAllData(modelContext: modelContext)
            }
            Button("general.cancel".localized, role: .cancel) {}
        } message: {
            Text("settings.deleteConfirm.message".localized)
        }
    }

    // MARK: - Sections

    private func contentSection(_ prefs: UserPreferences) -> some View {
        Section("settings.content".localized) {
            NavigationLink(value: AppDestination.contentFilterSettings) {
                Label("settings.contentFilters".localized, systemImage: "slider.horizontal.3")
            }

            Toggle("settings.gentleMode".localized, isOn: Binding(
                get: { prefs.gentleMode },
                set: {
                    prefs.gentleMode = $0
                    viewModel.save(modelContext: modelContext)
                }
            ))

            Picker("settings.tone".localized, selection: Binding(
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
        Section("settings.reminders".localized) {
            NavigationLink(value: AppDestination.reminders) {
                Label("settings.reminderSchedule".localized, systemImage: "bell.fill")
            }
        }
    }

    private var appearanceSection: some View {
        Section("settings.appearance".localized) {
            NavigationLink(value: AppDestination.themes) {
                Label("settings.themes".localized, systemImage: "paintpalette.fill")
            }
        }
    }

    private var subscriptionSection: some View {
        Section("settings.subscription".localized) {
            NavigationLink(value: AppDestination.subscription) {
                HStack {
                    Label(
                        viewModel.isPremium ? "settings.manageSubscription".localized : "subscription.upgrade.title".localized,
                        systemImage: viewModel.isPremium ? "star.fill" : "sparkles"
                    )
                    .foregroundStyle(viewModel.isPremium ? Color.primary : Color.orange)
                    Spacer()
                    if viewModel.isPremium {
                        Text("subscription.plan.premium".localized)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    } else {
                        Text("subscription.plan.free".localized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var historySection: some View {
        Section("settings.history".localized) {
            NavigationLink(value: AppDestination.history) {
                Label("settings.recentlyViewed".localized, systemImage: "clock.fill")
            }
        }
    }

    private var cloudSyncSection: some View {
        Section {
            HStack {
                Label("iCloud Sync", systemImage: "icloud.fill")
                Spacer()
                if viewModel.isPremium {
                    Toggle("", isOn: Binding(
                        get: { viewModel.isCloudSyncEnabled },
                        set: { viewModel.toggleCloudSync($0) }
                    ))
                    .labelsHidden()
                } else {
                    Button {
                        router.isShowingPaywall = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                            Text("Pro")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.orange.opacity(0.15)))
                    }
                }
            }
            if viewModel.isPremium && viewModel.isCloudSyncEnabled {
                Text(viewModel.cloudSyncStatusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } footer: {
            Text("Sync favorites, preferences, and themes across your devices.")
        }
    }

    private var dataSection: some View {
        Section("settings.dataPrivacy".localized) {
            NavigationLink(value: AppDestination.privacyData) {
                Label("settings.privacyData".localized, systemImage: "lock.fill")
            }

            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("settings.deleteAll".localized, systemImage: "trash.fill")
            }
            .accessibilityHint("Permanently deletes all app data")
        }
    }

    #if DEBUG
    private var developerSection: some View {
        Section("Developer") {
            Button("Reset Onboarding") {
                viewModel.resetOnboarding(modelContext: modelContext)
            }
        }
    }
    #else
    private var developerSection: some View { EmptyView() }
    #endif

    private var helpSection: some View {
        Section("settings.help".localized) {
            Button {
                router.isShowingCrisis = true
            } label: {
                Label("settings.getHelp".localized, systemImage: "heart.text.square.fill")
                    .foregroundStyle(.red)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environment(AppRouter())
    .modelContainer(for: [UserPreferences.self, AppTheme.self], inMemory: true)
}
