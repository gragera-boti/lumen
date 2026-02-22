import SwiftUI
import SwiftData

struct FavoritesView: View {
    @State private var viewModel = FavoritesViewModel()
    @State private var showSlideshow = false
    @State private var editingAffirmation: Affirmation?
    @State private var editingCardAffirmation: Affirmation?
    @State private var showDeleteConfirm = false
    @State private var affirmationToDelete: Affirmation?
    @Environment(\.modelContext) private var modelContext
    @Environment(AppRouter.self) private var router

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .tint(.white)
            } else if viewModel.userCreated.isEmpty && viewModel.curatedFavorites.isEmpty {
                emptyState
            } else {
                favoritesList
            }
        }
        .ambientBackground()
        .navigationTitle("favorites.title".localized)
        .toolbar {
            if !viewModel.allFavorites.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSlideshow = true
                    } label: {
                        Image(systemName: "play.rectangle.fill")
                            .foregroundStyle(.white)
                    }
                    .accessibilityLabel("Slideshow")
                    .accessibilityHint("Play all favorites as a slideshow")
                    .accessibilityIdentifier("favorites_slideshow_button")
                }
            }
        }
        .fullScreenCover(isPresented: $showSlideshow) {
            SlideshowView(
                affirmations: viewModel.allFavorites,
                customizations: viewModel.customizations
            )
        }
        .sheet(item: $editingAffirmation) { affirmation in
            EditAffirmationSheet(affirmation: affirmation)
        }
        .sheet(item: $editingCardAffirmation) { affirmation in
            CardEditorView(
                affirmation: affirmation,
                existingCustomization: viewModel.customizations[affirmation.id]
            )
        }
        .onChange(of: editingCardAffirmation) { _, newValue in
            if newValue == nil {
                viewModel.reloadCustomizations(modelContext: modelContext)
            }
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

    // MARK: - Favorites List

    private var favoritesList: some View {
        ScrollView {
            VStack(spacing: LumenTheme.Spacing.lg) {
                // My Affirmations section
                if !viewModel.userCreated.isEmpty {
                    favoritesSection(
                        title: "My Affirmations",
                        icon: "person.fill",
                        affirmations: viewModel.userCreated,
                        isUserCreated: true
                    )
                }

                // Curated favorites section
                if !viewModel.curatedFavorites.isEmpty {
                    favoritesSection(
                        title: viewModel.userCreated.isEmpty ? nil : "Favorites",
                        icon: "heart.fill",
                        affirmations: viewModel.curatedFavorites,
                        isUserCreated: false
                    )
                }
            }
            .padding(.horizontal, LumenTheme.Spacing.md)
            .padding(.top, LumenTheme.Spacing.sm)
            .padding(.bottom, LumenTheme.Spacing.xxl)
        }
    }

    @ViewBuilder
    private func favoritesSection(title: String?, icon: String, affirmations: [Affirmation], isUserCreated: Bool) -> some View {
        VStack(alignment: .leading, spacing: LumenTheme.Spacing.sm) {
            if let title {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.caption2)
                    Text(title)
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(.white.opacity(0.5))
                .textCase(.uppercase)
                .padding(.leading, LumenTheme.Spacing.sm)
            }

            VStack(spacing: LumenTheme.Spacing.sm) {
                ForEach(affirmations, id: \.id) { affirmation in
                    FavoriteRow(
                        affirmation: affirmation,
                        isUserCreated: isUserCreated,
                        displayText: viewModel.customizations[affirmation.id]?.customText
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        router.navigate(to: .affirmationDetail(affirmationId: affirmation.id), in: .favorites)
                    }
                    .contextMenu {
                        if isUserCreated {
                            Button {
                                editingAffirmation = affirmation
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                        }

                        Button {
                            editingCardAffirmation = affirmation
                        } label: {
                            Label("Customize Card", systemImage: "paintbrush")
                        }

                        Button(role: .destructive) {
                            if isUserCreated {
                                affirmationToDelete = affirmation
                                showDeleteConfirm = true
                            } else {
                                viewModel.removeFavorite(affirmation, modelContext: modelContext)
                            }
                        } label: {
                            Label(isUserCreated ? "Delete" : "Remove", systemImage: isUserCreated ? "trash" : "heart.slash")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView {
            Label("favorites.empty.title".localized, systemImage: "heart")
                .foregroundStyle(.white.opacity(0.6))
        } description: {
            Text("favorites.empty.description".localized)
                .foregroundStyle(.white.opacity(0.4))
        }
    }
}

// MARK: - Favorite Row

struct FavoriteRow: View {
    let affirmation: Affirmation
    var isUserCreated: Bool = false
    var displayText: String?

    private var gradientColors: [Color] {
        let index = abs(affirmation.id.hashValue) % LumenTheme.Colors.gradients.count
        return LumenTheme.Colors.gradients[index]
    }

    var body: some View {
        HStack(spacing: LumenTheme.Spacing.md) {
            // Gradient accent strip
            RoundedRectangle(cornerRadius: LumenTheme.Radii.sm)
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: isUserCreated ? "pencil.line" : "heart.fill")
                        .foregroundStyle(.white)
                        .font(.caption)
                }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(displayText ?? affirmation.text)
                        .font(.subheadline)
                        .foregroundStyle(.white)
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
                        .foregroundStyle(.white.opacity(0.45))
                } else if isUserCreated, let fontStyle = affirmation.fontStyle,
                          let style = AffirmationFontStyle.from( fontStyle) {
                    Text(style.displayName + " style")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.45))
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.25))
        }
        .padding(LumenTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: LumenTheme.Radii.md)
                .fill(LumenTheme.Colors.glassBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: LumenTheme.Radii.md)
                        .strokeBorder(LumenTheme.Colors.glassBorder, lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        FavoritesView()
    }
    .environment(AppRouter())
    .modelContainer(for: [Affirmation.self, Favorite.self, CardCustomization.self, UserPreferences.self], inMemory: true)
}
