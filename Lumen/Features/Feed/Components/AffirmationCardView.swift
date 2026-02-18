import SwiftUI

struct AffirmationCardView: View {
    let affirmation: Affirmation
    let gradientColors: [Color]
    let isFavorited: Bool
    let isPlayingTTS: Bool
    let onFavorite: () -> Void
    let onListen: () -> Void
    let onShare: () -> Void

    @State private var showOverflow = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Readability overlay
            ReadabilityOverlay()

            // Content
            VStack {
                Spacer()

                Text(affirmation.text)
                    .font(LumenTheme.Typography.affirmationLargeFont)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, LumenTheme.Spacing.xl)
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                // Action bar
                actionBar
                    .padding(.bottom, LumenTheme.Spacing.xxl + 20)
            }
        }
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack(spacing: LumenTheme.Spacing.xl) {
            ActionButton(
                icon: isFavorited ? "heart.fill" : "heart",
                label: "Favorite",
                isActive: isFavorited,
                action: onFavorite
            )

            ActionButton(
                icon: isPlayingTTS ? "pause.fill" : "play.fill",
                label: isPlayingTTS ? "Pause" : "Listen",
                isActive: isPlayingTTS,
                action: onListen
            )

            ActionButton(
                icon: "square.and.arrow.up",
                label: "Share",
                action: onShare
            )
        }
    }
}

// MARK: - Action Button

private struct ActionButton: View {
    let icon: String
    let label: String
    var isActive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: LumenTheme.Spacing.xs) {
                Image(systemName: icon)
                    .font(.title2)
                    .symbolEffect(.bounce, value: isActive)

                Text(label)
                    .font(.caption2)
            }
            .foregroundStyle(.white)
            .frame(minWidth: 60, minHeight: 44)
        }
        .accessibilityLabel(label)
    }
}
