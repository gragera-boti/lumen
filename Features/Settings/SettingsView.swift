import SwiftData
import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @Environment(\.modelContext) private var modelContext
    @Environment(AppRouter.self) private var router
    @State private var showDeleteConfirmation = false

    var body: some View {
        List {
            if let prefs = viewModel.preferences {
                subscriptionSection
                contentSection(prefs)
                remindersSection(prefs)
                appearanceSection
                cloudSyncSection
                historySection
                developerSection
            }
        }
        .ambientBackground()
        .navigationTitle("settings.title".localized)
        .task {
            await viewModel.load(modelContext: modelContext)
        }
        .onChange(of: router.isShowingPaywall) { _, isShowing in
            if !isShowing {
                Task {
                    await viewModel.load(modelContext: modelContext)
                }
            }
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
            NavigationLink(value: AppDestination.manageCategories(isPremium: viewModel.isPremium)) {
                Label("Manage Categories", systemImage: "list.bullet")
            }

            NavigationLink(value: AppDestination.contentFilterSettings) {
                Label("settings.contentFilters".localized, systemImage: "slider.horizontal.3")
            }

            Toggle(
                "settings.gentleMode".localized,
                isOn: Binding(
                    get: { prefs.gentleMode },
                    set: {
                        prefs.gentleMode = $0
                        viewModel.save(modelContext: modelContext)
                    }
                )
            )

            Picker(
                "settings.tone".localized,
                selection: Binding(
                    get: { prefs.tonePreset },
                    set: {
                        prefs.tonePreset = $0
                        viewModel.save(modelContext: modelContext)
                    }
                )
            ) {
                ForEach(Tone.allCases) { tone in
                    Text(tone.displayName).tag(tone)
                }
            }
        }
    }

    private func remindersSection(_: UserPreferences) -> some View {
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
        Section {
            if viewModel.isPremium {
                NavigationLink(value: AppDestination.subscription) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "star.fill").foregroundStyle(.orange)
                                // We can use the premium plan name directly
                                Text("Lumen Pro").font(.headline).fontWeight(.semibold)
                            }
                            Text("settings.manageSubscription".localized)
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("Active")
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Color.green.opacity(0.1))
                            .foregroundStyle(.green)
                            .clipShape(Capsule())
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Color.orange.opacity(0.05))
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "sparkles").foregroundStyle(.orange)
                        Text("subscription.upgrade.title".localized).font(.headline).fontWeight(.semibold)
                        Spacer()
                    }
                    Text("subscription.upgrade.subtitle".localized)
                        .font(.subheadline).foregroundStyle(.secondary)
                    
                    Button {
                        router.isShowingPaywall = true
                    } label: {
                        Text("subscription.upgrade.title".localized)
                            .font(.headline).foregroundStyle(.white)
                            .frame(maxWidth: .infinity).padding()
                            .background(Color.orange)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
                .listRowBackground(Color.orange.opacity(0.05))
                .accessibilityIdentifier("paywall_subscription_button")
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
                    Toggle(
                        "",
                        isOn: Binding(
                            get: { viewModel.isCloudSyncEnabled },
                            set: { viewModel.toggleCloudSync($0) }
                        )
                    )
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
        } header: {
            Text("Data")
        } footer: {
            Text("Sync favorites, preferences, and themes across your devices.")
        }
    }

    // periphery:ignore - hidden until CloudKit container is configured
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

    private var developerSection: some View {
        Section("Developer") {
            Button("Reset Onboarding") {
                viewModel.resetOnboarding(modelContext: modelContext)
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
