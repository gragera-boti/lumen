import SwiftUI
import SwiftData

struct SlideshowView: View {
    let affirmations: [Affirmation]

    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex = 0
    @State private var opacity: Double = 1.0
    @State private var timer: Timer?
    @State private var isPaused = false
    @State private var idleHideControls = false

    /// Seconds each card stays on screen.
    private let interval: TimeInterval = 8

    var body: some View {
        ZStack {
            // Background
            currentBackground
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 1.5), value: currentIndex)

            ReadabilityOverlay(opacity: 0.35)
                .ignoresSafeArea()

            // Affirmation text
            if !affirmations.isEmpty {
                Text(affirmations[currentIndex].text)
                    .font(.system(.title, design: .serif, weight: .medium))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, 40)
                    .shadow(color: .black.opacity(0.3), radius: 8, y: 3)
                    .opacity(opacity)
                    .id(currentIndex)
                    .transition(.opacity)
            }

            // Controls overlay
            if !idleHideControls {
                controlsOverlay
                    .transition(.opacity)
            }
        }
        .statusBarHidden(idleHideControls)
        .persistentSystemOverlays(idleHideControls ? .hidden : .automatic)
        .onTapGesture {
            if idleHideControls {
                withAnimation { idleHideControls = false }
                scheduleIdleHide()
            } else {
                togglePause()
            }
        }
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    if value.translation.width < -50 {
                        advance()
                    } else if value.translation.width > 50 {
                        goBack()
                    }
                }
        )
        .onAppear {
            startTimer()
            scheduleIdleHide()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    // MARK: - Background

    @ViewBuilder
    private var currentBackground: some View {
        if affirmations.isEmpty {
            Color.black
        } else {
            let aff = affirmations[currentIndex]
            let index = abs(aff.id.hashValue) % LumenTheme.Colors.gradients.count
            LinearGradient(
                colors: LumenTheme.Colors.gradients[index],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    // MARK: - Controls

    private var controlsOverlay: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .white.opacity(0.3))
                }
                .padding(LumenTheme.Spacing.lg)
            }

            Spacer()

            // Progress dots + pause indicator
            HStack(spacing: LumenTheme.Spacing.md) {
                Button {
                    goBack()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.7))
                }

                // Progress indicator
                HStack(spacing: 4) {
                    ForEach(0..<min(affirmations.count, 20), id: \.self) { i in
                        Capsule()
                            .fill(i == currentIndex ? Color.white : Color.white.opacity(0.3))
                            .frame(width: i == currentIndex ? 16 : 6, height: 4)
                            .animation(.easeInOut(duration: 0.3), value: currentIndex)
                    }
                    if affirmations.count > 20 {
                        Text("…")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }

                Button {
                    advance()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(.bottom, 8)

            // Pause badge
            if isPaused {
                Text("Paused — tap to resume")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.bottom, LumenTheme.Spacing.xl)
            } else {
                Color.clear.frame(height: 30)
            }
        }
    }

    // MARK: - Timer

    private func startTimer() {
        timer?.invalidate()
        isPaused = false
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            Task { @MainActor in
                advance()
            }
        }
    }

    private func togglePause() {
        if isPaused {
            startTimer()
        } else {
            timer?.invalidate()
            isPaused = true
        }
        scheduleIdleHide()
    }

    private func advance() {
        guard !affirmations.isEmpty else { return }
        withAnimation(.easeInOut(duration: 0.6)) {
            opacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            currentIndex = (currentIndex + 1) % affirmations.count
            withAnimation(.easeInOut(duration: 0.6)) {
                opacity = 1
            }
        }
    }

    private func goBack() {
        guard !affirmations.isEmpty else { return }
        withAnimation(.easeInOut(duration: 0.6)) {
            opacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            currentIndex = currentIndex > 0 ? currentIndex - 1 : affirmations.count - 1
            withAnimation(.easeInOut(duration: 0.6)) {
                opacity = 1
            }
        }
    }

    private func scheduleIdleHide() {
        // Hide controls after 5 seconds of inactivity
        Task {
            try? await Task.sleep(for: .seconds(5))
            if !isPaused {
                withAnimation { idleHideControls = true }
            }
        }
    }
}
