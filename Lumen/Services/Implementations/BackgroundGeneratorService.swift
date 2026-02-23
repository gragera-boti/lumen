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
            let image = renderImage(request: request, rng: &rng)

            try Task.checkCancellation()

            let themeId = "bg_\(UUID().uuidString.prefix(8))"
            let (imagePath, thumbPath) = try saveImage(image, themeId: themeId)
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

    private func renderImage(request: BackgroundRequest, rng: inout SeededRNG) -> UIImage {
        let size = request.size
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: size)
            let gc = ctx.cgContext

            // Layer 1: Rich base gradient
            drawBaseGradient(gc: gc, rect: rect, palette: request.palette, mood: request.mood, rng: &rng)

            // Layer 2: Glow orbs (skip for styles that don't benefit)
            let skipOrbs: Set<GeneratorStyle> = [.geometric, .stainedGlass, .prism, .topography]
            if !skipOrbs.contains(request.style) {
                drawGlowOrbs(gc: gc, rect: rect, palette: request.palette, rng: &rng, complexity: request.complexity)
            }

            // Layer 3: Style-specific pattern
            switch request.style {
            case .aurora:
                drawAurora(gc: gc, rect: rect, palette: request.palette, complexity: request.complexity, rng: &rng)
            case .bokeh:
                drawBokeh(gc: gc, rect: rect, palette: request.palette, complexity: request.complexity, rng: &rng)
            case .mist:
                drawMist(gc: gc, rect: rect, palette: request.palette, complexity: request.complexity, rng: &rng)
            case .dunes:
                drawDunes(gc: gc, rect: rect, palette: request.palette, complexity: request.complexity, rng: &rng)
            case .minimal:
                break  // Just base + orbs
            case .cosmos:
                drawCosmos(gc: gc, rect: rect, palette: request.palette, complexity: request.complexity, rng: &rng)
            case .geometric:
                drawGeometric(gc: gc, rect: rect, palette: request.palette, complexity: request.complexity, rng: &rng)
            case .watercolor:
                drawWatercolor(gc: gc, rect: rect, palette: request.palette, complexity: request.complexity, rng: &rng)
            case .stainedGlass:
                drawStainedGlass(
                    gc: gc,
                    rect: rect,
                    palette: request.palette,
                    complexity: request.complexity,
                    rng: &rng
                )
            case .waves:
                drawWaves(gc: gc, rect: rect, palette: request.palette, complexity: request.complexity, rng: &rng)
            case .prism:
                drawPrism(gc: gc, rect: rect, palette: request.palette, complexity: request.complexity, rng: &rng)
            case .topography:
                drawTopography(gc: gc, rect: rect, palette: request.palette, complexity: request.complexity, rng: &rng)
            }

            // Layer 4: Light leak
            drawLightLeak(gc: gc, rect: rect, mood: request.mood, rng: &rng)

            // Layer 5: Subtle grain
            drawGrain(gc: gc, rect: rect, rng: &rng)
        }
    }

    // MARK: - Layer 1: Base gradient

    private func drawBaseGradient(
        gc: CGContext,
        rect: CGRect,
        palette: ColorPalette,
        mood: GeneratorMood,
        rng: inout SeededRNG
    ) {
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        let colors = palette.cgColors.map { cgColor -> CGColor in
            let uiColor = UIColor(cgColor: cgColor)
            var h: CGFloat = 0
            var s: CGFloat = 0
            var b: CGFloat = 0
            var a: CGFloat = 0
            uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
            return UIColor(hue: h, saturation: min(s * 1.2, 1.0), brightness: b * 0.85, alpha: a).cgColor
        }

        guard
            let gradient = CGGradient(
                colorsSpace: colorSpace,
                colors: colors as CFArray,
                locations: [0.0, 0.45, 1.0]
            )
        else { return }

        let angle: CGFloat =
            switch mood {
            case .calm: .pi * 0.65
            case .hopeful: .pi * 0.35
            case .focused: .pi * 0.5
            case .energized: .pi * 0.25
            case .dreamy: .pi * 0.75
            }

        // Add slight random angle variation for uniqueness
        let jitter = CGFloat(rng.nextFloat() - 0.5) * 0.15
        let finalAngle = angle + jitter

        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = max(rect.width, rect.height) * 0.6
        let start = CGPoint(x: center.x + cos(finalAngle) * radius, y: center.y + sin(finalAngle) * radius)
        let end = CGPoint(x: center.x - cos(finalAngle) * radius, y: center.y - sin(finalAngle) * radius)

        gc.drawLinearGradient(
            gradient,
            start: start,
            end: end,
            options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
        )
    }

    // MARK: - Layer 2: Glow orbs

    private func drawGlowOrbs(
        gc: CGContext,
        rect: CGRect,
        palette: ColorPalette,
        rng: inout SeededRNG,
        complexity: Float
    ) {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let orbCount = 2 + Int(complexity * 4)
        let allColors = palette.cgColors + [palette.accentCGColor]

        for _ in 0..<orbCount {
            let x = CGFloat(0.1 + rng.nextFloat() * 0.8) * rect.width
            let y = CGFloat(0.1 + rng.nextFloat() * 0.8) * rect.height
            let radius = CGFloat(0.12 + rng.nextFloat() * 0.28) * max(rect.width, rect.height)
            let center = CGPoint(x: x, y: y)

            let sourceColor = allColors[Int(rng.next() % UInt64(allColors.count))]
            let alpha = CGFloat(0.12 + rng.nextFloat() * 0.18)

            let colors =
                [
                    UIColor(cgColor: sourceColor).withAlphaComponent(alpha).cgColor,
                    UIColor(cgColor: sourceColor).withAlphaComponent(alpha * 0.3).cgColor,
                    UIColor(cgColor: sourceColor).withAlphaComponent(0).cgColor,
                ] as CFArray

            if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 0.4, 1]) {
                gc.drawRadialGradient(
                    gradient,
                    startCenter: center,
                    startRadius: 0,
                    endCenter: center,
                    endRadius: radius,
                    options: []
                )
            }
        }
    }

    // MARK: - Aurora — rich flowing bands

    private func drawAurora(gc: CGContext, rect: CGRect, palette: ColorPalette, complexity: Float, rng: inout SeededRNG)
    {
        let bandCount = 4 + Int(complexity * 5)
        let allColors = palette.cgColors + [palette.accentCGColor]
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        for i in 0..<bandCount {
            let fraction = CGFloat(i) / CGFloat(bandCount)
            let yBase = rect.height * (0.15 + fraction * 0.65)
            let amplitude = rect.height * CGFloat(0.04 + rng.nextFloat() * 0.1)
            let frequency = CGFloat(1.2 + rng.nextFloat() * 2.5)
            let phase = CGFloat(rng.nextFloat()) * .pi * 2
            let bandHeight = rect.height * CGFloat(0.06 + rng.nextFloat() * 0.1)

            let topPath = CGMutablePath()
            let steps = 80

            topPath.move(to: CGPoint(x: -10, y: yBase))

            for s in 0...steps {
                let x = rect.width * CGFloat(s) / CGFloat(steps)
                let n = x / rect.width
                let yTop = yBase + sin(n * .pi * frequency + phase) * amplitude
                topPath.addLine(to: CGPoint(x: x, y: yTop))
            }

            let fillPath = CGMutablePath()
            fillPath.addPath(topPath)

            for s in (0...steps).reversed() {
                let x = rect.width * CGFloat(s) / CGFloat(steps)
                let n = x / rect.width
                let yTop = yBase + sin(n * .pi * frequency + phase) * amplitude
                let yBot = yTop + bandHeight + sin(n * .pi * (frequency * 0.7) + phase * 1.3) * amplitude * 0.4
                fillPath.addLine(to: CGPoint(x: x, y: yBot))
            }
            fillPath.closeSubpath()

            let colorIdx = i % allColors.count
            let bandColor = UIColor(cgColor: allColors[colorIdx])
            let alpha = CGFloat(0.12 + complexity * 0.15)

            gc.saveGState()
            gc.addPath(fillPath)
            gc.clip()

            if let g = CGGradient(
                colorsSpace: colorSpace,
                colors: [
                    bandColor.withAlphaComponent(alpha * 0.3).cgColor,
                    bandColor.withAlphaComponent(alpha).cgColor,
                    bandColor.withAlphaComponent(alpha * 0.5).cgColor,
                ] as CFArray,
                locations: [0, 0.5, 1]
            ) {
                gc.drawLinearGradient(
                    g,
                    start: CGPoint(x: rect.midX, y: yBase - amplitude),
                    end: CGPoint(x: rect.midX, y: yBase + bandHeight + amplitude),
                    options: []
                )
            }
            gc.restoreGState()
        }
    }

    // MARK: - Bokeh — luminous floating circles

    private func drawBokeh(gc: CGContext, rect: CGRect, palette: ColorPalette, complexity: Float, rng: inout SeededRNG)
    {
        let circleCount = 12 + Int(complexity * 30)
        let allColors = palette.cgColors + [palette.accentCGColor]
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        var circles: [(x: CGFloat, y: CGFloat, r: CGFloat, colorIdx: Int)] = []
        for _ in 0..<circleCount {
            circles.append(
                (
                    x: CGFloat(rng.nextFloat()) * rect.width,
                    y: CGFloat(rng.nextFloat()) * rect.height,
                    r: CGFloat(20 + rng.nextFloat() * 80) * CGFloat(0.6 + complexity * 0.8),
                    colorIdx: Int(rng.next() % UInt64(allColors.count))
                )
            )
        }
        circles.sort { $0.r > $1.r }

        for circle in circles {
            let center = CGPoint(x: circle.x, y: circle.y)
            let color = UIColor(cgColor: allColors[circle.colorIdx])
            let alpha = CGFloat(0.06 + rng.nextFloat() * 0.14)

            let colors =
                [
                    color.withAlphaComponent(alpha * 0.8).cgColor,
                    color.withAlphaComponent(alpha).cgColor,
                    color.withAlphaComponent(alpha * 0.5).cgColor,
                    color.withAlphaComponent(0).cgColor,
                ] as CFArray

            if let radial = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 0.3, 0.7, 1]) {
                gc.drawRadialGradient(
                    radial,
                    startCenter: center,
                    startRadius: 0,
                    endCenter: center,
                    endRadius: circle.r,
                    options: []
                )
            }

            if rng.nextFloat() > 0.6 {
                gc.setStrokeColor(color.withAlphaComponent(alpha * 0.6).cgColor)
                gc.setLineWidth(1.5)
                gc.strokeEllipse(
                    in: CGRect(
                        x: circle.x - circle.r * 0.9,
                        y: circle.y - circle.r * 0.9,
                        width: circle.r * 1.8,
                        height: circle.r * 1.8
                    )
                )
            }
        }
    }

    // MARK: - Mist — dreamy layered fog

    private func drawMist(gc: CGContext, rect: CGRect, palette: ColorPalette, complexity: Float, rng: inout SeededRNG) {
        let layerCount = 5 + Int(complexity * 5)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let allColors = palette.cgColors + [palette.accentCGColor]

        for i in 0..<layerCount {
            let yCenter = rect.height * CGFloat(0.2 + rng.nextFloat() * 0.6)
            let xOffset = CGFloat(rng.nextFloat() - 0.5) * rect.width * 0.6
            let center = CGPoint(x: rect.midX + xOffset, y: yCenter)
            let radiusX = rect.width * CGFloat(0.35 + rng.nextFloat() * 0.4)
            let radiusY = rect.height * CGFloat(0.06 + rng.nextFloat() * 0.15)
            let alpha = CGFloat(0.08 + complexity * 0.12)

            let sourceColor = UIColor(cgColor: allColors[i % allColors.count])

            let colors =
                [
                    sourceColor.withAlphaComponent(alpha).cgColor,
                    sourceColor.withAlphaComponent(alpha * 0.4).cgColor,
                    sourceColor.withAlphaComponent(0).cgColor,
                ] as CFArray

            gc.saveGState()
            gc.translateBy(x: center.x, y: center.y)
            gc.scaleBy(x: 1.0, y: radiusY / radiusX)
            gc.translateBy(x: -center.x, y: -center.y)

            if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 0.5, 1]) {
                gc.drawRadialGradient(
                    gradient,
                    startCenter: center,
                    startRadius: 0,
                    endCenter: center,
                    endRadius: radiusX,
                    options: []
                )
            }
            gc.restoreGState()
        }
    }

    // MARK: - Dunes — layered sand-wave bands

    private func drawDunes(gc: CGContext, rect: CGRect, palette: ColorPalette, complexity: Float, rng: inout SeededRNG)
    {
        let waveCount = 5 + Int(complexity * 6)
        let allColors = palette.cgColors + [palette.accentCGColor]
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        for i in 0..<waveCount {
            let fraction = CGFloat(i) / CGFloat(waveCount)
            let yBase = rect.height * (0.2 + fraction * 0.65)
            let amplitude = rect.height * CGFloat(0.02 + rng.nextFloat() * 0.06)
            let wavelength = CGFloat(0.6 + rng.nextFloat() * 1.8)
            let phase = CGFloat(rng.nextFloat()) * .pi * 2
            let bandDepth = rect.height * CGFloat(0.08 + fraction * 0.12)

            let path = CGMutablePath()
            let steps = 100
            path.move(to: CGPoint(x: -10, y: rect.maxY + 10))
            path.addLine(to: CGPoint(x: -10, y: yBase))

            for s in 0...steps {
                let x = rect.width * CGFloat(s) / CGFloat(steps)
                let n = x / rect.width
                let y =
                    yBase
                    + sin(n * .pi * 2 * wavelength + phase) * amplitude
                    + cos(n * .pi * 3 * wavelength * 0.5 + phase * 0.7) * amplitude * 0.3
                path.addLine(to: CGPoint(x: x, y: y))
            }

            path.addLine(to: CGPoint(x: rect.maxX + 10, y: rect.maxY + 10))
            path.closeSubpath()

            let colorIdx = (waveCount - 1 - i) % allColors.count
            let waveColor = UIColor(cgColor: allColors[colorIdx])
            let alpha: CGFloat = CGFloat(0.08) + fraction * 0.12 + CGFloat(complexity) * 0.05

            gc.saveGState()
            gc.addPath(path)
            gc.clip()

            if let g = CGGradient(
                colorsSpace: colorSpace,
                colors: [
                    waveColor.withAlphaComponent(alpha).cgColor,
                    waveColor.withAlphaComponent(alpha * 0.3).cgColor,
                ] as CFArray,
                locations: [0, 1]
            ) {
                gc.drawLinearGradient(
                    g,
                    start: CGPoint(x: rect.midX, y: yBase),
                    end: CGPoint(x: rect.midX, y: yBase + bandDepth),
                    options: [.drawsAfterEndLocation]
                )
            }
            gc.restoreGState()
        }
    }

    // MARK: - Cosmos — deep space with nebula and stars

    private func drawCosmos(gc: CGContext, rect: CGRect, palette: ColorPalette, complexity: Float, rng: inout SeededRNG)
    {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let nebulaCount = 2 + Int(complexity * 2)
        let allColors = palette.cgColors + [palette.accentCGColor]

        for i in 0..<nebulaCount {
            let cx = CGFloat(0.15 + rng.nextFloat() * 0.7) * rect.width
            let cy = CGFloat(0.15 + rng.nextFloat() * 0.7) * rect.height
            let center = CGPoint(x: cx, y: cy)
            let radius = CGFloat(0.2 + rng.nextFloat() * 0.3) * max(rect.width, rect.height)
            let alpha = CGFloat(0.12 + complexity * 0.1)
            let nebulaColor = UIColor(cgColor: allColors[i % allColors.count])

            gc.saveGState()
            let scaleY = CGFloat(0.5 + rng.nextFloat() * 0.5)
            let rotation = CGFloat(rng.nextFloat()) * .pi
            gc.translateBy(x: center.x, y: center.y)
            gc.rotate(by: rotation)
            gc.scaleBy(x: 1.0, y: scaleY)

            let colors =
                [
                    nebulaColor.withAlphaComponent(alpha).cgColor,
                    nebulaColor.withAlphaComponent(alpha * 0.5).cgColor,
                    nebulaColor.withAlphaComponent(0).cgColor,
                ] as CFArray

            if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 0.4, 1]) {
                gc.drawRadialGradient(
                    gradient,
                    startCenter: .zero,
                    startRadius: 0,
                    endCenter: .zero,
                    endRadius: radius,
                    options: []
                )
            }
            gc.restoreGState()
        }

        // Star field
        let starCount = 50 + Int(complexity * 150)
        for _ in 0..<starCount {
            let x = CGFloat(rng.nextFloat()) * rect.width
            let y = CGFloat(rng.nextFloat()) * rect.height
            let size = CGFloat(0.4 + rng.nextFloat() * 1.8)
            let alpha = CGFloat(0.2 + rng.nextFloat() * 0.6)
            gc.setFillColor(UIColor.white.withAlphaComponent(alpha).cgColor)
            gc.fillEllipse(in: CGRect(x: x - size, y: y - size, width: size * 2, height: size * 2))
        }

        // Bright stars with cross-glow
        let brightCount = 3 + Int(complexity * 6)
        for _ in 0..<brightCount {
            let x = CGFloat(rng.nextFloat()) * rect.width
            let y = CGFloat(rng.nextFloat()) * rect.height
            let glowRadius = CGFloat(15 + rng.nextFloat() * 40)
            let center = CGPoint(x: x, y: y)
            let starAlpha = CGFloat(0.15 + rng.nextFloat() * 0.2)

            let colors =
                [
                    UIColor.white.withAlphaComponent(starAlpha).cgColor,
                    UIColor.white.withAlphaComponent(starAlpha * 0.3).cgColor,
                    UIColor.white.withAlphaComponent(0).cgColor,
                ] as CFArray

            if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 0.3, 1]) {
                gc.drawRadialGradient(
                    gradient,
                    startCenter: center,
                    startRadius: 0,
                    endCenter: center,
                    endRadius: glowRadius,
                    options: []
                )
            }

            gc.setStrokeColor(UIColor.white.withAlphaComponent(starAlpha * 0.5).cgColor)
            gc.setLineWidth(0.5)
            let spikeLen = glowRadius * 0.8
            gc.move(to: CGPoint(x: x - spikeLen, y: y))
            gc.addLine(to: CGPoint(x: x + spikeLen, y: y))
            gc.move(to: CGPoint(x: x, y: y - spikeLen))
            gc.addLine(to: CGPoint(x: x, y: y + spikeLen))
            gc.strokePath()
        }
    }

    // MARK: - Geometric — tessellated crystal facets

    private func drawGeometric(
        gc: CGContext,
        rect: CGRect,
        palette: ColorPalette,
        complexity: Float,
        rng: inout SeededRNG
    ) {
        let allColors = palette.cgColors + [palette.accentCGColor]
        let cellCount = 20 + Int(complexity * 40)

        // Generate Voronoi-like seed points
        var points: [CGPoint] = []
        for _ in 0..<cellCount {
            points.append(
                CGPoint(
                    x: CGFloat(rng.nextFloat()) * rect.width,
                    y: CGFloat(rng.nextFloat()) * rect.height
                )
            )
        }

        // For each point, draw a polygon by connecting midpoints to neighbors
        // Simplified: draw triangles from random triplets of nearby points
        let triangleCount = 15 + Int(complexity * 35)
        for _ in 0..<triangleCount {
            let i0 = Int(rng.next() % UInt64(points.count))
            let i1 = Int(rng.next() % UInt64(points.count))
            let i2 = Int(rng.next() % UInt64(points.count))
            guard i0 != i1, i1 != i2, i0 != i2 else { continue }

            let p0 = points[i0]
            let p1 = points[i1]
            let p2 = points[i2]

            // Skip very large triangles
            let maxDist = max(
                hypot(p1.x - p0.x, p1.y - p0.y),
                hypot(p2.x - p1.x, p2.y - p1.y),
                hypot(p0.x - p2.x, p0.y - p2.y)
            )
            guard maxDist < rect.width * 0.5 else { continue }

            let path = CGMutablePath()
            path.move(to: p0)
            path.addLine(to: p1)
            path.addLine(to: p2)
            path.closeSubpath()

            let colorIdx = Int(rng.next() % UInt64(allColors.count))
            let color = UIColor(cgColor: allColors[colorIdx])
            let alpha = CGFloat(0.08 + rng.nextFloat() * 0.18)

            gc.setFillColor(color.withAlphaComponent(alpha).cgColor)
            gc.addPath(path)
            gc.fillPath()

            // Thin bright edge
            gc.setStrokeColor(UIColor.white.withAlphaComponent(alpha * 0.3).cgColor)
            gc.setLineWidth(0.5)
            gc.addPath(path)
            gc.strokePath()
        }

        // Diamond highlights at some vertices
        let diamondCount = 5 + Int(complexity * 10)
        for i in 0..<min(diamondCount, points.count) {
            let p = points[i]
            let size = CGFloat(3 + rng.nextFloat() * 8)
            let diamond = CGMutablePath()
            diamond.move(to: CGPoint(x: p.x, y: p.y - size))
            diamond.addLine(to: CGPoint(x: p.x + size * 0.6, y: p.y))
            diamond.addLine(to: CGPoint(x: p.x, y: p.y + size))
            diamond.addLine(to: CGPoint(x: p.x - size * 0.6, y: p.y))
            diamond.closeSubpath()

            gc.setFillColor(UIColor.white.withAlphaComponent(CGFloat(0.08 + rng.nextFloat() * 0.12)).cgColor)
            gc.addPath(diamond)
            gc.fillPath()
        }
    }

    // MARK: - Watercolor — soft bleeding paint washes

    private func drawWatercolor(
        gc: CGContext,
        rect: CGRect,
        palette: ColorPalette,
        complexity: Float,
        rng: inout SeededRNG
    ) {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let allColors = palette.cgColors + [palette.accentCGColor]
        let washCount = 6 + Int(complexity * 8)

        for i in 0..<washCount {
            let cx = CGFloat(rng.nextFloat()) * rect.width
            let cy = CGFloat(rng.nextFloat()) * rect.height
            let center = CGPoint(x: cx, y: cy)

            // Irregular blob: draw multiple overlapping ellipses
            let blobParts = 3 + Int(rng.nextFloat() * 4)
            let baseRadius = CGFloat(0.1 + rng.nextFloat() * 0.25) * max(rect.width, rect.height)
            let colorIdx = i % allColors.count
            let washColor = UIColor(cgColor: allColors[colorIdx])
            let alpha = CGFloat(0.06 + rng.nextFloat() * 0.12)

            for _ in 0..<blobParts {
                let offsetX = CGFloat(rng.nextFloat() - 0.5) * baseRadius * 0.6
                let offsetY = CGFloat(rng.nextFloat() - 0.5) * baseRadius * 0.6
                let partCenter = CGPoint(x: cx + offsetX, y: cy + offsetY)
                let partRadius = baseRadius * CGFloat(0.5 + rng.nextFloat() * 0.6)

                // Stretch into ellipse
                let scaleX = CGFloat(0.6 + rng.nextFloat() * 0.8)
                let scaleY = CGFloat(0.6 + rng.nextFloat() * 0.8)

                gc.saveGState()
                gc.translateBy(x: partCenter.x, y: partCenter.y)
                gc.scaleBy(x: scaleX, y: scaleY)
                gc.translateBy(x: -partCenter.x, y: -partCenter.y)

                // Soft radial gradient for watercolor bleed
                let colors =
                    [
                        washColor.withAlphaComponent(alpha).cgColor,
                        washColor.withAlphaComponent(alpha * 0.6).cgColor,
                        washColor.withAlphaComponent(alpha * 0.15).cgColor,
                        washColor.withAlphaComponent(0).cgColor,
                    ] as CFArray

                if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 0.25, 0.65, 1]) {
                    gc.drawRadialGradient(
                        gradient,
                        startCenter: partCenter,
                        startRadius: 0,
                        endCenter: partCenter,
                        endRadius: partRadius,
                        options: []
                    )
                }
                gc.restoreGState()
            }
        }

        // Paper texture: subtle splotches
        let splotchCount = 15 + Int(complexity * 20)
        for _ in 0..<splotchCount {
            let x = CGFloat(rng.nextFloat()) * rect.width
            let y = CGFloat(rng.nextFloat()) * rect.height
            let r = CGFloat(5 + rng.nextFloat() * 30)
            let dark = rng.nextFloat() > 0.5
            let alpha = CGFloat(0.02 + rng.nextFloat() * 0.04)

            gc.setFillColor((dark ? UIColor.black : UIColor.white).withAlphaComponent(alpha).cgColor)
            gc.fillEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
        }
    }

    // MARK: - Stained Glass — bold angular shards with bright edges

    private func drawStainedGlass(
        gc: CGContext,
        rect: CGRect,
        palette: ColorPalette,
        complexity: Float,
        rng: inout SeededRNG
    ) {
        let allColors = palette.cgColors + [palette.accentCGColor]

        // Generate seed points in a grid with jitter for organic Voronoi feel
        let cols = 4 + Int(complexity * 4)
        let rows = 6 + Int(complexity * 6)
        var points: [CGPoint] = []

        for r in 0...rows {
            for c in 0...cols {
                let baseX = rect.width * CGFloat(c) / CGFloat(cols)
                let baseY = rect.height * CGFloat(r) / CGFloat(rows)
                let jitterX = CGFloat(rng.nextFloat() - 0.5) * rect.width / CGFloat(cols) * 0.8
                let jitterY = CGFloat(rng.nextFloat() - 0.5) * rect.height / CGFloat(rows) * 0.8
                points.append(CGPoint(x: baseX + jitterX, y: baseY + jitterY))
            }
        }

        // For each pixel region, approximate Voronoi by drawing colored quads between neighbors
        // Simpler approach: draw filled convex polygons for each Delaunay-like triangle
        let triCount = 30 + Int(complexity * 50)
        for _ in 0..<triCount {
            // Pick a random point and its 2 nearest neighbors
            let seedIdx = Int(rng.next() % UInt64(points.count))
            let seedPt = points[seedIdx]

            var sorted = points.enumerated()
                .filter { $0.offset != seedIdx }
                .map { (idx: $0.offset, dist: hypot($0.element.x - seedPt.x, $0.element.y - seedPt.y)) }
                .sorted { $0.dist < $1.dist }

            guard sorted.count >= 2 else { continue }

            let p0 = seedPt
            let p1 = points[sorted[0].idx]
            let p2 = points[sorted[1].idx]

            let path = CGMutablePath()
            path.move(to: p0)
            path.addLine(to: p1)
            path.addLine(to: p2)
            path.closeSubpath()

            let colorIdx = Int(rng.next() % UInt64(allColors.count))
            let color = UIColor(cgColor: allColors[colorIdx])
            let alpha = CGFloat(0.15 + rng.nextFloat() * 0.25)

            gc.setFillColor(color.withAlphaComponent(alpha).cgColor)
            gc.addPath(path)
            gc.fillPath()
        }

        // Draw "lead" lines between neighboring points
        gc.setStrokeColor(UIColor.black.withAlphaComponent(0.3).cgColor)
        gc.setLineWidth(1.5)
        let maxEdgeDist = max(rect.width, rect.height) * 0.2
        for i in 0..<points.count {
            for j in (i + 1)..<points.count {
                let d = hypot(points[j].x - points[i].x, points[j].y - points[i].y)
                if d < maxEdgeDist {
                    gc.move(to: points[i])
                    gc.addLine(to: points[j])
                }
            }
        }
        gc.strokePath()

        // Bright highlight on some edges
        gc.setStrokeColor(UIColor.white.withAlphaComponent(0.08).cgColor)
        gc.setLineWidth(0.5)
        for i in 0..<points.count {
            for j in (i + 1)..<points.count {
                let d = hypot(points[j].x - points[i].x, points[j].y - points[i].y)
                if d < maxEdgeDist && rng.nextFloat() > 0.6 {
                    gc.move(to: CGPoint(x: points[i].x + 1, y: points[i].y + 1))
                    gc.addLine(to: CGPoint(x: points[j].x + 1, y: points[j].y + 1))
                }
            }
        }
        gc.strokePath()
    }

    // MARK: - Waves — concentric ripple rings

    private func drawWaves(gc: CGContext, rect: CGRect, palette: ColorPalette, complexity: Float, rng: inout SeededRNG)
    {
        let allColors = palette.cgColors + [palette.accentCGColor]

        // 1-3 ripple centers
        let centerCount = 1 + Int(rng.nextFloat() * 2)

        for c in 0..<centerCount {
            let cx = CGFloat(0.2 + rng.nextFloat() * 0.6) * rect.width
            let cy = CGFloat(0.2 + rng.nextFloat() * 0.6) * rect.height
            let center = CGPoint(x: cx, y: cy)
            let maxRadius = max(rect.width, rect.height) * CGFloat(0.6 + rng.nextFloat() * 0.4)

            let ringCount = 8 + Int(complexity * 15)
            let ringSpacing = maxRadius / CGFloat(ringCount)

            for i in 0..<ringCount {
                let radius = ringSpacing * CGFloat(i + 1)
                let colorIdx = (c + i) % allColors.count
                let color = UIColor(cgColor: allColors[colorIdx])

                // Rings get fainter as they expand
                let falloff = 1.0 - (CGFloat(i) / CGFloat(ringCount))
                let alpha = CGFloat(0.06 + complexity * 0.12) * falloff

                // Slight wobble for organic feel
                gc.saveGState()
                let scaleX = CGFloat(1.0 + (rng.nextFloat() - 0.5) * 0.15)
                let scaleY = CGFloat(1.0 + (rng.nextFloat() - 0.5) * 0.15)
                gc.translateBy(x: center.x, y: center.y)
                gc.scaleBy(x: scaleX, y: scaleY)
                gc.translateBy(x: -center.x, y: -center.y)

                let lineWidth = CGFloat(1.5 + complexity * 2.0) * falloff + 0.5
                gc.setStrokeColor(color.withAlphaComponent(alpha).cgColor)
                gc.setLineWidth(lineWidth)
                gc.strokeEllipse(
                    in: CGRect(
                        x: center.x - radius,
                        y: center.y - radius,
                        width: radius * 2,
                        height: radius * 2
                    )
                )
                gc.restoreGState()
            }
        }
    }

    // MARK: - Prism — refracted light streaks

    private func drawPrism(gc: CGContext, rect: CGRect, palette: ColorPalette, complexity: Float, rng: inout SeededRNG)
    {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let allColors = palette.cgColors + [palette.accentCGColor]

        // Rainbow-like spectral bars cutting diagonally
        let barCount = 5 + Int(complexity * 10)
        let baseAngle = CGFloat(rng.nextFloat()) * .pi * 0.4 + .pi * 0.1  // 10°–50°

        for i in 0..<barCount {
            let fraction = CGFloat(i) / CGFloat(barCount)
            let offset = rect.height * (0.05 + fraction * 0.9)
            let barWidth = rect.height * CGFloat(0.03 + rng.nextFloat() * 0.08)

            let colorIdx = i % allColors.count
            let barColor = UIColor(cgColor: allColors[colorIdx])
            let alpha = CGFloat(0.10 + rng.nextFloat() * 0.18)

            // Calculate bar as a parallelogram
            let dx = cos(baseAngle) * rect.width * 1.5
            let dy = sin(baseAngle) * rect.width * 1.5
            let perpX = -sin(baseAngle) * barWidth
            let perpY = cos(baseAngle) * barWidth

            let startX = -rect.width * 0.3
            let startY = offset

            let path = CGMutablePath()
            path.move(to: CGPoint(x: startX, y: startY))
            path.addLine(to: CGPoint(x: startX + dx, y: startY + dy))
            path.addLine(to: CGPoint(x: startX + dx + perpX, y: startY + dy + perpY))
            path.addLine(to: CGPoint(x: startX + perpX, y: startY + perpY))
            path.closeSubpath()

            // Gradient across the bar width for light-refraction look
            gc.saveGState()
            gc.addPath(path)
            gc.clip()

            let colors =
                [
                    barColor.withAlphaComponent(alpha * 0.2).cgColor,
                    barColor.withAlphaComponent(alpha).cgColor,
                    barColor.withAlphaComponent(alpha * 0.4).cgColor,
                    barColor.withAlphaComponent(0).cgColor,
                ] as CFArray

            if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 0.3, 0.7, 1]) {
                gc.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: startX, y: startY),
                    end: CGPoint(x: startX + perpX * 2, y: startY + perpY * 2),
                    options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
                )
            }
            gc.restoreGState()
        }

        // Central bright flare (prism source)
        let flareX = CGFloat(0.3 + rng.nextFloat() * 0.4) * rect.width
        let flareY = CGFloat(0.2 + rng.nextFloat() * 0.3) * rect.height
        let flareCenter = CGPoint(x: flareX, y: flareY)
        let flareRadius = CGFloat(0.08 + rng.nextFloat() * 0.12) * max(rect.width, rect.height)

        let flareColors =
            [
                UIColor.white.withAlphaComponent(0.20).cgColor,
                UIColor.white.withAlphaComponent(0.05).cgColor,
                UIColor.white.withAlphaComponent(0).cgColor,
            ] as CFArray

        if let gradient = CGGradient(colorsSpace: colorSpace, colors: flareColors, locations: [0, 0.4, 1]) {
            gc.drawRadialGradient(
                gradient,
                startCenter: flareCenter,
                startRadius: 0,
                endCenter: flareCenter,
                endRadius: flareRadius,
                options: []
            )
        }
    }

    // MARK: - Topography — contour-map elevation lines

    private func drawTopography(
        gc: CGContext,
        rect: CGRect,
        palette: ColorPalette,
        complexity: Float,
        rng: inout SeededRNG
    ) {
        let allColors = palette.cgColors + [palette.accentCGColor]

        // Generate a simple height field using overlapping sine functions
        let peaks = 3 + Int(rng.nextFloat() * 3)
        var peakData: [(cx: CGFloat, cy: CGFloat, radius: CGFloat, height: CGFloat)] = []
        for _ in 0..<peaks {
            peakData.append(
                (
                    cx: CGFloat(rng.nextFloat()) * rect.width,
                    cy: CGFloat(rng.nextFloat()) * rect.height,
                    radius: CGFloat(0.2 + rng.nextFloat() * 0.4) * max(rect.width, rect.height),
                    height: CGFloat(0.5 + rng.nextFloat() * 0.5)
                )
            )
        }

        func heightAt(_ x: CGFloat, _ y: CGFloat) -> CGFloat {
            var h: CGFloat = 0
            for peak in peakData {
                let d = hypot(x - peak.cx, y - peak.cy)
                let falloff = max(0, 1.0 - d / peak.radius)
                h += falloff * falloff * peak.height
            }
            return min(h, 1.0)
        }

        // Draw contour lines by marching across the grid
        let contourLevels = 10 + Int(complexity * 15)
        let step: CGFloat = 6  // grid resolution
        let cols = Int(rect.width / step)
        let rows = Int(rect.height / step)

        // Pre-compute height grid
        var grid: [[CGFloat]] = Array(repeating: Array(repeating: 0, count: cols + 1), count: rows + 1)
        for r in 0...rows {
            for c in 0...cols {
                grid[r][c] = heightAt(CGFloat(c) * step, CGFloat(r) * step)
            }
        }

        for level in 0..<contourLevels {
            let threshold = CGFloat(level + 1) / CGFloat(contourLevels + 1)
            let colorIdx = level % allColors.count
            let color = UIColor(cgColor: allColors[colorIdx])
            let alpha = CGFloat(0.12 + complexity * 0.15)

            gc.setStrokeColor(color.withAlphaComponent(alpha).cgColor)
            gc.setLineWidth(CGFloat(0.8 + complexity * 0.8))

            // Simple marching squares: find edges where height crosses threshold
            for r in 0..<rows {
                for c in 0..<cols {
                    let tl = grid[r][c]
                    let tr = grid[r][c + 1]
                    let bl = grid[r + 1][c]
                    let br = grid[r + 1][c + 1]

                    let x0 = CGFloat(c) * step
                    let y0 = CGFloat(r) * step

                    // Check each edge for threshold crossing
                    var segments: [(CGPoint, CGPoint)] = []

                    func lerp(_ a: CGFloat, _ b: CGFloat, _ va: CGFloat, _ vb: CGFloat) -> CGFloat {
                        guard abs(vb - va) > 0.001 else { return 0.5 }
                        return (threshold - va) / (vb - va)
                    }

                    let topCross = (tl < threshold) != (tr < threshold)
                    let bottomCross = (bl < threshold) != (br < threshold)
                    let leftCross = (tl < threshold) != (bl < threshold)
                    let rightCross = (tr < threshold) != (br < threshold)

                    var crossPoints: [CGPoint] = []

                    if topCross {
                        let t = lerp(x0, x0 + step, tl, tr)
                        crossPoints.append(CGPoint(x: x0 + t * step, y: y0))
                    }
                    if bottomCross {
                        let t = lerp(x0, x0 + step, bl, br)
                        crossPoints.append(CGPoint(x: x0 + t * step, y: y0 + step))
                    }
                    if leftCross {
                        let t = lerp(y0, y0 + step, tl, bl)
                        crossPoints.append(CGPoint(x: x0, y: y0 + t * step))
                    }
                    if rightCross {
                        let t = lerp(y0, y0 + step, tr, br)
                        crossPoints.append(CGPoint(x: x0 + step, y: y0 + t * step))
                    }

                    if crossPoints.count >= 2 {
                        gc.move(to: crossPoints[0])
                        gc.addLine(to: crossPoints[1])
                    }
                    if crossPoints.count == 4 {
                        gc.move(to: crossPoints[2])
                        gc.addLine(to: crossPoints[3])
                    }
                }
            }
            gc.strokePath()
        }
    }

    // MARK: - Layer 4: Light leak

    private func drawLightLeak(gc: CGContext, rect: CGRect, mood: GeneratorMood, rng: inout SeededRNG) {
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        let (cx, cy, warmth): (CGFloat, CGFloat, UIColor) =
            switch mood {
            case .calm:
                (
                    rect.width * 0.7, rect.height * 0.2,
                    UIColor(red: 1.0, green: 0.95, blue: 0.85, alpha: 1)
                )
            case .hopeful:
                (
                    rect.width * 0.3, rect.height * 0.15,
                    UIColor(red: 1.0, green: 0.92, blue: 0.75, alpha: 1)
                )
            case .focused:
                (
                    rect.midX, rect.height * 0.1,
                    UIColor(red: 0.9, green: 0.92, blue: 1.0, alpha: 1)
                )
            case .energized:
                (
                    rect.width * 0.8, rect.height * 0.3,
                    UIColor(red: 1.0, green: 0.85, blue: 0.65, alpha: 1)
                )
            case .dreamy:
                (
                    rect.width * 0.4, rect.height * 0.25,
                    UIColor(red: 0.92, green: 0.85, blue: 1.0, alpha: 1)
                )
            }

        let center = CGPoint(x: cx, y: cy)
        let radius = max(rect.width, rect.height) * 0.5

        let colors =
            [
                warmth.withAlphaComponent(0.12).cgColor,
                warmth.withAlphaComponent(0.04).cgColor,
                warmth.withAlphaComponent(0).cgColor,
            ] as CFArray

        if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 0.35, 1]) {
            gc.drawRadialGradient(
                gradient,
                startCenter: center,
                startRadius: 0,
                endCenter: center,
                endRadius: radius,
                options: []
            )
        }
    }

    // MARK: - Layer 5: Film grain

    private func drawGrain(gc: CGContext, rect: CGRect, rng: inout SeededRNG) {
        let dotCount = 3000
        for _ in 0..<dotCount {
            let x = CGFloat(rng.nextFloat()) * rect.width
            let y = CGFloat(rng.nextFloat()) * rect.height
            let bright = rng.nextFloat() > 0.5
            let alpha = CGFloat(0.015 + rng.nextFloat() * 0.025)

            gc.setFillColor(
                (bright ? UIColor.white : UIColor.black)
                    .withAlphaComponent(alpha).cgColor
            )
            gc.fill(CGRect(x: x, y: y, width: 1, height: 1))
        }
    }

    // MARK: - File management

    private func saveImage(_ image: UIImage, themeId: String) throws -> (URL, URL) {
        let dir = generatedThemesDirectory()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let imagePath = dir.appendingPathComponent("\(themeId).png")
        let thumbPath = dir.appendingPathComponent("\(themeId)_thumb.jpg")

        guard let pngData = image.pngData() else {
            throw BackgroundGeneratorError.generationFailed("Could not encode image")
        }
        try pngData.write(to: imagePath)

        let thumbSize = CGSize(width: 256, height: 256)
        let thumbRenderer = UIGraphicsImageRenderer(size: thumbSize)
        let thumbData = thumbRenderer.jpegData(withCompressionQuality: 0.8) { ctx in
            image.draw(in: CGRect(origin: .zero, size: thumbSize))
        }
        try thumbData.write(to: thumbPath)

        return (imagePath, thumbPath)
    }

    private func generatedThemesDirectory() -> URL {
        if let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.gragera.lumen"
        ) {
            return container.appendingPathComponent("themes/generated")
        }
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("themes/generated")
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
