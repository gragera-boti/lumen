import SwiftData
import SwiftUI

struct PrivacyDataView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var preferences: UserPreferences?
    @State private var exportedData: Data?
    @State private var showShareSheet = false

    private let preferencesService: PreferencesServiceProtocol = PreferencesService.shared

    var body: some View {
        List {
            if let prefs = preferences {
                Section("Analytics") {
                    Toggle(
                        "Opt out of analytics",
                        isOn: Binding(
                            get: { prefs.analyticsOptOut },
                            set: {
                                prefs.analyticsOptOut = $0
                                save()
                            }
                        )
                    )

                    Text("When opted out, no usage data is collected.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Your Data") {
                Button("Export favorites as JSON") {
                    let settingsVM = SettingsViewModel()
                    exportedData = settingsVM.exportData(modelContext: modelContext)
                    if exportedData != nil {
                        showShareSheet = true
                    }
                }

                Text("Your data is stored locally on this device. No account is required.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Privacy Policy") {
                if let privacyURL = URL(string: "https://example.com/privacy") {
                    Link("Read our privacy policy", destination: privacyURL)
                }
            }
        }
        .ambientBackground()
        .navigationTitle("settings.privacyData".localized)
        .task {
            preferences = try? preferencesService.getOrCreate(modelContext: modelContext)
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = exportedFileURL {
                ShareLink(item: url) {
                    Text("Share exported data")
                }
            }
        }
    }

    private var exportedFileURL: URL? {
        guard let data = exportedData else { return nil }
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("lumen_favorites.json")
        try? data.write(to: tempURL)
        return tempURL
    }

    private func save() {
        preferences?.updatedAt = .now
        try? preferencesService.save(modelContext: modelContext)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PrivacyDataView()
    }
    .modelContainer(for: UserPreferences.self, inMemory: true)
}
