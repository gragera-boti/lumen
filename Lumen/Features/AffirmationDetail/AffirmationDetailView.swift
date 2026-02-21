import SwiftUI
import SwiftData

struct AffirmationDetailView: View {
    let affirmationId: String
    @Environment(\.modelContext) private var modelContext
    @State private var affirmation: Affirmation?
    @State private var isFavorited = false
    @State private var editingAffirmation: Affirmation?
    @State private var customization: CardCustomization?

    private let customizationService: CardCustomizationServiceProtocol = CardCustomizationService.shared

    var body: some View {
        Group {
            if let affirmation {
                detailContent(affirmation)
            } else {
                ContentUnavailableView(
                    "affirmation.notFound".localized,
                    systemImage: "text.quote"
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task { loadAffirmation() }
        .sheet(item: $editingAffirmation) { aff in
            CardEditorView(
                affirmation: aff,
                existingCustomization: customization
            )
        }
        .onChange(of: editingAffirmation) { _, newValue in
            if newValue == nil {
                reloadCustomization()
            }
        }
    }

    @ViewBuilder
    private func detailContent(_ affirmation: Affirmation) -> some View {
        let gradientIndex = abs(affirmation.id.hashValue) % LumenTheme.Colors.gradients.count
        let colors = LumenTheme.Colors.gradients[gradientIndex]
        let displayText = customization?.customText?.isEmpty == false
            ? customization!.customText!
            : affirmation.text

        ZStack {
            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            ReadabilityOverlay()
                .ignoresSafeArea()

            VStack(spacing: LumenTheme.Spacing.xl) {
                Spacer()

                Text(displayText)
                    .font(detailFont(for: affirmation))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, LumenTheme.Spacing.xl)
                    .accessibilityAddTraits(.isHeader)

                if !affirmation.categories.isEmpty {
                    HStack(spacing: LumenTheme.Spacing.xs) {
                        ForEach(affirmation.categories, id: \.id) { category in
                            Text(category.name)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(.white.opacity(0.2), in: Capsule())
                        }
                    }
                }

                Spacer()

                HStack(spacing: LumenTheme.Spacing.xl) {
                    Button {
                        toggleFavorite(affirmation)
                    } label: {
                        Label(
                            isFavorited ? "favorites.remove".localized : "favorites.add".localized,
                            systemImage: isFavorited ? "heart.fill" : "heart"
                        )
                        .font(.body)
                        .foregroundStyle(.white)
                        .padding(.horizontal, LumenTheme.Spacing.lg)
                        .padding(.vertical, LumenTheme.Spacing.sm)
                        .background(.ultraThinMaterial, in: Capsule())
                    }
                    .accessibilityLabel(isFavorited ? "Remove from favorites" : "Add to favorites")
                    .accessibilityIdentifier("detail_favorite_button")

                    Button {
                        editingAffirmation = affirmation
                    } label: {
                        Label("Edit", systemImage: "paintbrush")
                            .font(.body)
                            .foregroundStyle(.white)
                            .padding(.horizontal, LumenTheme.Spacing.lg)
                            .padding(.vertical, LumenTheme.Spacing.sm)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                    .accessibilityLabel("Customize card")
                    .accessibilityIdentifier("detail_edit_button")

                    ShareLink(item: displayText) {
                        Label("share".localized, systemImage: "square.and.arrow.up")
                            .font(.body)
                            .foregroundStyle(.white)
                            .padding(.horizontal, LumenTheme.Spacing.lg)
                            .padding(.vertical, LumenTheme.Spacing.sm)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                    .accessibilityLabel("Share affirmation")
                }
                .padding(.bottom, LumenTheme.Spacing.xxl)
            }
        }
    }

    private func detailFont(for affirmation: Affirmation) -> Font {
        if let overrideName = customization?.fontStyleOverride,
           let style = AffirmationFontStyle(rawValue: overrideName) {
            return style.cardFont(textLength: affirmation.text.count)
        }
        return .system(.title2, design: .serif, weight: .medium)
    }

    private func loadAffirmation() {
        let id = affirmationId
        let descriptor = FetchDescriptor<Affirmation>(
            predicate: #Predicate { $0.id == id }
        )
        affirmation = try? modelContext.fetch(descriptor).first
        isFavorited = affirmation?.isFavorited ?? false
        reloadCustomization()
    }

    private func reloadCustomization() {
        customization = try? customizationService.customization(
            for: affirmationId,
            modelContext: modelContext
        )
    }

    private func toggleFavorite(_ affirmation: Affirmation) {
        if let existing = affirmation.favorite {
            modelContext.delete(existing)
            isFavorited = false
        } else {
            let fav = Favorite(affirmation: affirmation)
            modelContext.insert(fav)
            isFavorited = true
        }
        try? modelContext.save()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AffirmationDetailView(affirmationId: "preview_1")
    }
    .modelContainer(for: [Affirmation.self, Favorite.self, CardCustomization.self], inMemory: true)
}
