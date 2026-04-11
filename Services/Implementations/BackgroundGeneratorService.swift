import OSLog
import UIKit

/// Procedural background generator using Core Graphics.
///
/// Produces rich, immersive backgrounds by compositing multiple layers:
/// 1. Deep base gradient (3-stop, angle varies by mood)
/// 2. Optional glow orbs for warmth and depth
/// 3. Style-specific pattern — each style uses fundamentally different geometry
/// 4. Light leak / god-ray overlay (mood-tuned)
/// 5. Subtle grain for organic texture
///
/// 12 distinct styles × 14 palettes × 5 moods = 840 unique combinations.
/// Runs entirely on-device, instant results, no model downloads.
actor BackgroundGeneratorService: BackgroundGeneratorProtocol {
    static let shared = BackgroundGeneratorService()

    private let logger = Logger(subsystem: "com.gragera.lumen", category: "BackgroundGenerator")
    private var currentTask: Task<GeneratedBackground, Error>?

    // MARK: - Protocol

    func generate(request: BackgroundRequest) async throws -> GeneratedBackground {
        let task = Task<GeneratedBackground, Error> {
            try Task.checkCancellation()

            let startTime = CFAbsoluteTimeGetCurrent()
            let seed = request.seed ?? UInt32.random(in: 0...UInt32.max)

            logger.info(
                "Generating: style=\(request.style.rawValue), palette=\(request.palette.rawValue), seed=\(seed)"
            )

            var rng = SeededRNG(seed: UInt64(seed))
            let image = try await self.generateImageContext(request: request, seed: seed, rng: &rng)

            try Task.checkCancellation()

            let themeId = "bg_\(UUID().uuidString.prefix(8))"
            let (imagePath, thumbPath) = try self.saveImage(image, themeId: themeId)
            let durationMs = Int((CFAbsoluteTimeGetCurrent() - startTime) * 1000)

            let metadata = GenerationMetadata(
                style: request.style.rawValue,
                palette: request.palette.rawValue,
                mood: request.mood.rawValue,
                seed: seed,
                complexity: request.complexity,
                width: Int(request.size.width),
                height: Int(request.size.height),
                durationMs: durationMs
            )

            logger.info("Generated \(themeId) in \(durationMs)ms")

            return GeneratedBackground(
                themeId: themeId,
                imagePath: imagePath,
                thumbnailPath: thumbPath,
                metadata: metadata
            )
        }

        currentTask = task
        return try await task.value
    }

    func cancelGeneration() async {
        currentTask?.cancel()
        currentTask = nil
    }

    // MARK: - Rendering pipeline
    
    private func generateImageContext(request: BackgroundRequest, seed: UInt32, rng: inout SeededRNG) async throws -> UIImage {
        // Since ImageRenderer fails off-screen with colorEffect, all metal styles are ported to off-thread CoreGraphics
        return renderCoreGraphicsImage(request: request, rng: &rng, seed: seed)
    }

    private func renderCoreGraphicsImage(request: BackgroundRequest, rng: inout SeededRNG, seed: UInt32) -> UIImage {
        let size = request.size
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: size)
            let gc = ctx.cgContext

            // Layer 1: Rich base gradient
            drawBaseGradient(gc: gc, rect: rect, palette: request.palette, mood: request.mood, rng: &rng)

            // Layer 2: Glow orbs (skip for styles that don't benefit)
            let skipOrbs: Set<GeneratorStyle> = [.stainedGlass, .prism, .topography, .shards, .hyphae, .harmony, .neuralGrowth, .nebula]
            if !skipOrbs.contains(request.style) {
                drawGlowOrbs(gc: gc, rect: rect, palette: request.palette, rng: &rng, complexity: request.complexity)
            }

            // Layer 3: Style-specific pattern
            switch request.style {
            case .aurora:
                drawAurora(gc: gc, rect: rect, palette: request.palette, complexity: request.complexity, rng: &rng)
            case .bokeh:
                drawBokeh(gc: gc, rect: rect, palette: request.palette, complexity: request.complexity, rng: &rng)
            case .dunes:
                drawDunes(gc: gc, rect: rect, palette: request.palette, complexity: request.complexity, rng: &rng)
            case .cosmos:
                drawCosmos(gc: gc, rect: rect, palette: request.palette, complexity: request.complexity, rng: &rng)
            case .watercolor:
                drawWatercolor(gc: gc, rect: rect, palette: request.palette, complexity: request.complexity, rng: &rng)
            case .stainedGlass:
                drawStainedGlass(gc: gc, rect: rect, palette: request.palette, complexity: request.complexity, rng: &rng)
            case .waves:
                drawWaves(gc: gc, rect: rect, palette: request.palette, complexity: request.complexity, rng: &rng)
            case .prism:
                drawPrism(gc: gc, rect: rect, palette: request.palette, complexity: request.complexity, rng: &rng)
            case .topography:
                drawTopography(gc: gc, rect: rect, palette: request.palette, complexity: request.complexity, rng: &rng, seed: seed)
            // New Advanced Non-Metal Algorithmic
            case .etherealFlow:
                drawEtherealFlow(gc: gc, rect: rect, palette: request.palette, complexity: request.complexity, rng: &rng, seed: seed)
            case .neuralGrowth:
                drawNeuralGrowth(gc: gc, rect: rect, palette: request.palette, complexity: request.complexity, rng: &rng, seed: seed)
            case .harmony:
                drawHarmony(gc: gc, rect: rect, palette: request.palette, complexity: request.complexity, rng: &rng)
            case .shards:
                drawShards(gc: gc, rect: rect, palette: request.palette, complexity: request.complexity, rng: &rng)
            case .hyphae:
                drawHyphae(gc: gc, rect: rect, palette: request.palette, complexity: request.complexity, rng: &rng, seed: seed)
            case .juliaNebula:
                drawJuliaNebula(gc: gc, rect: rect, palette: request.palette, complexity: request.complexity, rng: &rng)
            
            // Re-implemented Metal Shaders in CoreGraphics
            case .nebula:
                drawNebula(gc: gc, rect: rect, palette: request.palette, complexity: request.complexity, rng: &rng, seed: seed)
            case .iridescence:
                drawIridescence(gc: gc, rect: rect, palette: request.palette, complexity: request.complexity, rng: &rng, seed: seed)
            default:
                break
            }

            // Layer 4: Light leak
            drawLightLeak(gc: gc, rect: rect, mood: request.mood, rng: &rng)

            // Layer 5: Subtle grain
            drawGrain(gc: gc, rect: rect, rng: &rng)
        }
    }
}

// MARK: - Seeded RNG for reproducible generation

struct SeededRNG: RandomNumberGenerator, Sendable {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 1 : seed
    }

    mutating func next() -> UInt64 {
        // xorshift64
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }

    mutating func nextFloat() -> Float {
        Float(next() % 10000) / 10000.0
    }
}
