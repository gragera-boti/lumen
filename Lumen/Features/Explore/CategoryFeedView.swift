import SwiftData
import SwiftUI

struct CategoryFeedView: View {
    let categoryId: String
    let preferences: UserPreferences
    let isPremium: Bool

    @State private var viewModel = CategoryFeedViewModel()
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// Whether the view is showing a fullscreen card (dark bg) vs empty state (light bg).
    private var showsFullscreenCard: Bool {
        !viewModel.isLoading && !viewModel.cards.isEmpty
    }

    // Crossfade state
    @State private var textOpacity: Double = 1.0
    @State private var backgroundOpacity: Double = 1.0
    @State private var isTransitioning = false

    var body: some View {
        ZStack {
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.cards.isEmpty {
                emptyState
            } else {
                cardContent
            }

            // Back button overlay
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(showsFullscreenCard ? .white : .primary)
                            .frame(width: 40, height: 40)
                            .background(
                                showsFullscreenCard
                                    ? AnyShapeStyle(.white.opacity(0.2))
                                    : AnyShapeStyle(.secondary.opacity(0.15)),
                                in: Circle()
                            )
                    }
                    .accessibilityLabel("Go back")
                    .accessibilityIdentifier("category_feed_back")
                    .padding(.leading, LumenTheme.Spacing.lg)

                    Spacer()

                    if !viewModel.categoryName.isEmpty {
                        Text(viewModel.categoryName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(showsFullscreenCard ? .white : .primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                showsFullscreenCard
                                    ? AnyShapeStyle(.white.opacity(0.15))
                                    : AnyShapeStyle(.secondary.opacity(0.1)),
                                in: Capsule()
                            )
                    }

                    Spacer()

                    // Spacer to balance the back button
                    Color.clear
                        .frame(width: 40, height: 40)
                        .padding(.trailing, LumenTheme.Spacing.lg)
                }
                .padding(.top, 54)

                Spacer()
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .toolbarBackground(.hidden, for: .tabBar)
        .ignoresSafeArea()
        .task(id: "\(preferences.includeSensitiveTopics)-\(preferences.gentleMode)") {
            await viewModel.loadCategory(
                categoryId: categoryId,
                preferences: preferences,
                isPremium: isPremium,
                modelContext: modelContext
            )
            viewModel.loadCustomizations(modelContext: modelContext)
        }
        .sheet(item: $viewModel.editingAffirmation) { affirmation in
            CardEditorView(
                affirmation: affirmation,
                existingCustomization: viewModel.customizations[affirmation.id]
            )
            .onDisappear {
                viewModel.reloadCustomizations(modelContext: modelContext)
            }
        }
    }

    // MARK: - Card content with crossfade

