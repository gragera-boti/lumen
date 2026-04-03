import SwiftData
import SwiftUI

struct FeedView: View {
    @State private var viewModel = FeedViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var newAffirmationToEdit: Affirmation?

    // Crossfade transition state
    @State private var textOpacity: Double = 1.0
    @State private var backgroundOpacity: Double = 1.0
    @State private var isTransitioning = false

    let preferences: UserPreferences
    let isPremium: Bool

    // MARK: - Body

    var body: some View {
        ZStack {
            if viewModel.isLoading {
                ProgressView()
                    .tint(.white)
            } else if viewModel.showRelaxFiltersPrompt {
                emptyState
            } else {
                cardContent
            }

            topBarOverlay
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .toolbarBackground(.hidden, for: .tabBar)
        .ignoresSafeArea()
        .sheet(
            item: $newAffirmationToEdit,
            onDismiss: {
                viewModel.insertLatestUserAffirmation(modelContext: modelContext)
            }
        ) { affirmation in
            CardEditorView(
                affirmation: affirmation,
                existingCustomization: nil,
                isCreatingNew: true
            )
        }
        .sheet(item: $viewModel.editingAffirmation) { affirmation in
            CardEditorView(
                affirmation: affirmation,
                existingCustomization: viewModel.customizations[affirmation.id]
            )
        }
        .onChange(of: viewModel.editingAffirmation) { _, newValue in
            if newValue == nil {
                viewModel.reloadCustomizations(modelContext: modelContext)
            }
        }
        .task {
            await viewModel.loadFeed(
                preferences: preferences,
                isPremium: isPremium,
                modelContext: modelContext
            )
            viewModel.updateMainWidget()
        }
    }

    // MARK: - Top Bar Overlay

    private var topBarOverlay: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()

                Button {
                    newAffirmationToEdit = Affirmation(
                        id: "user_\(UUID().uuidString)",
                        text: "",
                        tone: .gentle,
                        intensity: .low,
                        source: .user,
                        tags: ["custom"]
                    )
                } label: {
                    Image(systemName: "plus")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(.white.opacity(0.2), in: Circle())
                }
                .accessibilityLabel("feed.createCustom".localized)
                .accessibilityHint("Create your own affirmation")
                .accessibilityIdentifier("feed_create_button")
                .padding(.trailing, LumenTheme.Spacing.lg)
            }
            .padding(.top, 54)

            Spacer()
        }
    }

    // MARK: - Card Content

    private var cardContent: some View {
        GeometryReader { geo in
            ZStack {
                cardBackground(geo: geo)
                ReadabilityOverlay()
                cardTextAndActions(geo: geo)
                cardTapZones
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

    @ViewBuilder
    private func cardBackground(geo: GeometryProxy) -> some View {
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
                .animation(.easeInOut(duration: 1.0), value: viewModel.currentIndex)
            }
        }
    }

    @ViewBuilder
    private func cardTextAndActions(geo: GeometryProxy) -> some View {
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
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                actionBar
                    .padding(.bottom, 120)
                    .opacity(textOpacity)
            }
            .frame(width: geo.size.width)
        }
    }

    private var cardTapZones: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard !isTransitioning else { return }
                        crossfadeToPrevious()
                    }
                    .accessibilityLabel("Previous affirmation")

                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard !isTransitioning else { return }
                        crossfadeToNext()
                    }
                    .accessibilityLabel("Next affirmation")
            }

            Color.clear
                .frame(height: 180)
                .allowsHitTesting(false)
        }
    }

    // MARK: - Crossfade Transitions

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
            viewModel.loadMoreIfNeeded(
                preferences: preferences,
                isPremium: isPremium,
                modelContext: modelContext
            )

            withAnimation(.easeInOut(duration: 0.6)) {
                textOpacity = 1
                backgroundOpacity = 1
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                isTransitioning = false
            }
        }
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack(spacing: LumenTheme.Spacing.xl) {
            feedButton(
                icon: currentAffirmation.map { viewModel.isFavorited($0) } == true ? "heart.fill" : "heart",
                label: "feed.favorite".localized,
                isActive: currentAffirmation.map { viewModel.isFavorited($0) } == true
            ) {
                viewModel.toggleFavorite(modelContext: modelContext)
            }

            feedButton(
                icon: "paintbrush",
                label: "feed.edit".localized
            ) {
                if let aff = currentAffirmation {
                    viewModel.editingAffirmation = aff
                }
            }

            feedButton(
                icon: "square.and.arrow.up",
                label: "feed.share".localized
            ) {
                if let image = viewModel.shareImage(isPremium: isPremium) {
                    presentShareSheet(image: image)
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

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView(
            "feed.empty.title".localized,
            systemImage: "slider.horizontal.3",
            description: Text("feed.empty.description".localized)
        )
    }

    // MARK: - Typography

    private func customizedFont(for affirmation: Affirmation, customization: CardCustomization?) -> Font {
        if let overrideName = customization?.fontStyleOverride,
            let style = AffirmationFontStyle.from(overrideName)
        {
            return style.cardFont(textLength: affirmation.text.count)
        }
        return affirmationFont(for: affirmation)
    }

    private func affirmationFont(for affirmation: Affirmation) -> Font {
        if let styleName = affirmation.fontStyle,
            let style = AffirmationFontStyle.from(styleName)
        {
            return style.cardFont(textLength: affirmation.text.count)
        }

        // Randomly assign one of the custom font styles for variety
        let style = randomFontStyle(for: affirmation)
        return style.cardFont(textLength: affirmation.text.count)
    }

    /// Deterministically pick a font style based on the affirmation's ID hash.
    /// Weighted toward the more versatile styles.
    private func randomFontStyle(for affirmation: Affirmation) -> AffirmationFontStyle {
        let roll = abs(affirmation.id.hashValue) % 10
        switch roll {
        case 0...3: return .playfair  // 40% — the signature font
        case 4...5: return .cormorant  // 20% — refined
        case 6: return .zilla  // 10% — slab
        case 7: return .abril  // 10% — display
        case 8: return .rounded  // 10% — soft
        default: return .josefin  // 10% — minimal
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

    // MARK: - Helpers

    private var currentAffirmation: Affirmation? {
        guard viewModel.currentIndex >= 0, viewModel.currentIndex < viewModel.cards.count else { return nil }
        return viewModel.cards[viewModel.currentIndex]
    }

    private func gradientColors(for affirmation: Affirmation) -> [Color] {
        let index = abs(affirmation.id.hashValue) % LumenTheme.Colors.gradients.count
        return LumenTheme.Colors.gradients[index]
    }

    private func presentShareSheet(image: UIImage) {
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
    FeedView(
        preferences: UserPreferences(),
        isPremium: false
    )
    .environment(AppRouter())
}
