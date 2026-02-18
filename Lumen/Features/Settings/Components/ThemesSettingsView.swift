import SwiftUI
import SwiftData

struct ThemesSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppRouter.self) private var router
    @Query(sort: \AppTheme.name) private var themes: [AppTheme]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LumenTheme.Spacing.lg) {
                Text("Curated Themes")
                    .font(.headline)
                    .padding(.horizontal, LumenTheme.Spacing.md)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ], spacing: LumenTheme.Spacing.md) {
                    ForEach(themes, id: \.id) { theme in
                        ThemeThumbnail(theme: theme)
                    }
                }
                .padding(.horizontal, LumenTheme.Spacing.md)

                Divider()
                    .padding(.horizontal, LumenTheme.Spacing.md)

                PrimaryButton(title: "Generate new background") {
                    router.navigate(to: .themeGenerator, in: .settings)
                }
                .padding(.horizontal, LumenTheme.Spacing.md)
            }
            .padding(.vertical, LumenTheme.Spacing.md)
        }
        .navigationTitle("Themes & Backgrounds")
    }
}

private struct ThemeThumbnail: View {
    let theme: AppTheme

    var body: some View {
        let colors = parseGradient()
        RoundedRectangle(cornerRadius: LumenTheme.Radii.md)
            .fill(LinearGradient(
                colors: colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .frame(height: 80)
            .overlay(alignment: .bottom) {
                Text(theme.name)
                    .font(.caption2)
                    .foregroundStyle(.white)
                    .padding(4)
            }
    }

    private func parseGradient() -> [Color] {
        guard let data = theme.dataJSON.data(using: .utf8),
              let gradient = try? JSONDecoder().decode(GradientData.self, from: data) else {
            return [.gray]
        }
        return gradient.swiftUIColors
    }
}
