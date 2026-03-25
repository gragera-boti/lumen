import SwiftUI

// MARK: - PalettePickerView

/// Horizontal scroll of color swatches for ``ColorPalette`` selection.
struct PalettePickerView: View {
    @Binding var selection: ColorPalette

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: LumenTheme.Spacing.sm) {
                ForEach(ColorPalette.allCases) { palette in
                    PaletteSwatch(
                        palette: palette,
                        isSelected: selection == palette
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selection = palette
                        }
                    }
                }
            }
            .padding(.horizontal, LumenTheme.Spacing.md)
        }
    }
}

// MARK: - PaletteSwatch

private struct PaletteSwatch: View {
    let palette: ColorPalette
    let isSelected: Bool
    let action: () -> Void

    private var gradientColors: [Color] {
        palette.cgColors.map { Color(cgColor: $0) }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: LumenTheme.Spacing.xs) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                isSelected ? Color.white : .clear,
                                lineWidth: 2.5
                            )
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(
                                isSelected ? Color.black.opacity(0.2) : .clear,
                                lineWidth: 0.5
                            )
                            .padding(2)
                    )
                    .shadow(
                        color: isSelected ? .white.opacity(0.3) : .clear,
                        radius: 4
                    )

                Text(palette.displayName)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .lineLimit(1)
            }
            .frame(width: 56)
        }
        .accessibilityLabel("\(palette.displayName) color palette")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        PalettePickerView(selection: .constant(.nightFade))
    }
}
