import SwiftUI
import SwiftData

struct ContentFilterSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var preferences: UserPreferences?

    private let preferencesService: PreferencesServiceProtocol = PreferencesService.shared

    var body: some View {
        List {
            if let prefs = preferences {
                Section(header: Text("Content types"), footer: Text("Toggle which content types appear in your feed.")) {
                    Toggle("Spiritual content", isOn: binding(for: \.spiritual, prefs: prefs))
                    Toggle("Manifestation language", isOn: binding(for: \.manifestation, prefs: prefs))
                    Toggle("Body & fitness", isOn: binding(for: \.bodyFocus, prefs: prefs))
                }

                Section(header: Text("Sensitive topics"), footer: Text("These topics are hidden by default to avoid unexpected content.")) {
                    Toggle("Include sensitive topics (grief, illness)", isOn: Binding(
                        get: { prefs.includeSensitiveTopics },
                        set: {
                            prefs.includeSensitiveTopics = $0
                            save()
                        }
                    ))
                }

                Section(header: Text("Intensity")) {
                    Toggle("Gentle mode", isOn: Binding(
                        get: { prefs.gentleMode },
                        set: {
                            prefs.gentleMode = $0
                            save()
                        }
                    ))

                    Text("Gentle mode hides intense or absolute statements like \"I am unstoppable\".")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Content Filters")
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
