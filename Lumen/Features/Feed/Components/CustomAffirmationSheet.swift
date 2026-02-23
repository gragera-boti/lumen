import NaturalLanguage
import SwiftData
import SwiftUI

struct CustomAffirmationSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var text = ""
    @State private var selectedFont: AffirmationFontStyle = .playfair
    @State private var errorMessage: String?
    @State private var suggestions: [String] = []
    @State private var isLoadingSuggestions = true

    private let maxLength = 200
    private let minLength = 5

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: LumenTheme.Spacing.lg) {
                    // Live preview card
                    previewCard

                    // Text input
                    inputSection

                    // Font picker
                    fontPicker

                    // AI suggestions based on favorites
                    if !suggestions.isEmpty {
                        suggestionsSection
                    }
                }
                .padding(.horizontal, LumenTheme.Spacing.md)
                .padding(.top, LumenTheme.Spacing.sm)
                .padding(.bottom, 100)
            }
            .ambientBackground()
            .navigationTitle("Create Affirmation")
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
            .task {
                await loadSuggestions()
            }
        }
    }

    // MARK: - Preview Card

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

            Text(text.isEmpty ? "Your affirmation will appear here" : text)
                .font(selectedFont.cardFont(textLength: max(text.count, 40)))
                .foregroundStyle(.white.opacity(text.isEmpty ? 0.4 : 1.0))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 24)
                .shadow(color: .black.opacity(0.3), radius: 6, y: 2)
        }
        .frame(height: 240)
        .clipShape(RoundedRectangle(cornerRadius: LumenTheme.Radii.card))
        .animation(.easeInOut(duration: 0.3), value: selectedFont)
    }

    // MARK: - Input

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: LumenTheme.Spacing.sm) {
            Text("Your Words")
                .font(.headline)

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

                if text.isEmpty {
                    Text("Write something that lifts you up…")
                        .foregroundStyle(.tertiary)
                        .padding(.top, 20)
                        .padding(.leading, 16)
                        .allowsHitTesting(false)
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

    // MARK: - Font Picker

    private var fontPicker: some View {
        VStack(alignment: .leading, spacing: LumenTheme.Spacing.sm) {
            Text("Font Style")
                .font(.headline)

            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ],
                spacing: LumenTheme.Spacing.sm
            ) {
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

    // MARK: - ML Suggestions

    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: LumenTheme.Spacing.sm) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.purple)
                Text("Inspired by your favorites")
                    .font(.headline)
            }

            ForEach(suggestions, id: \.self) { suggestion in
                Button {
                    withAnimation {
                        text = suggestion
                    }
                } label: {
                    HStack {
                        Text(suggestion)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(3)
                        Spacer()
                        Image(systemName: "arrow.up.left")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: LumenTheme.Radii.sm)
                            .fill(Color(.systemBackground))
                    )
                }
            }
        }
    }

    // MARK: - Validation

    private var isValid: Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= minLength && trimmed.count <= maxLength
    }

    // MARK: - Save

    private func save() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= minLength else {
            errorMessage = "Too short — write at least \(minLength) characters"
            return
        }
        guard trimmed.count <= maxLength else {
            errorMessage = "Too long — max \(maxLength) characters"
            return
        }

        let affirmation = Affirmation(
            id: "user_\(UUID().uuidString)",
            text: trimmed,
            tone: .gentle,
            intensity: .low,
            source: .user,
            tags: ["custom"]
        )
        affirmation.fontStyle = selectedFont.rawValue
        modelContext.insert(affirmation)

        // Auto-favorite — you wrote it, you care about it
        let favorite = Favorite(affirmation: affirmation)
        modelContext.insert(favorite)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "Couldn't save. Try again."
        }
    }

    // MARK: - ML Suggestions

    private func loadSuggestions() async {
        defer { isLoadingSuggestions = false }

        // Fetch favorited affirmation texts
        let favoriteTexts = fetchFavoriteTexts()
        guard favoriteTexts.count >= 3 else { return }

        // Use NaturalLanguage embedding to find themes in favorites
        // then generate starter phrases based on common patterns
        await generateSuggestions(from: favoriteTexts)
    }

    private func fetchFavoriteTexts() -> [String] {
        do {
            let descriptor = FetchDescriptor<Favorite>(
                sortBy: [SortDescriptor(\.favoritedAt, order: .reverse)]
            )
            let favorites = try modelContext.fetch(descriptor)
            return favorites.compactMap { $0.affirmation?.text }.prefix(20).map { $0 }
        } catch {
            return []
        }
    }

    @MainActor
    private func generateSuggestions(from favoriteTexts: [String]) async {
        // Extract common opening patterns and themes from favorites
        var starters: [String: Int] = [:]
        var themes: [String] = []

        let tagger = NLTagger(tagSchemes: [.lemma, .nameType])

        for text in favoriteTexts {
            // Extract first few words as a starter pattern
            let words = text.split(separator: " ").prefix(3).joined(separator: " ")
            if words.count > 2 {
                starters[words, default: 0] += 1
            }

            // Extract key nouns/themes
            tagger.string = text
            tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lemma) { tag, range in
                if let lemma = tag?.rawValue, lemma.count > 3 {
                    let word = String(text[range]).lowercased()
                    if !Self.stopWords.contains(word) && !Self.stopWords.contains(lemma.lowercased()) {
                        themes.append(lemma)
                    }
                }
                return true
            }
        }

        // Find most common themes
        let themeCounts = Dictionary(themes.map { ($0, 1) }, uniquingKeysWith: +)
        let topThemes = themeCounts.sorted { $0.value > $1.value }.prefix(5).map { $0.key }

        // Generate personalized starters based on patterns
        var generated: [String] = []

        // Pattern-based suggestions using top themes
        let templates = [
            "I embrace my {theme} with gratitude",
            "Every day, my {theme} grows stronger",
            "I am worthy of {theme} and joy",
            "My {theme} inspires those around me",
            "I choose {theme} in every moment",
        ]

        for (i, theme) in topThemes.prefix(3).enumerated() {
            if i < templates.count {
                let suggestion = templates[i].replacingOccurrences(of: "{theme}", with: theme.lowercased())
                generated.append(suggestion)
            }
        }

        // Add a couple based on frequent starters
        let topStarters = starters.sorted { $0.value > $1.value }.prefix(2)
        for starter in topStarters {
            if !generated.contains(where: { $0.hasPrefix(starter.key) }) {
                // Complete the starter with a theme
                if let theme = topThemes.first {
                    generated.append("\(starter.key) \(theme.lowercased()) guides my path")
                }
            }
        }

        suggestions = Array(generated.prefix(5))
    }

    private static let stopWords: Set<String> = [
        "i", "my", "me", "am", "is", "are", "the", "a", "an", "and", "or",
        "to", "in", "of", "for", "with", "that", "this", "have", "has",
        "can", "will", "do", "be", "it", "not", "but", "all", "each",
        "every", "from", "into", "through", "than", "more", "most",
        "own", "being", "been", "was", "were", "their", "them", "they",
    ]
}

// MARK: - Preview

#Preview {
    CustomAffirmationSheet()
        .modelContainer(for: [Affirmation.self, Favorite.self], inMemory: true)
}
