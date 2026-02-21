import SwiftUI

/// Curated font styles for user-created affirmations.
/// Each maps to system-available fonts on iOS — no bundled fonts needed.
enum AffirmationFontStyle: String, CaseIterable, Identifiable, Codable {
    case serif          // New York — elegant, warm
    case rounded        // SF Rounded — soft, approachable
    case classic        // SF Pro — clean, modern
    case handwritten    // Bradley Hand — personal, casual
    case typewriter     // American Typewriter — vintage
    case elegant        // Didot — high fashion, editorial
    case bold           // SF Pro Heavy — powerful, assertive
    case script         // Snell Roundhand — flowing, calligraphic

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .serif: "Serif"
        case .rounded: "Rounded"
        case .classic: "Classic"
        case .handwritten: "Handwritten"
        case .typewriter: "Typewriter"
        case .elegant: "Elegant"
        case .bold: "Bold"
        case .script: "Script"
        }
    }

    /// Preview font for the font picker at a fixed size.
    func previewFont(size: CGFloat = 18) -> Font {
        switch self {
        case .serif:
            .system(size: size, weight: .medium, design: .serif)
        case .rounded:
            .system(size: size, weight: .medium, design: .rounded)
        case .classic:
            .system(size: size, weight: .regular, design: .default)
        case .handwritten:
            .custom("BradleyHandITCTT-Bold", size: size)
        case .typewriter:
            .custom("AmericanTypewriter", size: size)
        case .elegant:
            .custom("Didot", size: size)
        case .bold:
            .system(size: size, weight: .heavy, design: .default)
        case .script:
            .custom("SnellRoundhand", size: size)
        }
    }

    /// Card display font scaled by text length.
    func cardFont(textLength: Int) -> Font {
        let size: CGFloat
        if textLength < 40 {
            size = 32
        } else if textLength < 80 {
            size = 26
        } else if textLength < 140 {
            size = 22
        } else {
            size = 19
        }

        return previewFont(size: size)
    }
}
