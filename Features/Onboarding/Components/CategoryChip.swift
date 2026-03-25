import SwiftUI

struct CategoryChip: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void

    private var categoryColors: [Color] {
        let index = abs(category.id.utf8.reduce(0) { $0 &+ Int($1) }) % LumenTheme.Colors.gradients.count
        return LumenTheme.Colors.gradients[index]
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: LumenTheme.Spacing.md) {
                Image(systemName: category.icon)
                    .font(.system(size: 32))
                    .frame(width: 40)
                    .foregroundStyle(
                        LinearGradient(
                            colors: categoryColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: categoryColors.first?.opacity(0.5) ?? .clear, radius: 8)

                VStack(alignment: .leading, spacing: 4) {
                    Text(category.name)
                        .font(.title3.weight(.semibold))
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: categoryColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            .foregroundStyle(.white)
            .padding(LumenTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: LumenTheme.Radii.lg)
                    .fill(isSelected ? LumenTheme.Colors.glassBackground : .white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: LumenTheme.Radii.lg)
                            .fill(
                                isSelected ? LinearGradient(
                                    colors: categoryColors.map { $0.opacity(0.15) },
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) : LinearGradient(colors: [.clear, .clear], startPoint: .top, endPoint: .bottom)
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: LumenTheme.Radii.lg)
                            .strokeBorder(
                                isSelected ? LinearGradient(
                                    colors: [
                                        categoryColors.first?.opacity(0.5) ?? .clear,
                                        LumenTheme.Colors.glassBorder,
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) : LinearGradient(colors: [.white.opacity(0.1), .white.opacity(0.1)], startPoint: .top, endPoint: .bottom),
                                lineWidth: isSelected ? 1.5 : 1.0
                            )
                    )
            )
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
