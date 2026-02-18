import SwiftUI
import SwiftData

struct CustomAffirmationSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var selectedTone: Tone = .gentle
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Your affirmation") {
                    TextEditor(text: $text)
                        .frame(minHeight: 100)
                        .overlay(alignment: .topLeading) {
                            if text.isEmpty {
                                Text("Write something kind for yourself…")
                                    .foregroundStyle(.tertiary)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                                    .allowsHitTesting(false)
                            }
                        }
                }

                Section("Tone") {
                    Picker("Tone", selection: $selectedTone) {
                        ForEach(Tone.allCases) { tone in
                            Text(tone.displayName).tag(tone)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("New Affirmation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func save() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard trimmed.count <= 200 else {
            errorMessage = "Keep it under 200 characters."
            return
        }

        let affirmation = Affirmation(
            id: "user_\(UUID().uuidString)",
            text: trimmed,
            tone: selectedTone,
            intensity: .low,
            source: .user,
            tags: ["custom"]
        )
        modelContext.insert(affirmation)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "Couldn't save. Try again."
        }
    }
}
