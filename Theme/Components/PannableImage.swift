import SwiftUI

/// A view that renders a UIImage scaled to fill its bounded frame, precisely
/// shifted according to a defined `UnitPoint` alignment where `0` means fully flush left/top,
/// `0.5` is centered, and `1.0` is exactly flush right/bottom.
struct PannableImage: View {
    let uiImage: UIImage
    let alignment: UnitPoint

    var body: some View {
        GeometryReader { geo in
            let viewSize = geo.size
            let imageSize = uiImage.size

            if imageSize.width > 0 && imageSize.height > 0 {
                let scale = max(viewSize.width / imageSize.width, viewSize.height / imageSize.height)
                let drawnSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)

                let extraWidth = drawnSize.width - viewSize.width
                let extraHeight = drawnSize.height - viewSize.height

                let offsetX = -extraWidth * (alignment.x - 0.5)
                let offsetY = -extraHeight * (alignment.y - 0.5)

                Image(uiImage: uiImage)
                    .resizable()
                    .frame(width: drawnSize.width, height: drawnSize.height)
                    .position(x: viewSize.width / 2 + offsetX, y: viewSize.height / 2 + offsetY)
            }
        }
        .clipped()
    }
}
