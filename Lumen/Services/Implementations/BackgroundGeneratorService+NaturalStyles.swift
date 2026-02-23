import UIKit

// MARK: - BackgroundGeneratorService + Base Layers & Natural Styles

extension BackgroundGeneratorService {

    // MARK: - Layer 1: Base gradient

    func drawBaseGradient(
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

    func drawGlowOrbs(
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

    func drawAurora(gc: CGContext, rect: CGRect, palette: ColorPalette, complexity: Float, rng: inout SeededRNG) {
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

    func drawBokeh(gc: CGContext, rect: CGRect, palette: ColorPalette, complexity: Float, rng: inout SeededRNG) {
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

    func drawMist(gc: CGContext, rect: CGRect, palette: ColorPalette, complexity: Float, rng: inout SeededRNG) {
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

    func drawDunes(gc: CGContext, rect: CGRect, palette: ColorPalette, complexity: Float, rng: inout SeededRNG) {
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

    func drawCosmos(gc: CGContext, rect: CGRect, palette: ColorPalette, complexity: Float, rng: inout SeededRNG) {
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

}
