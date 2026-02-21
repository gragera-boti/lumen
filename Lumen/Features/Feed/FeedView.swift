import SwiftUI
import SwiftData

struct FeedView: View {
    @State private var viewModel = FeedViewModel()
    @Environment(\.modelContext) private var modelContext
    @Environment(AppRouter.self) private var router
    @State private var showCustomAffirmation = false

    // Crossfade transition state
    @State private var textOpacity: Double = 1.0
    @State private var backgroundOpacity: Double = 1.0
    @State private var isTransitioning = false

    let preferences: UserPreferences
    let isPremium: Bool

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

            // Floating top bar + mood check-in
            VStack(spacing: 0) {
                HStack {
                    if let mood = viewModel.currentMood, !viewModel.needsMoodCheckIn {
                        Button {
                            withAnimation(.spring(response: 0.35)) {
                                viewModel.needsMoodCheckIn = true
                            }
                        } label: {
                            Text(mood.emoji)
                                .font(.title2)
                                .frame(width: 40, height: 40)
                                .background(.white.opacity(0.2), in: Circle())
                        }
                        .padding(.leading, LumenTheme.Spacing.lg)
                    }

                    Spacer()

                    Button {
                        showCustomAffirmation = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(.white.opacity(0.2), in: Circle())
                    }
                    .accessibilityLabel("feed.createCustom".localized)
                    .padding(.trailing, LumenTheme.Spacing.lg)
                }
                .padding(.top, 54)

                if viewModel.needsMoodCheckIn {
                    MoodCheckInView { mood in
                        Task {
                            await viewModel.recordMood(
                                mood,
                                preferences: preferences,
                                isPremium: isPremium,
                                modelContext: modelContext
                            )
                        }
                    }
                    .padding(.top, LumenTheme.Spacing.md)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                Spacer()
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .toolbarBackground(.hidden, for: .tabBar)
        .ignoresSafeArea()
        .sheet(isPresented: $showCustomAffirmation, onDismiss: {
            // Insert newly created affirmation right after current card
            viewModel.insertLatestUserAffirmation(modelContext: modelContext)
        }) {
            CustomAffirmationSheet()
        }
        .task {
            await viewModel.loadFeed(
                preferences: preferences,
                isPremium: isPremium,
                modelContext: modelContext
            )
            updateWidget()
        }
        // Auto-advance disabled — user navigates via tap or swipe
    }

    // MARK: - Card content with crossfade

    private var cardContent: some View {
        GeometryReader { geo in
            ZStack {
                // Background layer — clipped to screen bounds to prevent layout overflow
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

                ReadabilityOverlay()

                // Text + action bar
                if let current = currentAffirmation {
                    VStack {
                        Spacer()

                        Text(current.text)
                            .font(affirmationFont(for: current))
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

                // Tap zones: left half = previous, right half = next
                // Stops above the action bar area so buttons remain tappable
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

                    // Reserve space for action bar + tab bar so taps pass through
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

    // MARK: - Crossfade transitions

    private func crossfadeToNext() {
        guard viewModel.currentIndex < viewModel.cards.count - 1 else { return }
        performCrossfade {
            viewModel.swipeToNext()
        }
    }

    private func crossfadeToPrevious() {
        guard viewModel.currentIndex > 0 else { return }
        performCrossfade {
            viewModel.swipeToPrevious()
        }
    }

    private func performCrossfade(indexChange: @escaping () -> Void) {
        isTransitioning = true

        // Phase 1: Fade out
        withAnimation(.easeInOut(duration: 0.5)) {
            textOpacity = 0
            backgroundOpacity = 0.3
        }

        // Phase 2: Switch card, fade in
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

    // MARK: - Typography

    /// Font selection — respects user-chosen font for custom affirmations.
    private func affirmationFont(for affirmation: Affirmation) -> Font {
        if let styleName = affirmation.fontStyle,
           let style = AffirmationFontStyle(rawValue: styleName) {
            return style.cardFont(textLength: affirmation.text.count)
        }

        let length = affirmation.text.count
        let design = fontDesign(for: affirmation)
        let weight = fontWeight(for: affirmation)

        if length < 40 {
            return .system(size: 34, weight: weight, design: design)
        } else if length < 80 {
            return .system(size: 28, weight: weight, design: design)
        } else if length < 140 {
            return .system(size: 24, weight: weight, design: design)
        } else {
            return .system(size: 21, weight: weight, design: design)
        }
    }

    /// Predominantly serif (New York) — the standard for wellness/meditation apps.
    /// Occasional rounded for short, punchy quotes.
    private func fontDesign(for affirmation: Affirmation) -> Font.Design {
        let hash = abs(affirmation.id.hashValue)
        // 70% serif, 20% rounded, 10% default
        let roll = hash % 10
        if roll < 7 { return .serif }
        if roll < 9 { return .rounded }
        return .default
    }

    /// Weights that read well on busy/gradient backgrounds.
    /// No thin or light — they disappear.
    private func fontWeight(for affirmation: Affirmation) -> Font.Weight {
        let hash = abs(affirmation.id.hashValue >> 4)
        let weights: [Font.Weight] = [.medium, .regular, .medium, .semibold, .regular]
        return weights[hash % weights.count]
    }

    /// Subtle letter spacing for elegance.
    private func letterSpacing(for affirmation: Affirmation) -> CGFloat {
        let design = fontDesign(for: affirmation)
        switch design {
        case .serif: return 0.3
        case .rounded: return 0.5
        default: return 0.2
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
                icon: "square.and.arrow.up",
                label: "feed.share".localized
            ) {
                if let image = viewModel.shareImage(isPremium: isPremium) {
                    presentShareSheet(image: image)
                }
            }
        }
    }

    private func feedButton(icon: String, label: String, isActive: Bool = false, action: @escaping () -> Void) -> some View {
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
            "feed.empty.title".localized,
            systemImage: "slider.horizontal.3",
            description: Text("feed.empty.description".localized)
        )
    }

    private func gradientColors(for affirmation: Affirmation) -> [Color] {
        let index = abs(affirmation.id.hashValue) % LumenTheme.Colors.gradients.count
        return LumenTheme.Colors.gradients[index]
    }

    private func gradientHexColors(for affirmation: Affirmation) -> [String] {
        let index = abs(affirmation.id.hashValue) % LumenTheme.Colors.gradients.count
        let colorSets: [[String]] = [
            ["#1B998B", "#3B5998"],
            ["#E8A87C", "#C38D9E"],
            ["#7FBBCA", "#A688B5"],
            ["#7EC8A0", "#3B5998"],
            ["#F4D06F", "#E8A87C"],
            ["#C38D9E", "#7FBBCA"],
        ]
        return colorSets[index]
    }

    private func updateWidget() {
        if let daily = viewModel.dailyAffirmation {
            WidgetService.shared.updateWidget(
                affirmationText: daily.text,
                gradientColors: gradientHexColors(for: daily)
            )
        }
    }

    private func presentShareSheet(image: UIImage) {
        let activityVC = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootVC = window.rootViewController else { return }
        rootVC.present(activityVC, animated: true)
    }
}
