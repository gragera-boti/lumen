import SwiftUI

struct CategoryCardView: View {
    let category: Category
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: LumenTheme.Spacing.sm) {
                Image(systemName: category.icon)
                    .font(.title)
                    .foregroundStyle(gradientForCategory)

                Text(category.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                Text(category.categoryDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
                    .fill(.ultraThinMaterial)
            )
        }
        .accessibilityLabel("\(category.name): \(category.categoryDescription)")
    }

    private var gradientForCategory: some ShapeStyle {
        let index = abs(category.id.hashValue) % LumenTheme.Colors.gradients.count
        let colors = LumenTheme.Colors.gradients[index]
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
