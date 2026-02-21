import SwiftUI

struct MoodCheckInView: View {
    let onMoodSelected: (Mood) -> Void
    @State private var selectedMood: Mood?
    @State private var dismissed = false

    var body: some View {
        if !dismissed {
            VStack(spacing: LumenTheme.Spacing.md) {
                Text("mood.prompt".localized)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)

                HStack(spacing: LumenTheme.Spacing.lg) {
                    ForEach(Mood.allCases) { mood in
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                selectedMood = mood
                            }
                            onMoodSelected(mood)

                            // Dismiss after a beat
                            withAnimation(.easeOut(duration: 0.4).delay(0.6)) {
                                dismissed = true
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Text(mood.emoji)
                                    .font(.system(size: selectedMood == mood ? 38 : 30))
                                    .scaleEffect(selectedMood == mood ? 1.15 : 1.0)

                                Text(mood.label)
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                            .frame(minWidth: 50)
                        }
                        .accessibilityLabel(mood.label)
                    }
                }
            }
            .padding(.vertical, LumenTheme.Spacing.lg)
            .padding(.horizontal, LumenTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: LumenTheme.Radii.lg)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
            )
            .padding(.horizontal, LumenTheme.Spacing.md)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}
