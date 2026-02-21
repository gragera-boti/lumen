import SwiftUI
import SwiftData

struct FavoritesView: View {
    @State private var viewModel = FavoritesViewModel()
    @State private var showSlideshow = false
    @State private var editingAffirmation: Affirmation?
    @State private var showDeleteConfirm = false
    @State private var affirmationToDelete: Affirmation?
    @Environment(\.modelContext) private var modelContext
    @Environment(AppRouter.self) private var router

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.userCreated.isEmpty && viewModel.curatedFavorites.isEmpty {
                emptyState
            } else {
                favoritesList
            }
        }
        .navigationTitle("favorites.title".localized)
        .toolbar {
            if !viewModel.allFavorites.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSlideshow = true
                    } label: {
                        Image(systemName: "play.rectangle.fill")
                    }
                    .accessibilityLabel("Slideshow")
                }
            }
        }
        .fullScreenCover(isPresented: $showSlideshow) {
            SlideshowView(affirmations: viewModel.allFavorites)
        }
        .sheet(item: $editingAffirmation) { affirmation in
            EditAffirmationSheet(affirmation: affirmation)
        }
        .alert("Delete Affirmation", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                if let aff = affirmationToDelete {
                    viewModel.deleteUserAffirmation(aff, modelContext: modelContext)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete your custom affirmation.")
        }
        .task {
            viewModel.loadFavorites(modelContext: modelContext)
        }
    }

    private var favoritesList: some View {
        List {
            // My Affirmations section
            if !viewModel.userCreated.isEmpty {
                Section {
                    ForEach(viewModel.userCreated, id: \.id) { affirmation in
                        FavoriteRow(affirmation: affirmation, isUserCreated: true)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                router.navigate(to: .affirmationDetail(affirmationId: affirmation.id), in: .favorites)
                            }
                            .contextMenu {
                                Button {
                                    editingAffirmation = affirmation
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }

                                Button(role: .destructive) {
                                    affirmationToDelete = affirmation
                                    showDeleteConfirm = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    affirmationToDelete = affirmation
                                    showDeleteConfirm = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }

                                Button {
                                    editingAffirmation = affirmation
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                    }
                } header: {
                    HStack(spacing: 6) {
                        Image(systemName: "person.fill")
                            .font(.caption2)
                        Text("My Affirmations")
                    }
                }
            }

            // Curated favorites section
            if !viewModel.curatedFavorites.isEmpty {
                Section {
                    ForEach(viewModel.curatedFavorites, id: \.id) { affirmation in
                        FavoriteRow(affirmation: affirmation, isUserCreated: false)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                router.navigate(to: .affirmationDetail(affirmationId: affirmation.id), in: .favorites)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    viewModel.removeFavorite(affirmation, modelContext: modelContext)
                                } label: {
                                    Label("favorites.remove".localized, systemImage: "heart.slash")
                                }
                            }
                    }
                } header: {
                    if !viewModel.userCreated.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "heart.fill")
                                .font(.caption2)
                            Text("Favorites")
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "favorites.empty.title".localized,
            systemImage: "heart",
            description: Text("favorites.empty.description".localized)
        )
    }
}

// MARK: - Favorite Row

struct FavoriteRow: View {
    let affirmation: Affirmation
    var isUserCreated: Bool = false

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
                    Image(systemName: isUserCreated ? "pencil.line" : "heart.fill")
                        .foregroundStyle(.white)
                        .font(.caption)
                }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(affirmation.text)
                        .font(.subheadline)
                        .lineLimit(2)

                    if isUserCreated {
                        Text("You")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(LumenTheme.Colors.primary))
                    }
                }

                if !affirmation.categories.isEmpty {
                    Text(affirmation.categories.map(\.name).joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if isUserCreated, let fontStyle = affirmation.fontStyle,
                          let style = AffirmationFontStyle(rawValue: fontStyle) {
                    Text(style.displayName + " style")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, LumenTheme.Spacing.xs)
    }

    private var gradientColors: [Color] {
        let index = abs(affirmation.id.hashValue) % LumenTheme.Colors.gradients.count
        return LumenTheme.Colors.gradients[index]
    }
}
