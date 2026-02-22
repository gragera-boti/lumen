import SwiftUI

enum LumenTheme {
    // MARK: - Colors

    enum Colors {
        static let primary = Color("AccentColor")
        static let cardBackground = Color(.systemBackground).opacity(0.85)
        static let textPrimary = Color(.label)
        static let textSecondary = Color(.secondaryLabel)
        static let gentleAccent = Color(hex: "#7FBBCA")
        static let warmAccent = Color(hex: "#E8A87C")
        static let softPurple = Color(hex: "#A688B5")
        static let mintGreen = Color(hex: "#7EC8A0")

        // Ambient dark backgrounds for immersive screens
        static let ambientDark = Color(hex: "#0A0E1A")
        static let ambientMid = Color(hex: "#131B2E")
        static let ambientLight = Color(hex: "#1C2541")

        // Glass card surface
        static let glassBackground = Color.white.opacity(0.08)
        static let glassBorder = Color.white.opacity(0.12)

        static let gradients: [[Color]] = [
            [Color(hex: "#1B998B"), Color(hex: "#3B5998")],
            [Color(hex: "#E8A87C"), Color(hex: "#C38D9E")],
            [Color(hex: "#7FBBCA"), Color(hex: "#A688B5")],
            [Color(hex: "#7EC8A0"), Color(hex: "#3B5998")],
            [Color(hex: "#F4D06F"), Color(hex: "#E8A87C")],
            [Color(hex: "#C38D9E"), Color(hex: "#7FBBCA")],
        ]
    }

    // MARK: - Typography

    enum Typography {
        static let affirmationFont = Font.custom("PlayfairDisplayRoman-SemiBold", size: 34)
        static let affirmationLargeFont = Font.custom("PlayfairDisplayRoman-Bold", size: 42)
        static let headlineFont = Font.system(.title2, weight: .bold)
        static let bodyFont = Font.system(.body)
        static let captionFont = Font.system(.caption)
    }

    // MARK: - Spacing

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Radii

    enum Radii {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let card: CGFloat = 20
    }
}
