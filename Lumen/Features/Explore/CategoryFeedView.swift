import SwiftUI
import SwiftData

struct CategoryFeedView: View {
    let categoryId: String
    let preferences: UserPreferences
    let isPremium: Bool

    @State private var viewModel = CategoryFeedViewModel()
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.cards.isEmpty {
                emptyState
            } else {
                cardStack
            }
        }
        .navigationTitle(viewModel.categoryName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.loadCategory(
                categoryId: categoryId,
                preferences: preferences,
                isPremium: isPremium,
                modelContext: modelContext
            )
        }
    }

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
                                shareImage(image)
                            }
                        }
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .ignoresSafeArea()
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No affirmations in this category",
            systemImage: "text.page",
            description: Text("Try adjusting your content filters in Settings.")
        )
    }

    private func gradientColors(for affirmation: Affirmation) -> [Color] {
        let index = abs(affirmation.id.hashValue) % LumenTheme.Colors.gradients.count
        return LumenTheme.Colors.gradients[index]
    }

    private func shareImage(_ image: UIImage) {
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootVC = window.rootViewController else { return }
        rootVC.present(activityVC, animated: true)
    }
}
