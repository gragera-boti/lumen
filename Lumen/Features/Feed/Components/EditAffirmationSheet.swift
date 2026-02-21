import SwiftUI
import SwiftData

struct EditAffirmationSheet: View {
    let affirmation: Affirmation

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var text: String
    @State private var selectedFont: AffirmationFontStyle
    @State private var errorMessage: String?

    private let maxLength = 200
    private let minLength = 5

    init(affirmation: Affirmation) {
        self.affirmation = affirmation
        _text = State(initialValue: affirmation.text)
        let style = affirmation.fontStyle.flatMap { AffirmationFontStyle(rawValue: $0) } ?? .serif
        _selectedFont = State(initialValue: style)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: LumenTheme.Spacing.lg) {
                    previewCard
                    inputSection
                    fontPicker
                }
                .padding(.horizontal, LumenTheme.Spacing.md)
                .padding(.top, LumenTheme.Spacing.sm)
                .padding(.bottom, 100)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Edit Affirmation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(!isValid)
                }
            }
        }
    }

    private var previewCard: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.28, green: 0.15, blue: 0.55),
                    Color(red: 0.50, green: 0.25, blue: 0.65),
                    Color(red: 0.70, green: 0.30, blue: 0.55),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            ReadabilityOverlay(opacity: 0.2)

            Text(text.isEmpty ? "Your affirmation" : text)
                .font(selectedFont.cardFont(textLength: max(text.count, 40)))
                .foregroundStyle(.white.opacity(text.isEmpty ? 0.4 : 1.0))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 24)
                .shadow(color: .black.opacity(0.3), radius: 6, y: 2)
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: LumenTheme.Radii.card))
        .animation(.easeInOut(duration: 0.3), value: selectedFont)
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: LumenTheme.Spacing.sm) {
            ZStack(alignment: .topLeading) {
                TextEditor(text: $text)
                    .frame(minHeight: 80, maxHeight: 120)
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: LumenTheme.Radii.sm)
                            .fill(Color(.systemBackground))
                    )
                    .onChange(of: text) { _, newValue in
                        if newValue.count > maxLength {
                            text = String(newValue.prefix(maxLength))
                        }
                    }
            }

            HStack {
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                Spacer()
                Text("\(text.count)/\(maxLength)")
                    .font(.caption)
                    .foregroundStyle(text.count > maxLength - 20 ? .orange : .secondary)
            }
        }
    }

    private var fontPicker: some View {
        VStack(alignment: .leading, spacing: LumenTheme.Spacing.sm) {
            Text("Font Style")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: LumenTheme.Spacing.sm) {
                ForEach(AffirmationFontStyle.allCases) { style in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedFont = style
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Text("Aa")
                                .font(style.previewFont(size: 22))
                                .frame(height: 36)
                            Text(style.displayName)
                                .font(.caption2)
                        }
                        .foregroundStyle(selectedFont == style ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: LumenTheme.Radii.sm)
                                .fill(selectedFont == style ? LumenTheme.Colors.primary : Color(.systemBackground))
                        )
                    }
                }
            }
        }
    }

    private var isValid: Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= minLength && trimmed.count <= maxLength
    }

    private func save() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= minLength else {
            errorMessage = "Too short — at least \(minLength) characters"
            return
        }

        affirmation.text = trimmed
        affirmation.fontStyle = selectedFont.rawValue
        affirmation.updatedAt = .now

        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "Couldn't save. Try again."
        }
    }
}

// MARK: - Preview

#Preview {
    EditAffirmationSheet(
        affirmation: Affirmation(
            id: "preview_edit",
            text: "I embrace every new day with gratitude",
            tone: .gentle,
            source: .user
        )
    )
    .modelContainer(for: Affirmation.self, inMemory: true)
}
