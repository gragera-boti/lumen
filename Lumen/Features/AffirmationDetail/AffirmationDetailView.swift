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
        .toolbar(.hidden, for: .tabBar)
        .toolbarBackground(.hidden, for: .navigationBar)
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
                    detailButton(
                        icon: isFavorited ? "heart.fill" : "heart",
                        label: "feed.favorite".localized,
                        isActive: isFavorited
                    ) {
                        toggleFavorite(affirmation)
                    }

                    detailButton(
                        icon: "paintbrush",
                        label: "feed.edit".localized
                    ) {
                        editingAffirmation = affirmation
                    }

                    detailButton(
                        icon: "square.and.arrow.up",
                        label: "feed.share".localized
                    ) {
                        shareText(displayText)
                    }
                }
                .padding(.bottom, 120)
            }
        }
    }

    private func detailButton(icon: String, label: String, isActive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: LumenTheme.Spacing.xs) {
                Image(systemName: icon)
                    .font(.title2)
                    .symbolEffect(.bounce, value: isActive)
                Text(label)
                    .font(.caption2)
            }
            .foregroundStyle(.white)
            .frame(minWidth: 60, minHeight: 44)
        }
        .accessibilityLabel(label)
    }

    private func shareText(_ text: String) {
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootVC = window.rootViewController else { return }
        rootVC.present(activityVC, animated: true)
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
