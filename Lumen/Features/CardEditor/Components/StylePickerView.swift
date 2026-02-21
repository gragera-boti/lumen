import SwiftUI

// MARK: - StylePickerView

/// Horizontal scroll picker displaying ``GeneratorStyle`` options as small thumbnail cards.
struct StylePickerView: View {
    @Binding var selection: GeneratorStyle
    let palette: ColorPalette

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: LumenTheme.Spacing.sm) {
                ForEach(GeneratorStyle.allCases) { style in
                    StyleThumbnail(
                        style: style,
                        palette: palette,
                        isSelected: selection == style
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selection = style
                        }
                    }
                }
            }
            .padding(.horizontal, LumenTheme.Spacing.md)
        }
    }
}

// MARK: - StyleThumbnail

private struct StyleThumbnail: View {
    let style: GeneratorStyle
    let palette: ColorPalette
    let isSelected: Bool
    let action: () -> Void

    private var gradientColors: [Color] {
        palette.cgColors.map { Color(cgColor: $0) }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: LumenTheme.Spacing.xs) {
                RoundedRectangle(cornerRadius: LumenTheme.Radii.sm)
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .overlay(
                        RoundedRectangle(cornerRadius: LumenTheme.Radii.sm)
                            .strokeBorder(
                                isSelected ? Color.white : .clear,
                                lineWidth: 2
                            )
                    )
                    .shadow(
                        color: isSelected ? .white.opacity(0.3) : .clear,
                        radius: 4
                    )

                Text(style.displayName)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .lineLimit(1)
            }
            .frame(width: 72)
        }
        .accessibilityLabel("\(style.displayName) background style")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        StylePickerView(
            selection: .constant(.aurora),
            palette: .nightFade
        )
    }
}