    private var cardContent: some View {
        GeometryReader { geo in
            ZStack {
                // Background
                if let current = currentAffirmation {
                    if let bgImage = viewModel.backgroundImage(for: current) {
                        Image(uiImage: bgImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                            .opacity(backgroundOpacity)
                            .animation(.easeInOut(duration: 1.0), value: viewModel.currentIndex)
                    } else {
                        LinearGradient(
                            colors: gradientColors(for: current),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .opacity(backgroundOpacity)
                        .animation(.easeInOut(duration: 1.0), value: viewModel.currentIndex)
                    }
                }

                ReadabilityOverlay()

                // Text + action bar
                if let current = currentAffirmation {
                    let customization = viewModel.customizations[current.id]
                    let displayText: String =
                        if let text = customization?.customText, !text.isEmpty {
                            text
                        } else {
                            current.text
                        }
                    VStack {
                        Spacer()

                        Text(displayText)
                            .font(customizedFont(for: current, customization: customization))
                            .tracking(letterSpacing(for: current))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .lineSpacing(8)
                            .fixedSize(horizontal: false, vertical: true)
                            .minimumScaleFactor(0.5)
                            .padding(.horizontal, 32)
                            .shadow(color: .black.opacity(0.4), radius: 8, y: 3)
                            .opacity(textOpacity)

                        Spacer()

                        actionBar
                            .padding(.bottom, 120)
                            .opacity(textOpacity)
                    }
                    .frame(width: geo.size.width)
                }

                // Tap zones — stops above action bar
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                guard !isTransitioning else { return }
                                crossfadeToPrevious()
                            }

                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                guard !isTransitioning else { return }
                                crossfadeToNext()
                            }
                    }

                    Color.clear
                        .frame(height: 180)
                        .allowsHitTesting(false)
                }
            }
        }
        .ignoresSafeArea()
        .gesture(
            DragGesture(minimumDistance: 40)
                .onEnded { value in
                    guard !isTransitioning else { return }
                    if value.translation.width < -40 {
                        crossfadeToNext()
                    } else if value.translation.width > 40 {
                        crossfadeToPrevious()
                    }
                }
        )
    }

    // MARK: - Crossfade

    private func crossfadeToNext() {
        guard viewModel.currentIndex < viewModel.cards.count - 1 else { return }
        performCrossfade { viewModel.swipeToNext() }
    }

    private func crossfadeToPrevious() {
        guard viewModel.currentIndex > 0 else { return }
        performCrossfade { viewModel.swipeToPrevious() }
    }

    private func performCrossfade(indexChange: @escaping () -> Void) {
        isTransitioning = true

        withAnimation(.easeInOut(duration: 0.5)) {
            textOpacity = 0
            backgroundOpacity = 0.3
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            indexChange()
            viewModel.recordSeen(modelContext: modelContext)

            withAnimation(.easeInOut(duration: 0.6)) {
                textOpacity = 1
                backgroundOpacity = 1
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                isTransitioning = false
            }
        }
    }

    // MARK: - Typography (matching FeedView)

    private func customizedFont(for affirmation: Affirmation, customization: CardCustomization?) -> Font {
        if let fontRaw = customization?.fontStyleOverride,
            let style = AffirmationFontStyle.from(fontRaw)
        {
            return style.cardFont(textLength: affirmation.text.count)
        }
        if let fontRaw = affirmation.fontStyle,
            let style = AffirmationFontStyle.from(fontRaw)
        {
            return style.cardFont(textLength: affirmation.text.count)
        }
        return affirmationFont(for: affirmation)
    }

    private func affirmationFont(for affirmation: Affirmation) -> Font {
        let style = randomFontStyle(for: affirmation)
        return style.cardFont(textLength: affirmation.text.count)
    }

    private func randomFontStyle(for affirmation: Affirmation) -> AffirmationFontStyle {
        let roll = abs(affirmation.id.hashValue) % 10
        switch roll {
        case 0...3: return .playfair
        case 4...5: return .cormorant
        case 6: return .zilla
        case 7: return .abril
        case 8: return .rounded
        default: return .josefin
        }
    }

    private func letterSpacing(for affirmation: Affirmation) -> CGFloat {
        let style = randomFontStyle(for: affirmation)
        switch style {
        case .josefin: return 1.5
        case .abril, .playfair: return 0.3
        case .zilla: return 0.2
        default: return 0.5
        }
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack(spacing: LumenTheme.Spacing.xl) {
            feedButton(
                icon: currentAffirmation?.isFavorited == true ? "heart.fill" : "heart",
                label: "feed.favorite".localized,
                isActive: currentAffirmation?.isFavorited == true
            ) {
                viewModel.toggleFavorite(modelContext: modelContext)
            }

            feedButton(
                icon: "paintbrush",
                label: "feed.edit".localized
            ) {
                if let current = currentAffirmation {
                    viewModel.editingAffirmation = current
                }
            }

            feedButton(
                icon: "square.and.arrow.up",
                label: "feed.share".localized
            ) {
                if let image = viewModel.shareImage(isPremium: isPremium) {
                    shareImage(image)
                }
            }
        }
    }

    private func feedButton(
        icon: String,
        label: String,
        isActive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
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

    // MARK: - Helpers

    private var currentAffirmation: Affirmation? {
        guard viewModel.currentIndex >= 0, viewModel.currentIndex < viewModel.cards.count else { return nil }
        return viewModel.cards[viewModel.currentIndex]
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No affirmations in this category",
            systemImage: "text.page",
            description: Text("Try adjusting your content filters in Settings.")
        )
    }

    private func gradientColors(for affirmation: Affirmation) -> [Color] {
        if let customization = viewModel.customizations[affirmation.id],
            let paletteRaw = customization.colorPalette,
            let palette = ColorPalette(rawValue: paletteRaw)
        {
            return palette.cgColors.map { Color(cgColor: $0) }
        }
        let index = abs(affirmation.id.hashValue) % LumenTheme.Colors.gradients.count
        return LumenTheme.Colors.gradients[index]
    }

    private func shareImage(_ image: UIImage) {
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let window = windowScene.windows.first,
            let rootVC = window.rootViewController
        else { return }
        rootVC.present(activityVC, animated: true)
    }
}

// MARK: - Preview

#Preview {
    CategoryFeedView(
        categoryId: "preview",
        preferences: UserPreferences(),
        isPremium: false
    )
    .modelContainer(for: [Affirmation.self, Category.self], inMemory: true)
}
