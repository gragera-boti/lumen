import SwiftUI
import SwiftData

struct FavoritesView: View {
    @State private var viewModel = FavoritesViewModel()
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.favorites.isEmpty {
                emptyState
            } else {
                favoritesList
            }
        }
        .navigationTitle("Favorites")
        .task {
            viewModel.loadFavorites(modelContext: modelContext)
        }
    }

    private var favoritesList: some View {
        List {
            ForEach(viewModel.favorites, id: \.id) { affirmation in
                FavoriteRow(affirmation: affirmation)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            viewModel.removeFavorite(affirmation, modelContext: modelContext)
                        } label: {
                            Label("Remove", systemImage: "heart.slash")
                        }
                    }
            }
        }
        .listStyle(.plain)
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No favorites yet",
            systemImage: "heart",
            description: Text("Tap the heart on any affirmation to save it here.")
        )
    }
}

// MARK: - Favorite Row

struct FavoriteRow: View {
    let affirmation: Affirmation

    var body: some View {
        HStack(spacing: LumenTheme.Spacing.md) {
            // Mini gradient thumbnail
            RoundedRectangle(cornerRadius: LumenTheme.Radii.sm)
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 48, height: 48)
                .overlay {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.white)
                        .font(.caption)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(affirmation.text)
                    .font(.subheadline)
                    .lineLimit(2)

                Text(affirmation.categories.map(\.name).joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, LumenTheme.Spacing.xs)
    }

    private var gradientColors: [Color] {
        let index = abs(affirmation.id.hashValue) % LumenTheme.Colors.gradients.count
        return LumenTheme.Colors.gradients[index]
    }
}
