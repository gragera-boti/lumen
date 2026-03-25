import Foundation

/// Curated prompt library for AI background generation.
///
/// Each prompt is designed to produce abstract, colorful, calming imagery
/// that works beautifully behind white affirmation text. No faces, no text,
/// no recognizable objects — just pure color, light, and feeling.
struct AIBackgroundPrompt: Sendable, Identifiable, Codable {
    let id: String
    let prompt: String
    let negativePrompt: String
    let category: PromptCategory
    let displayName: String

    enum PromptCategory: String, CaseIterable, Identifiable, Codable, Sendable {
        case ethereal  // Soft, dreamy, otherworldly
        case cosmic  // Deep space, nebulae, stardust
        case organic  // Nature-inspired abstracts
        case luminous  // Light play, refractions, glows
        case fluid  // Liquid, flowing, watercolor-like
        case warm  // Golden hour, amber, comfort

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .ethereal: "Ethereal"
            case .cosmic: "Cosmic"
            case .organic: "Organic"
            case .luminous: "Luminous"
            case .fluid: "Fluid"
            case .warm: "Warm"
            }
        }

        var emoji: String {
            switch self {
            case .ethereal: "✨"
            case .cosmic: "🌌"
            case .organic: "🌿"
            case .luminous: "💎"
            case .fluid: "🌊"
            case .warm: "🌅"
            }
        }
    }

    /// Pick a random prompt from the full library
    static func random() -> AIBackgroundPrompt {
        library.randomElement() ?? library[0]
    }

    /// Pick a random prompt from a specific category
    static func random(category: PromptCategory) -> AIBackgroundPrompt {
        let filtered = library.filter { $0.category == category }
        return filtered.randomElement() ?? random()
    }

    // MARK: - The Prompt Library

    /// Shared negative prompt — keeps outputs abstract and clean
    private static let sharedNegative =
        "text, words, letters, numbers, watermark, signature, face, person, human, animal, photo, realistic, ugly, blurry, noisy, low quality, distorted, deformed"

    static let library: [AIBackgroundPrompt] = {
        var prompts: [AIBackgroundPrompt] = []
        var index = 0

        func add(_ name: String, _ category: PromptCategory, _ prompt: String) {
            prompts.append(
                AIBackgroundPrompt(
                    id: "ai_\(index)",
                    prompt: prompt,
                    negativePrompt: sharedNegative,
                    category: category,
                    displayName: name
                )
            )
            index += 1
        }

        // ═══════════════════════════════════════
        // ETHEREAL — soft, dreamy, otherworldly
        // ═══════════════════════════════════════

        add(
            "Morning Veil",
            .ethereal,
            "soft ethereal abstract gradient, translucent layers of pale rose and lavender, gentle light diffusion, dreamy atmosphere, smooth flowing forms, pastel aurora, silk-like textures floating in space"
        )

        add(
            "Cloud Whisper",
            .ethereal,
            "abstract cloudscape, soft billowing forms in pearl white and dusty lilac, volumetric light rays, heavenly glow, iridescent edges, gentle depth, peaceful and airy composition"
        )

        add(
            "Silk Dreams",
            .ethereal,
            "flowing silk fabric in abstract motion, delicate folds of champagne gold and soft pink, pearlescent highlights, gentle shadows, luxurious smooth texture, dreamy and weightless"
        )

        add(
            "Petal Drift",
            .ethereal,
            "abstract soft focus, scattered translucent rose petals dissolving into mist, gentle pink and cream gradient, bokeh light spots, romantic and serene, painterly quality"
        )

        add(
            "Twilight Haze",
            .ethereal,
            "abstract twilight gradient, soft transition from dusty blue to warm mauve to pale peach, gentle halos of light, atmospheric haze, calm and contemplative mood"
        )

        add(
            "Crystal Breath",
            .ethereal,
            "abstract crystalline structures in soft focus, faceted light refractions in pastel spectrum, gentle prismatic glow, translucent geometric forms, peaceful radiance"
        )

        // ═══════════════════════════════════════
        // COSMIC — deep space, nebulae, stardust
        // ═══════════════════════════════════════

        add(
            "Nebula Heart",
            .cosmic,
            "vibrant deep space nebula, rich purple and magenta gas clouds, scattered bright stars, cosmic dust lanes, galactic core glow, abstract astronomical beauty, saturated colors against deep black"
        )

        add(
            "Stardust River",
            .cosmic,
            "abstract cosmic river of stardust, flowing bands of turquoise and deep violet across dark space, sparkling particles, interstellar clouds, luminous cosmic highway"
        )

        add(
            "Aurora Borealis",
            .cosmic,
            "vivid northern lights in abstract style, curtains of emerald green and electric blue dancing across dark sky, subtle purple edges, magnetic field lines, celestial shimmer"
        )

        add(
            "Supernova Bloom",
            .cosmic,
            "abstract supernova explosion, radiating rings of hot pink and electric orange against deep blue, shockwave ripples, luminous expanding shells, energetic and awe-inspiring"
        )

        add(
            "Galaxy Swirl",
            .cosmic,
            "abstract spiral galaxy from above, swirling arms of deep indigo and electric violet, bright core, scattered star clusters, cosmic dust, deep space majesty"
        )

        add(
            "Constellation Pool",
            .cosmic,
            "abstract star field reflected in dark water, deep navy and midnight blue, bright points of light, gentle ripple distortions, infinite depth, meditative cosmic scene"
        )

        // ═══════════════════════════════════════
        // ORGANIC — nature-inspired abstracts
        // ═══════════════════════════════════════

        add(
            "Moss & Stone",
            .organic,
            "abstract macro texture, deep emerald green and warm brown earth tones, organic patterns like moss on ancient stone, natural gradient, rich earth pigments, grounding and calm"
        )

        add(
            "Underwater Garden",
            .organic,
            "abstract underwater scene, flowing seaweed-like forms in deep teal and jade, dappled light from above, gentle bubble textures, oceanic depth, peaceful aquatic mood"
        )

        add(
            "Autumn Canopy",
            .organic,
            "abstract view through autumn leaves, rich amber and burnt orange blending into deep burgundy, backlighting creating warm glow, organic leaf shapes in soft focus, cozy warmth"
        )

        add(
            "Forest Floor",
            .organic,
            "abstract forest light, dappled sunbeams through canopy, deep green and golden light, organic shadow patterns, fern-like shapes, woodland tranquility, rich natural tones"
        )

        add(
            "Desert Bloom",
            .organic,
            "abstract desert landscape colors, warm terracotta and sandy gold transitioning to pale sage green, subtle organic textures, dry warmth meeting gentle growth, earthy and hopeful"
        )

        add(
            "Coral Reef",
            .organic,
            "abstract coral reef colors, vivid coral pink and deep turquoise, organic branch-like structures, tropical vibrancy, underwater glow, rich saturated natural palette"
        )

        // ═══════════════════════════════════════
        // LUMINOUS — light play, refractions, glows
        // ═══════════════════════════════════════

        add(
            "Prism Light",
            .luminous,
            "abstract light passing through prism, rainbow spectrum dispersed across dark background, clean color bands, chromatic light play, vivid refraction, elegant and minimal"
        )

        add(
            "Lens Flare",
            .luminous,
            "abstract cinematic lens flare, warm golden and cool blue light streaks, hexagonal bokeh, anamorphic light leak, film-like quality, dramatic and beautiful"
        )

        add(
            "Northern Glow",
            .luminous,
            "abstract bioluminescent glow, soft cyan and electric blue light emanating from dark depths, gentle pulse effect, mysterious underwater radiance, deep and calming"
        )

        add(
            "Golden Rays",
            .luminous,
            "abstract sunlight rays, warm golden beams cutting through soft atmospheric haze, volumetric light, particles catching light, divine and uplifting, rich warm tones"
        )

        add(
            "Neon Dusk",
            .luminous,
            "abstract neon gradient, deep magenta fading to electric indigo, soft neon glow at horizon, smooth light bloom, cyberpunk sunset vibes, vibrant and bold"
        )

        add(
            "Diamond Fire",
            .luminous,
            "abstract light refraction through crystal, brilliant white and spectral colors, sharp geometric light patterns on dark background, luxury sparkle, mesmerizing clarity"
        )

        // ═══════════════════════════════════════
        // FLUID — liquid, flowing, watercolor-like
        // ═══════════════════════════════════════

        add(
            "Ink Drop",
            .fluid,
            "abstract ink dropping into water, swirling tendrils of deep indigo and cobalt blue in clear liquid, organic fluid dynamics, mesmerizing flow patterns, high contrast beauty"
        )

        add(
            "Liquid Marble",
            .fluid,
            "abstract marble texture with flowing veins, rich navy and rose gold swirls, luxurious fluid pattern, geode-like coloring, polished surface effect, elegant and sophisticated"
        )

        add(
            "Watercolor Wash",
            .fluid,
            "abstract watercolor painting, wet-on-wet technique, soft edges where warm coral meets cool periwinkle, organic color bleeding, gentle paper texture, artistic and dreamy"
        )

        add(
            "Ocean Current",
            .fluid,
            "abstract ocean current visualization, swirling teal and deep sapphire, flowing dynamic forms, powerful yet graceful movement, marine depth, immersive fluidity"
        )

        add(
            "Molten Jewel",
            .fluid,
            "abstract molten metal and gemstone colors, flowing streams of ruby red and liquid gold, rich viscous texture, glowing heat, luxurious and intense, deep shadows"
        )

        add(
            "Smoke Cascade",
            .fluid,
            "abstract colorful smoke, cascading wisps of purple and teal intertwining, soft volume, gentle turbulence, dark background, mysterious and elegant, smooth gradient edges"
        )

        // ═══════════════════════════════════════
        // WARM — golden hour, amber, comfort
        // ═══════════════════════════════════════

        add(
            "Golden Hour",
            .warm,
            "abstract golden hour sky, warm amber and peach gradient melting into soft dusty rose, gentle sun glow, hazy atmospheric warmth, comforting and nostalgic, rich warm palette"
        )

        add(
            "Candlelight",
            .warm,
            "abstract warm candlelight glow, soft amber and honey tones radiating from center, gentle dark edges, intimate warmth, flickering light quality, cozy and grounding"
        )

        add(
            "Copper Sunset",
            .warm,
            "abstract sunset reflection, burnished copper and rich tangerine blending into deep plum, smooth gradient, metallic warmth, horizon glow, luxurious evening light"
        )

        add(
            "Honey Drip",
            .warm,
            "abstract flowing honey colors, rich golden amber and warm caramel, viscous flowing forms, backlit warmth, organic sweetness, translucent and luminous, inviting depth"
        )

        add(
            "Ember Glow",
            .warm,
            "abstract glowing embers, deep cherry red and warm orange coals against dark charcoal, gentle heat shimmer, radiating warmth, intimate and powerful, primal comfort"
        )

        add(
            "Spice Market",
            .warm,
            "abstract spice colors, saffron yellow and cinnamon brown with touches of paprika red, rich layered warmth, exotic and inviting, earthy vibrancy, deep saturated tones"
        )

        return prompts
    }()
}
