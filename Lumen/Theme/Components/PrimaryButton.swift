import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isDisabled: Bool = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, LumenTheme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: LumenTheme.Radii.lg)
                        .fill(isDisabled ? Color.gray : LumenTheme.Colors.primary)
                )
        }
        .disabled(isDisabled)
    }
}

struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(LumenTheme.Colors.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, LumenTheme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: LumenTheme.Radii.lg)
                        .strokeBorder(LumenTheme.Colors.primary, lineWidth: 1.5)
                )
        }
    }
}
