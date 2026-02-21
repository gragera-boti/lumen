import SwiftUI

struct ShareService: ShareServiceProtocol {
    static let shared = ShareService()

    @MainActor func renderShareImage(
        text: String,
        gradientColors: [Color],
        size: CGSize,
        showWatermark: Bool
    ) -> UIImage? {
        let renderer = ImageRenderer(
            content: ShareImageView(
                text: text,
                gradientColors: gradientColors,
                size: size,
                showWatermark: showWatermark
            )
        )
        renderer.scale = 3.0
        return renderer.uiImage
    }
}

private struct ShareImageView: View {
    let text: String
    let gradientColors: [Color]
    let size: CGSize
    let showWatermark: Bool

    var body: some View {
        ZStack {
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Readability overlay
            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0), location: 0),
                    .init(color: .black.opacity(0.3), location: 0.5),
                    .init(color: .black.opacity(0.2), location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: 24) {
                Spacer()

                Text(text)
                    .font(.system(.title, design: .serif, weight: .medium))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .shadow(color: .black.opacity(0.3), radius: 4, y: 2)

                Spacer()

                if showWatermark {
                    Text("Lumen")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.bottom, 16)
                }
            }
        }
        .frame(width: size.width, height: size.height)
    }
}
