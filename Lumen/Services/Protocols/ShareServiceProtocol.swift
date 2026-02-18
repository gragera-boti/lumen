import SwiftUI

protocol ShareServiceProtocol: Sendable {
    @MainActor func renderShareImage(
        text: String,
        gradientColors: [Color],
        size: CGSize,
        showWatermark: Bool
    ) -> UIImage?
}
