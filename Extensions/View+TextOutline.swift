import SwiftUI

extension View {
    /// Renders the view with a subtle stroke outline behind it for improved legibility.
    /// - Parameters:
    ///   - color: The outline color. Defaults to semi-transparent black.
    ///   - width: Stroke width in points.
    func textOutline(color: Color = .black.opacity(0.55), width: CGFloat = 1.5) -> some View {
        self.modifier(TextOutlineModifier(outlineColor: color, lineWidth: width))
    }
}

private struct TextOutlineModifier: ViewModifier {
    let outlineColor: Color
    let lineWidth: CGFloat

    func body(content: Content) -> some View {
        let d = lineWidth
        content
            .overlay(
                ZStack {
                    content.foregroundStyle(outlineColor).offset(x: -d, y: -d)
                    content.foregroundStyle(outlineColor).offset(x:  0, y: -d)
                    content.foregroundStyle(outlineColor).offset(x:  d, y: -d)
                    content.foregroundStyle(outlineColor).offset(x: -d, y:  0)
                    content.foregroundStyle(outlineColor).offset(x:  d, y:  0)
                    content.foregroundStyle(outlineColor).offset(x: -d, y:  d)
                    content.foregroundStyle(outlineColor).offset(x:  0, y:  d)
                    content.foregroundStyle(outlineColor).offset(x:  d, y:  d)
                }
                .allowsHitTesting(false)
            )
    }
}
