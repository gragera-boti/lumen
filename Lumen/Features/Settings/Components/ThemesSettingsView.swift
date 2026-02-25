import SwiftData
import SwiftUI

struct ThemesSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppRouter.self) private var router
    @Query(sort: \AppTheme.createdAt, order: .reverse) private var themes: [AppTheme]
    
    @State private var newAffirmationToEdit: Affirmation?

    private var activeCount: Int {
        themes.filter(\.isInRotation).count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LumenTheme.Spacing.lg) {
                // My Backgrounds summary
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("My Backgrounds")
                                .font(.headline)
                            Text("\(activeCount) active in rotation")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button {
                            router.navigate(to: .themeGallery, in: .settings)
                        } label: {
                            HStack(spacing: 4) {
                                Text("Manage")
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                            }
                            .font(.subheadline)
                        }
                    }
                    .padding(LumenTheme.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: LumenTheme.Radii.card)
                            .fill(Color(.systemGray6))
                    )
                }
                .padding(.horizontal, LumenTheme.Spacing.md)

                // Recent thumbnails preview (up to 6)
                if !themes.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: LumenTheme.Spacing.sm) {
                            ForEach(themes.prefix(6)) { theme in
                                ThemeThumbnail(theme: theme)
                            }
                        }
                        .padding(.horizontal, LumenTheme.Spacing.md)
                    }
                }

                Divider()
                    .padding(.horizontal, LumenTheme.Spacing.md)

                PrimaryButton(title: "Generate new background") {
                    newAffirmationToEdit = Affirmation(
                        id: "user_\(UUID().uuidString)",
                        text: "",
                        tone: .gentle,
                        intensity: .low,
                        source: .user,
                        tags: ["custom"]
                    )
                }
                .padding(.horizontal, LumenTheme.Spacing.md)

                Text("Saved backgrounds rotate randomly behind your affirmations.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, LumenTheme.Spacing.md)
            }
            .padding(.vertical, LumenTheme.Spacing.md)
        }
        .ambientBackground()
        .navigationTitle("settings.themes".localized)
        .sheet(item: $newAffirmationToEdit) { affirmation in
            CardEditorView(
                affirmation: affirmation,
                existingCustomization: nil,
                isCreatingNew: true
            )
        }
    }
}

private struct ThemeThumbnail: View {
    let theme: AppTheme

    var body: some View {
        ZStack {
            thumbnailImage
        }
        .frame(width: 80, height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(theme.isInRotation ? Color.green.opacity(0.8) : Color.clear, lineWidth: 2)
        )
        .opacity(theme.isInRotation ? 1.0 : 0.5)
    }

    @ViewBuilder
    private var thumbnailImage: some View {
        if let image = loadImage() {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            // Fallback: try parsing gradient data
            let colors = parseGradient()
            LinearGradient(
                colors: colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private func loadImage() -> UIImage? {
        let dirs: [URL] = [
            FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.gragera.lumen")?
                .appendingPathComponent("themes/generated"),
            FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.gragera.lumen")?
                .appendingPathComponent("themes/ai"),
            FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
                .appendingPathComponent("themes/generated"),
            FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
                .appendingPathComponent("themes/ai"),
        ].compactMap { $0 }

        for dir in dirs {
            for filename in ["\(theme.id)_thumb.jpg", "\(theme.id).jpg", "\(theme.id).png"] {
                let path = dir.appendingPathComponent(filename)
                if let data = try? Data(contentsOf: path), let img = UIImage(data: data) {
                    return img
                }
            }
        }
        return nil
    }

    private func parseGradient() -> [Color] {
        guard let data = theme.dataJSON.data(using: .utf8),
            let gradient = try? JSONDecoder().decode(GradientData.self, from: data)
        else {
            return [.gray]
        }
        return gradient.swiftUIColors
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ThemesSettingsView()
    }
    .environment(AppRouter())
    .modelContainer(for: AppTheme.self, inMemory: true)
}
