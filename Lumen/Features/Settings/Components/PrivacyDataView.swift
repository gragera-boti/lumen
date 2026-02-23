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
                Link("Read our privacy policy", destination: URL(string: "https://example.com/privacy")!)
            }
        }
        .ambientBackground()
        .navigationTitle("settings.privacyData".localized)
        .task {
            preferences = try? preferencesService.getOrCreate(modelContext: modelContext)
        }
        .sheet(isPresented: $showShareSheet) {
            if let data = exportedData {
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("lumen_favorites.json")
                let _ = try? data.write(to: tempURL)
                ShareLink(item: tempURL) {
                    Text("Share exported data")
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
        PrivacyDataView()
    }
    .modelContainer(for: UserPreferences.self, inMemory: true)
}
