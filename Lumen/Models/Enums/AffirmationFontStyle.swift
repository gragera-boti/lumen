import SwiftUI

/// Curated font styles for affirmation cards.
/// Includes bundled custom fonts (OFL-licensed) and select system fonts.
enum AffirmationFontStyle: String, CaseIterable, Identifiable, Codable {
    case playfair  // Playfair Display — dramatic editorial serif
    case cormorant  // Cormorant Garamond — refined, tall, elegant
    case caveat  // Caveat — warm natural handwriting
    case dancing  // Dancing Script — lively calligraphic script
    case abril  // Abril Fatface — bold display serif, magazine cover
    case josefin  // Josefin Sans — geometric, airy, Scandinavian
    case zilla  // Zilla Slab — friendly, strong slab serif
    case righteous  // Righteous — retro-futuristic display
    case rounded  // SF Rounded — soft, approachable (system)
    case heavy  // SF Pro Heavy — powerful, assertive (system)

    var id: String { rawValue }

    /// Initialize from a raw value, falling back to legacy mappings.
    /// Use this instead of `init?(rawValue:)` when reading persisted data.
    static func from(_ rawValue: String) -> AffirmationFontStyle? {
        if let style = AffirmationFontStyle(rawValue: rawValue) {
            return style
        }
        // Legacy mappings from v1 font styles
        switch rawValue {
        case "serif": return .playfair
        case "classic": return .josefin
        case "handwritten": return .caveat
        case "typewriter": return .zilla
        case "elegant": return .cormorant
        case "bold": return .heavy
        case "script": return .dancing
        default: return nil
        }
    }

    var displayName: String {
        switch self {
        case .playfair: "Playfair"
        case .cormorant: "Cormorant"
        case .caveat: "Handwritten"
        case .dancing: "Script"
        case .abril: "Display"
        case .josefin: "Minimal"
        case .zilla: "Slab"
        case .righteous: "Expressive"
        case .rounded: "Rounded"
        case .heavy: "Bold"
        }
    }

    /// Preview font for the font picker at a fixed size.
    func previewFont(size: CGFloat = 20) -> Font {
        switch self {
        case .playfair:
            .custom("PlayfairDisplayRoman-SemiBold", size: size)
        case .cormorant:
            .custom("CormorantGaramond-SemiBold", size: size)
        case .caveat:
            .custom("CaveatRoman-Bold", size: size)
        case .dancing:
            .custom("DancingScript-SemiBold", size: size)
        case .abril:
            .custom("AbrilFatface-Regular", size: size)
        case .josefin:
            .custom("JosefinSansRoman-Light", size: size)
        case .zilla:
            .custom("ZillaSlab-SemiBold", size: size)
        case .righteous:
            .custom("Righteous-Regular", size: size)
        case .rounded:
            .system(size: size, weight: .semibold, design: .rounded)
        case .heavy:
            .system(size: size, weight: .heavy, design: .default)
        }
    }

    /// Card display font scaled by text length — bolder and bigger than before.
    func cardFont(textLength: Int) -> Font {
        let size: CGFloat
        if textLength < 40 {
            size = 42  // Short phrases: big and bold
        } else if textLength < 80 {
            size = 34  // Medium: still prominent
        } else if textLength < 140 {
            size = 28  // Longer: readable but impactful
        } else {
            size = 23  // Very long: still larger than before
        }

        return cardWeight(size: size)
    }

    /// Uses a heavier weight for card display than preview.
    private func cardWeight(size: CGFloat) -> Font {
        switch self {
        case .playfair:
            .custom("PlayfairDisplayRoman-Bold", size: size)
        case .cormorant:
            .custom("CormorantGaramond-Bold", size: size)
        case .caveat:
            .custom("CaveatRoman-Bold", size: size)
        case .dancing:
            .custom("DancingScript-Bold", size: size)
        case .abril:
            .custom("AbrilFatface-Regular", size: size)  // Only has Regular (it's already bold)
        case .josefin:
            .custom("JosefinSansRoman-Regular", size: size)  // Light for preview, Regular for cards
        case .zilla:
            .custom("ZillaSlab-Bold", size: size)
        case .righteous:
            .custom("Righteous-Regular", size: size)  // Single weight, already bold
        case .rounded:
            .system(size: size, weight: .bold, design: .rounded)
        case .heavy:
            .system(size: size, weight: .heavy, design: .default)
        }
    }
}
