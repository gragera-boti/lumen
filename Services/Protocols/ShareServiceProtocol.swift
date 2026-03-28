import SwiftUI

/// Service for rendering shareable affirmation card images.
protocol ShareServiceProtocol: Sendable {
    /// Render an affirmation as a styled card image suitable for sharing.
    /// - Parameters:
    ///   - text: The affirmation text to display on the card.
    ///   - gradientColors: The gradient colors for the card background.
    ///   - size: The desired output image size in points.
    ///   - showWatermark: Whether to include the "Lumen" watermark.
    /// - Returns: The rendered card as a `UIImage`, or `nil` if rendering failed.
    @MainActor func renderShareImage(
        text: String,
        font: Font,
        letterSpacing: CGFloat,
        gradientColors: [Color],
        backgroundImage: UIImage?,
        size: CGSize,
        showWatermark: Bool
    ) -> UIImage?
}
