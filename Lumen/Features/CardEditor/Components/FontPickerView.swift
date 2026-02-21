import SwiftUI

// MARK: - FontPickerView

/// Grid of ``AffirmationFontStyle`` options, each rendered in its own font.
struct FontPickerView: View {
    @Binding var selection: AffirmationFontStyle?

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: LumenTheme.Spacing.sm) {
            ForEach(AffirmationFontStyle.allCases) { style in
                FontCell(
                    style: style,
                    isSelected: selection == style
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selection = style
                    }
                }
            }
        }
    }
}

// MARK: - FontCell

private struct FontCell: View {
    let style: AffirmationFontStyle
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text("Aa")
                    .font(style.previewFont(size: 22))
                    .frame(height: 36)

                Text(style.displayName)
                    .font(.caption2)
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: LumenTheme.Radii.sm)
                    .fill(isSelected ? LumenTheme.Colors.primary : Color(.systemBackground))
            )
        }
        .accessibilityLabel("\(style.displayName) font style")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        FontPickerView(selection: .constant(.serif))
            .padding()
    }
}
