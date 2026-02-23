import SwiftUI

struct CategoryCardView: View {
    let category: Category
    let action: () -> Void

    private var categoryColors: [Color] {
        let index = abs(category.id.utf8.reduce(0) { $0 &+ Int($1) }) % LumenTheme.Colors.gradients.count
        return LumenTheme.Colors.gradients[index]
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: LumenTheme.Spacing.sm) {
                Image(systemName: category.icon)
                    .font(.system(size: 28))
                    .foregroundStyle(
                        LinearGradient(
                            colors: categoryColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: categoryColors.first?.opacity(0.5) ?? .clear, radius: 8)

                Text(category.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                Text(category.categoryDescription)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                if category.isPremium {
                    Label("Premium", systemImage: "star.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
            .padding(LumenTheme.Spacing.md)
            .frame(maxWidth: .infinity, minHeight: 140)
            .background(
                RoundedRectangle(cornerRadius: LumenTheme.Radii.lg)
                    .fill(LumenTheme.Colors.glassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: LumenTheme.Radii.lg)
                            .fill(
                                LinearGradient(
                                    colors: categoryColors.map { $0.opacity(0.08) },
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: LumenTheme.Radii.lg)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        categoryColors.first?.opacity(0.3) ?? .clear,
                                        LumenTheme.Colors.glassBorder,
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    )
            )
        }
        .accessibilityLabel("\(category.name): \(category.categoryDescription)")
        .accessibilityHint(category.isPremium ? "Premium category" : "Tap to explore")
        .accessibilityIdentifier("category_card_\(category.id)")
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        LinearGradient(
            colors: [LumenTheme.Colors.ambientDark, LumenTheme.Colors.ambientMid],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        CategoryCardView(
            category: Category(
                id: "self-love",
                name: "Self Love",
                categoryDescription: "Embrace who you are",
                icon: "heart.fill"
            ),
            action: {}
        )
        .frame(width: 180)
        .padding()
    }
}
