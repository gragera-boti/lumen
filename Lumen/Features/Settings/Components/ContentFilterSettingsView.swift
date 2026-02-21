import SwiftUI
import SwiftData

struct ContentFilterSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var preferences: UserPreferences?

    private let preferencesService: PreferencesServiceProtocol = PreferencesService.shared

    var body: some View {
        List {
            if let prefs = preferences {
                Section(header: Text("filters.contentTypes".localized), footer: Text("filters.contentTypesFooter".localized)) {
                    Toggle("filters.spiritual".localized, isOn: binding(for: \.spiritual, prefs: prefs))
                    Toggle("filters.manifestation".localized, isOn: binding(for: \.manifestation, prefs: prefs))
                    Toggle("filters.bodyFocus".localized, isOn: binding(for: \.bodyFocus, prefs: prefs))
                }

                Section(header: Text("filters.sensitiveTopics".localized), footer: Text("filters.sensitiveFooter".localized)) {
                    Toggle("filters.includeSensitive".localized, isOn: Binding(
                        get: { prefs.includeSensitiveTopics },
                        set: {
                            prefs.includeSensitiveTopics = $0
                            save()
                        }
                    ))
                }

                Section(header: Text("filters.intensity".localized)) {
                    Toggle("filters.gentleMode".localized, isOn: Binding(
                        get: { prefs.gentleMode },
                        set: {
                            prefs.gentleMode = $0
                            save()
                        }
                    ))

                    Text("filters.gentleModeDescription".localized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("filters.title".localized)
        .task {
            preferences = try? preferencesService.getOrCreate(modelContext: modelContext)
        }
    }

    private func binding(for keyPath: WritableKeyPath<ContentFilters, Bool>, prefs: UserPreferences) -> Binding<Bool> {
        Binding(
            get: { prefs.contentFilters[keyPath: keyPath] },
            set: { newValue in
                var filters = prefs.contentFilters
                filters[keyPath: keyPath] = newValue
                prefs.contentFilters = filters
                save()
            }
        )
    }

    private func save() {
        preferences?.updatedAt = .now
        try? preferencesService.save(modelContext: modelContext)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ContentFilterSettingsView()
    }
    .modelContainer(for: UserPreferences.self, inMemory: true)
}
