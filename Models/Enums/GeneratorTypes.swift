import UIKit

// MARK: - Pattern styles

enum GeneratorStyle: String, CaseIterable, Identifiable, Sendable {
    case aurora  // Flowing horizontal light bands
    case bokeh  // Soft luminous floating circles
    case dunes  // Smooth rolling wave bands
    case cosmos  // Deep space with nebula + stars
    case watercolor  // Soft bleeding paint washes
    case stainedGlass  // Bold angular shards with bright edges
    case waves  // Concentric ripple rings
    case prism  // Refracted light streaks / rainbow bars
    case topography  // Contour-map elevation lines

    // Advanced Non-Metal Algorithmic
    case etherealFlow // Swirling hair-like strands
    case neuralGrowth // Reaction-diffusion brain-like patterns
    case harmony // Hypotrochoids orbits
    case shards // Layered Voronoi cells
    case hyphae // Organic branching growth
    case juliaNebula // Julia set fractals
    
    // Metal Shaders
    case nebula // Iterative space clouds
    case iridescence // Color shift interference


    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .aurora: "Aurora"
        case .bokeh: "Bokeh"
        case .dunes: "Dunes"
        case .cosmos: "Cosmos"
        case .watercolor: "Watercolor"
        case .stainedGlass: "Stained Glass"
        case .waves: "Waves"
        case .prism: "Prism"
        case .topography: "Topography"
        case .etherealFlow: "Ethereal Flow"
        case .neuralGrowth: "Neural Growth"
        case .harmony: "Harmony"
        case .shards: "Shards"
        case .hyphae: "Hyphae"
        case .juliaNebula: "Julia Nebula"
        case .nebula: "Nebula"
        case .iridescence: "Iridescence"

        }
    }
}

// MARK: - Color palettes (curated for readability with white text)

