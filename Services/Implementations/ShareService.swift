import SwiftUI

struct ShareService: ShareServiceProtocol {
    static let shared = ShareService()

    @MainActor func renderShareImage(
        text: String,
        font: Font,
        letterSpacing: CGFloat,
        gradientColors: [Color],
        backgroundImage: UIImage?,
        size: CGSize,
        showWatermark: Bool
    ) -> UIImage? {
        let renderer = ImageRenderer(
            content: ShareImageView(
                text: text,
                font: font,
                letterSpacing: letterSpacing,
                gradientColors: gradientColors,
                backgroundImage: backgroundImage,
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
    let font: Font
    let letterSpacing: CGFloat
    let gradientColors: [Color]
    let backgroundImage: UIImage?
    let size: CGSize
    let showWatermark: Bool

    var body: some View {
        ZStack {
            if let bgImage = backgroundImage {
                Image(uiImage: bgImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.width, height: size.height)
                    .clipped()
            } else {
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }

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
                    .font(font)
                    .tracking(letterSpacing)
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
