import SwiftUI
import SwiftData

struct AffirmationDetailView: View {
    let affirmationId: String
    @Environment(\.modelContext) private var modelContext
    @State private var affirmation: Affirmation?
    @State private var isFavorited = false

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
    }

    @ViewBuilder
    private func detailContent(_ affirmation: Affirmation) -> some View {
        let gradientIndex = abs(affirmation.id.hashValue) % LumenTheme.Colors.gradients.count
        let colors = LumenTheme.Colors.gradients[gradientIndex]

        ZStack {
            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            ReadabilityOverlay()
                .ignoresSafeArea()

            VStack(spacing: LumenTheme.Spacing.xl) {
                Spacer()

                Text(affirmation.text)
                    .font(.system(.title2, design: .serif, weight: .medium))
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

                    ShareLink(item: affirmation.text) {
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

    private func loadAffirmation() {
        let id = affirmationId
        let descriptor = FetchDescriptor<Affirmation>(
            predicate: #Predicate { $0.id == id }
        )
        affirmation = try? modelContext.fetch(descriptor).first
        isFavorited = affirmation?.isFavorited ?? false
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
    .modelContainer(for: [Affirmation.self, Favorite.self], inMemory: true)
}