enum ColorPalette: String, CaseIterable, Identifiable, Sendable {
    case warmFlame
    case nightFade
    case frozenDreams
    case rainyDay
    case oceanBreeze
    case goldenHour
    case deepForest
    case moonlight
    case cherry
    case auroraGreen
    case desert
    case sakura
    case electric
    case slate

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .warmFlame: "Warm Flame"
        case .nightFade: "Night Fade"
        case .frozenDreams: "Frozen Dreams"
        case .rainyDay: "Rainy Day"
        case .oceanBreeze: "Ocean Breeze"
        case .goldenHour: "Golden Hour"
        case .deepForest: "Deep Forest"
        case .moonlight: "Moonlight"
        case .cherry: "Cherry"
        case .auroraGreen: "Aurora Green"
        case .desert: "Desert"
        case .sakura: "Sakura"
        case .electric: "Electric"
        case .slate: "Slate"
        }
    }

    /// Primary gradient stops (3 colors — rich, saturated, dark enough for white text)
    var cgColors: [CGColor] {
        switch self {
        case .warmFlame:
            [
                UIColor(red: 0.75, green: 0.22, blue: 0.30, alpha: 1).cgColor,
                UIColor(red: 0.85, green: 0.42, blue: 0.35, alpha: 1).cgColor,
                UIColor(red: 0.60, green: 0.18, blue: 0.38, alpha: 1).cgColor,
            ]
        case .nightFade:
            [
                UIColor(red: 0.28, green: 0.15, blue: 0.55, alpha: 1).cgColor,
                UIColor(red: 0.50, green: 0.25, blue: 0.65, alpha: 1).cgColor,
                UIColor(red: 0.70, green: 0.30, blue: 0.55, alpha: 1).cgColor,
            ]
        case .frozenDreams:
            [
                UIColor(red: 0.35, green: 0.30, blue: 0.55, alpha: 1).cgColor,
                UIColor(red: 0.50, green: 0.40, blue: 0.65, alpha: 1).cgColor,
                UIColor(red: 0.30, green: 0.35, blue: 0.55, alpha: 1).cgColor,
            ]
        case .rainyDay:
            [
                UIColor(red: 0.20, green: 0.30, blue: 0.55, alpha: 1).cgColor,
                UIColor(red: 0.35, green: 0.40, blue: 0.65, alpha: 1).cgColor,
                UIColor(red: 0.25, green: 0.25, blue: 0.50, alpha: 1).cgColor,
            ]
        case .oceanBreeze:
            [
                UIColor(red: 0.05, green: 0.30, blue: 0.50, alpha: 1).cgColor,
                UIColor(red: 0.10, green: 0.45, blue: 0.60, alpha: 1).cgColor,
                UIColor(red: 0.08, green: 0.22, blue: 0.45, alpha: 1).cgColor,
            ]
        case .goldenHour:
            [
                UIColor(red: 0.70, green: 0.40, blue: 0.15, alpha: 1).cgColor,
                UIColor(red: 0.80, green: 0.50, blue: 0.20, alpha: 1).cgColor,
                UIColor(red: 0.55, green: 0.25, blue: 0.18, alpha: 1).cgColor,
            ]
        case .deepForest:
            [
                UIColor(red: 0.08, green: 0.30, blue: 0.22, alpha: 1).cgColor,
                UIColor(red: 0.12, green: 0.42, blue: 0.30, alpha: 1).cgColor,
                UIColor(red: 0.10, green: 0.25, blue: 0.28, alpha: 1).cgColor,
            ]
        case .moonlight:
            [
                UIColor(red: 0.08, green: 0.08, blue: 0.18, alpha: 1).cgColor,
                UIColor(red: 0.14, green: 0.15, blue: 0.30, alpha: 1).cgColor,
                UIColor(red: 0.20, green: 0.18, blue: 0.38, alpha: 1).cgColor,
            ]
        case .cherry:
            [
                UIColor(red: 0.55, green: 0.05, blue: 0.15, alpha: 1).cgColor,
                UIColor(red: 0.75, green: 0.10, blue: 0.25, alpha: 1).cgColor,
                UIColor(red: 0.40, green: 0.05, blue: 0.20, alpha: 1).cgColor,
            ]
        case .auroraGreen:
            [
                UIColor(red: 0.02, green: 0.18, blue: 0.15, alpha: 1).cgColor,
                UIColor(red: 0.05, green: 0.50, blue: 0.40, alpha: 1).cgColor,
                UIColor(red: 0.10, green: 0.30, blue: 0.45, alpha: 1).cgColor,
            ]
        case .desert:
            [
                UIColor(red: 0.60, green: 0.35, blue: 0.20, alpha: 1).cgColor,
                UIColor(red: 0.50, green: 0.28, blue: 0.18, alpha: 1).cgColor,
                UIColor(red: 0.35, green: 0.18, blue: 0.12, alpha: 1).cgColor,
            ]
        case .sakura:
            [
                UIColor(red: 0.60, green: 0.28, blue: 0.45, alpha: 1).cgColor,
                UIColor(red: 0.75, green: 0.40, blue: 0.55, alpha: 1).cgColor,
                UIColor(red: 0.50, green: 0.22, blue: 0.40, alpha: 1).cgColor,
            ]
        case .electric:
            [
                UIColor(red: 0.10, green: 0.05, blue: 0.30, alpha: 1).cgColor,
                UIColor(red: 0.30, green: 0.10, blue: 0.60, alpha: 1).cgColor,
                UIColor(red: 0.15, green: 0.40, blue: 0.65, alpha: 1).cgColor,
            ]
        case .slate:
            [
                UIColor(red: 0.18, green: 0.20, blue: 0.25, alpha: 1).cgColor,
                UIColor(red: 0.28, green: 0.30, blue: 0.35, alpha: 1).cgColor,
                UIColor(red: 0.15, green: 0.15, blue: 0.20, alpha: 1).cgColor,
            ]
        }
    }

    /// Accent color for overlays and pattern details
    var accentCGColor: CGColor {
        switch self {
        case .warmFlame: UIColor(red: 1.00, green: 0.70, blue: 0.55, alpha: 1).cgColor
        case .nightFade: UIColor(red: 0.80, green: 0.55, blue: 0.90, alpha: 1).cgColor
        case .frozenDreams: UIColor(red: 0.70, green: 0.65, blue: 0.90, alpha: 1).cgColor
        case .rainyDay: UIColor(red: 0.55, green: 0.65, blue: 0.90, alpha: 1).cgColor
        case .oceanBreeze: UIColor(red: 0.30, green: 0.80, blue: 0.75, alpha: 1).cgColor
        case .goldenHour: UIColor(red: 1.00, green: 0.80, blue: 0.40, alpha: 1).cgColor
        case .deepForest: UIColor(red: 0.40, green: 0.80, blue: 0.55, alpha: 1).cgColor
        case .moonlight: UIColor(red: 0.45, green: 0.45, blue: 0.75, alpha: 1).cgColor
        case .cherry: UIColor(red: 1.00, green: 0.40, blue: 0.50, alpha: 1).cgColor
        case .auroraGreen: UIColor(red: 0.30, green: 0.90, blue: 0.70, alpha: 1).cgColor
        case .desert: UIColor(red: 0.90, green: 0.70, blue: 0.45, alpha: 1).cgColor
        case .sakura: UIColor(red: 1.00, green: 0.70, blue: 0.80, alpha: 1).cgColor
        case .electric: UIColor(red: 0.50, green: 0.30, blue: 1.00, alpha: 1).cgColor
        case .slate: UIColor(red: 0.55, green: 0.60, blue: 0.70, alpha: 1).cgColor
        }
    }
}

// MARK: - Mood

enum GeneratorMood: String, CaseIterable, Identifiable, Sendable {
    case calm
    case hopeful
    case focused
    case energized
    case dreamy

    var id: String { rawValue }

    var displayName: String { rawValue.capitalized }
}

// MARK: - Request

struct BackgroundRequest: Sendable {
    let style: GeneratorStyle
    let palette: ColorPalette
    let mood: GeneratorMood
    let complexity: Float  // 0..1, controls density of decorative elements
    let seed: UInt32?
    let size: CGSize

    init(
        style: GeneratorStyle = .aurora,
        palette: ColorPalette = .warmFlame,
        mood: GeneratorMood = .calm,
        complexity: Float = 0.5,
        seed: UInt32? = nil,
        size: CGSize = CGSize(width: 512, height: 512)
    ) {
        self.style = style
        self.palette = palette
        self.mood = mood
        self.complexity = complexity
        self.seed = seed
        self.size = size
    }
}

// MARK: - Output

struct GeneratedBackground: Sendable {
    let themeId: String
    let imagePath: URL
    let thumbnailPath: URL
    let metadata: GenerationMetadata
}

struct GenerationMetadata: Codable, Sendable {
    let style: String
    let palette: String
    let mood: String
    let seed: UInt32
    let complexity: Float
    let width: Int
    let height: Int
    let durationMs: Int
}

// MARK: - Errors

enum BackgroundGeneratorError: Error, LocalizedError {
    case generationFailed(String)
    case cancelled

    var errorDescription: String? {
        switch self {
        case .generationFailed(let reason): "Generation failed: \(reason)"
        case .cancelled: "Generation was cancelled."
        }
    }
}
