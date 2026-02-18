import SwiftUI
import AVFoundation
import SwiftData

struct VoiceSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var preferences: UserPreferences?
    @State private var availableVoices: [AVSpeechSynthesisVoice] = []

    private let preferencesService: PreferencesServiceProtocol = PreferencesService.shared
    private let speechService: SpeechServiceProtocol = SpeechService.shared

    var body: some View {
        List {
            if let prefs = preferences {
                Section("Speed") {
                    VStack(alignment: .leading) {
                        Text("Rate: \(prefs.voice.rate, specifier: "%.1f")×")
                        Slider(value: Binding(
                            get: { Double(prefs.voice.rate) },
                            set: {
                                prefs.voice.rate = Float($0)
                                save()
                            }
                        ), in: 0.5...1.5, step: 0.1)
                    }
                }

                Section("Language") {
                    Picker("Language", selection: Binding(
                        get: { prefs.voice.language },
                        set: {
                            prefs.voice.language = $0
                            prefs.voice.voiceId = ""
                            save()
                            loadVoices(for: $0)
                        }
                    )) {
                        Text("English (UK)").tag("en-GB")
                        Text("English (US)").tag("en-US")
                        Text("Spanish").tag("es-ES")
                    }
                }

                Section("Voice") {
                    ForEach(availableVoices, id: \.identifier) { voice in
                        Button {
                            prefs.voice.voiceId = voice.identifier
                            save()
                        } label: {
                            HStack {
                                Text(voice.name)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if prefs.voice.voiceId == voice.identifier {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.accent)
                                }
                            }
                        }
                    }
                }

                Section {
                    Button("Preview voice") {
                        Task {
                            await speechService.speak(
                                text: "I can take one small step today.",
                                voice: prefs.voice
                            )
                        }
                    }
                }
            }
        }
        .navigationTitle("Voice")
        .task {
            preferences = try? preferencesService.getOrCreate(modelContext: modelContext)
            if let lang = preferences?.voice.language {
                loadVoices(for: lang)
            }
        }
    }

    private func loadVoices(for language: String) {
        availableVoices = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix(language.prefix(2).lowercased()) }
            .sorted { $0.name < $1.name }
    }

    private func save() {
        preferences?.updatedAt = .now
        try? preferencesService.save(modelContext: modelContext)
    }
}
