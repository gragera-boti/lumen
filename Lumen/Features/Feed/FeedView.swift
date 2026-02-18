import SwiftUI
import SwiftData

struct FeedView: View {
    @State private var viewModel = FeedViewModel()
    @Environment(\.modelContext) private var modelContext
    @Environment(AppRouter.self) private var router
    @State private var showCustomAffirmation = false

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
                cardStack
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showCustomAffirmation = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(.primary)
                }
                .accessibilityLabel("Create custom affirmation")
            }
        }
        .sheet(isPresented: $showCustomAffirmation) {
            CustomAffirmationSheet()
        }
        .task {
            viewModel.loadFeed(
                preferences: preferences,
                isPremium: isPremium,
                modelContext: modelContext
            )
            updateWidget()
        }
    }

    // MARK: - Card Stack

    private var cardStack: some View {
        GeometryReader { geometry in
            TabView(selection: $viewModel.currentIndex) {
                ForEach(Array(viewModel.cards.enumerated()), id: \.element.id) { index, affirmation in
                    AffirmationCardView(
                        affirmation: affirmation,
                        gradientColors: gradientColors(for: affirmation),
                        isFavorited: affirmation.isFavorited,
                        isPlayingTTS: viewModel.isPlayingTTS && viewModel.currentIndex == index,
                        onFavorite: { viewModel.toggleFavorite(modelContext: modelContext) },
                        onListen: { viewModel.toggleTTS(voice: preferences.voice) },
                        onShare: {
                            if let image = viewModel.shareImage(isPremium: isPremium) {
                                presentShareSheet(image: image)
                            }
                        }
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(width: geometry.size.width, height: geometry.size.height)
            .onChange(of: viewModel.currentIndex) { _, _ in
                viewModel.recordSeen(modelContext: modelContext)
                viewModel.loadMoreIfNeeded(
                    preferences: preferences,
                    isPremium: isPremium,
                    modelContext: modelContext
                )
            }
        }
        .ignoresSafeArea()
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No affirmations match your filters",
            systemImage: "slider.horizontal.3",
            description: Text("Try adding more categories or turning off Gentle mode.")
        )
    }

    // MARK: - Helpers

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
