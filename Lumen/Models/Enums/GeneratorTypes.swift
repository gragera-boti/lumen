import Foundation

// MARK: - Background Generation Request

struct BackgroundGenerationRequest: Sendable {
    let styleId: GeneratorStyle
    let colorFamily: ColorFamily
    let mood: GeneratorMood
    let detailLevel: Float
    let seed: UInt32?
    let outputSize: GeneratorOutputSize

    init(
        styleId: GeneratorStyle = .abstract,
        colorFamily: ColorFamily = .warm,
        mood: GeneratorMood = .calm,
        detailLevel: Float = 0.5,
        seed: UInt32? = nil,
        outputSize: GeneratorOutputSize = .standard
    ) {
        self.styleId = styleId
        self.colorFamily = colorFamily
        self.mood = mood
        self.detailLevel = detailLevel
        self.seed = seed
        self.outputSize = outputSize
    }

    /// Composed prompt from structured selections (no free-form text)
    var prompt: String {
        let style = styleId.promptFragment
        let color = colorFamily.promptFragment
        let moodText = mood.promptFragment
        let detail = detailLevel < 0.33 ? "minimal" : detailLevel < 0.66 ? "medium detail" : "high detail"
        return "\(style), \(color), \(moodText), \(detail), high quality, 4k, wallpaper"
    }

    /// Safety negative prompt — always applied
    static let negativePrompt = "people, face, portrait, nude, violence, gore, weapon, blood, text, watermark, logo, explicit, nsfw, child, fingers, hands"
}

// MARK: - Generator Output

struct GeneratedBackground: Sendable {
    let themeId: String
    let imagePath: URL
    let thumbnailPath: URL
    let metadata: GenerationMetadata
}

struct GenerationMetadata: Codable, Sendable {
    let model: String
    let styleId: String
    let seed: UInt32
    let steps: Int
    let guidanceScale: Float
    let size: Int
    let prompt: String
    let durationMs: Int
}

// MARK: - Device capability

enum GeneratorCapability: Sendable {
    case supported(tier: DeviceTier)
    case unsupported(reason: String)
}

enum DeviceTier: Sendable {
    case high    // A17+: steps=25, size=512
    case mid     // A15-A16: steps=20, size=512
    case low     // A14: steps=12, size=512

    var steps: Int {
        switch self {
        case .high: 25
        case .mid: 20
        case .low: 12
        }
    }

    var guidanceScale: Float {
        7.0
    }
}

enum GeneratorOutputSize: Sendable {
    case standard  // 512×512
    case large     // 768×768 (P2)

    var pixels: Int {
        switch self {
        case .standard: 512
        case .large: 768
        }
    }
}

// MARK: - Style definitions

extension GeneratorStyle {
    var promptFragment: String {
        switch self {
        case .abstract: "soft abstract watercolor, flowing shapes, dreamy atmosphere"
        case .nature: "serene natural landscape, soft focus, gentle light"
        case .mist: "ethereal mist, fog layers, atmospheric depth"
        case .minimal: "clean minimal geometric, soft gradients, simple forms"
        }
    }
}

extension ColorFamily {
    var promptFragment: String {
        switch self {
        case .warm: "warm palette, amber, peach, coral, golden"
        case .cool: "cool palette, teal, ocean blue, lavender, mint"
        case .mono: "monochrome, subtle grey tones, silver, charcoal"
        }
    }
}

// Rename Mood enum to avoid conflict with existing
enum GeneratorMood: String, CaseIterable, Sendable {
    case calm
    case hopeful
    case focused

    var promptFragment: String {
        switch self {
        case .calm: "calm atmosphere, tranquil, peaceful, serene"
        case .hopeful: "hopeful mood, sunrise feel, optimistic light"
        case .focused: "focused energy, clear, structured, balanced"
        }
    }
}
