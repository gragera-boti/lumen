import SwiftData
import SwiftUI
import UIKit

struct AffirmationDetailView: View {
    let affirmationId: String
    @Environment(\.modelContext) private var modelContext
    @State private var affirmation: Affirmation?
    @State private var isFavorited = false
    @State private var editingAffirmation: Affirmation?
    @State private var customization: CardCustomization?
    @State private var backgroundImage: UIImage?

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
        let displayText =
            if let text = customization?.customText, !text.isEmpty {
                text
            } else {
                affirmation.text
            }

        ZStack {
            if let cachedPath = customization?.cachedImagePath,
                let image = UIImage(
                    contentsOfFile: CardEditorViewModel.customizationImagesDir.appendingPathComponent(cachedPath).path
                )
            {
                GeometryReader { geo in
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                }
                .ignoresSafeArea()
            } else if let paletteRaw = customization?.colorPalette,
                let palette = ColorPalette(rawValue: paletteRaw)
            {
                LinearGradient(
                    colors: palette.cgColors.map { Color(cgColor: $0) },
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            } else if let bgImage = backgroundImage {
                GeometryReader { geo in
                    Image(uiImage: bgImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                }
                .ignoresSafeArea()
            } else {
                LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
            }

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

                if !(affirmation.categories?.isEmpty ?? true) {
                    HStack(spacing: LumenTheme.Spacing.xs) {
                        ForEach(affirmation.categories ?? [], id: \.id) { category in
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

    private func detailButton(
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

    private func shareText(_ text: String) {
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let window = windowScene.windows.first,
            let rootVC = window.rootViewController
        else { return }
        rootVC.present(activityVC, animated: true)
    }

    private func detailFont(for affirmation: Affirmation) -> Font {
        if let overrideName = customization?.fontStyleOverride,
            let style = AffirmationFontStyle.from(overrideName)
        {
            return style.cardFont(textLength: affirmation.text.count)
        }
        return .custom("PlayfairDisplayRoman-Bold", size: 34)
    }

    private func loadAffirmation() {
        let id = affirmationId
        let descriptor = FetchDescriptor<Affirmation>(
            predicate: #Predicate { $0.id == id }
        )
        affirmation = try? modelContext.fetch(descriptor).first
        isFavorited = affirmation?.isFavorited ?? false
        reloadCustomization()

        if let aff = affirmation {
            Task {
                await loadBackground(for: aff)
            }
        }
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

    // MARK: - Background Loading

    private func loadBackground(for affirmation: Affirmation) async {
        do {
            let descriptor = FetchDescriptor<AppTheme>(
                predicate: #Predicate<AppTheme> { $0.isActive == true || $0.isActive == nil }
            )
            let themes = try modelContext.fetch(descriptor)
            let activeThemeIds = themes.map(\.id)
            guard !activeThemeIds.isEmpty else { return }

            let themeId = activeThemeIds[abs(affirmation.id.hashValue) % activeThemeIds.count]

            if let image = await Task.detached(operation: { Self.loadThemeImage(themeId: themeId) }).value {
                self.backgroundImage = image
            }
        } catch {
            print("Failed to load active themes for detail view: \(error)")
        }
    }

    private nonisolated static func loadThemeImage(themeId: String) -> UIImage? {
        let searchDirs: [URL] = [
            FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.gragera.lumen")?
                .appendingPathComponent("themes/generated"),
            FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.gragera.lumen")?
                .appendingPathComponent("themes/ai"),
            FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
                .appendingPathComponent("themes/generated"),
            FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
                .appendingPathComponent("themes/ai"),
        ].compactMap { $0 }

        let extensions = ["png", "jpg"]

        for dir in searchDirs {
            for ext in extensions {
                let imagePath = dir.appendingPathComponent("\(themeId).\(ext)")
                if let data = try? Data(contentsOf: imagePath), let image = UIImage(data: data) {
                    let screenScale = 2.0
                    let targetWidth = 430.0 * screenScale
                    let scale = targetWidth / image.size.width
                    let targetSize = CGSize(width: targetWidth, height: image.size.height * scale)
                    let renderer = UIGraphicsImageRenderer(size: targetSize)
                    return renderer.image { _ in
                        image.draw(in: CGRect(origin: .zero, size: targetSize))
                    }
                }
            }
        }

        if let bundled = UIImage(named: themeId) {
            return bundled
        }
        return nil
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AffirmationDetailView(affirmationId: "preview_1")
    }
    .modelContainer(for: [Affirmation.self, Favorite.self, CardCustomization.self], inMemory: true)
}
