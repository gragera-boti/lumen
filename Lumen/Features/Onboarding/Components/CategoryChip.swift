import SwiftUI

struct CategoryChip: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: LumenTheme.Spacing.sm) {
                Image(systemName: category.icon)
                    .font(.body)

                Text(category.name)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? .white : .white.opacity(0.8))
            .padding(.horizontal, LumenTheme.Spacing.md)
            .padding(.vertical, LumenTheme.Spacing.sm + 4)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: LumenTheme.Radii.lg)
                    .fill(isSelected ? .white.opacity(0.3) : .white.opacity(0.1))
                    .strokeBorder(isSelected ? .white : .white.opacity(0.2), lineWidth: 1.5)
            )
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
