import SwiftUI

/// A view layout that horizontal stacks elements and wraps to a new line when horizontal space runs out.
struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.bounds
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )

        for (index, subview) in subviews.enumerated() {
            let point = result.frames[index].origin
            let location = CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y)
            subview.place(at: location, proposal: .unspecified)
        }
    }

    struct FlowResult {
        var bounds: CGSize = .zero
        var frames: [CGRect] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentPosition: CGPoint = .zero
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentPosition.x + size.width > maxWidth, currentPosition.x > 0 {
                    // Wrap to next line
                    currentPosition.x = 0
                    currentPosition.y += lineHeight + spacing
                    lineHeight = 0
                }

                frames.append(CGRect(origin: currentPosition, size: size))

                // Update row state
                currentPosition.x += size.width + spacing
                lineHeight = max(lineHeight, size.height)
                bounds.width = max(bounds.width, currentPosition.x - spacing)
            }

            bounds.height = currentPosition.y + lineHeight
        }
    }
}
