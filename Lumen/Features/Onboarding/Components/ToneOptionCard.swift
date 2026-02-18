import SwiftUI

struct ToneOptionCard: View {
    let tone: Tone
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: LumenTheme.Spacing.md) {
                Image(systemName: tone.iconName)
                    .font(.title2)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(tone.displayName)
                        .font(.headline)

                    Text(tone.description)
                        .font(.caption)
                        .opacity(0.7)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                }
            }
            .foregroundStyle(.white)
            .padding(LumenTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: LumenTheme.Radii.md)
                    .fill(isSelected ? .white.opacity(0.25) : .white.opacity(0.1))
                    .strokeBorder(isSelected ? .white : .clear, lineWidth: 1.5)
            )
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
