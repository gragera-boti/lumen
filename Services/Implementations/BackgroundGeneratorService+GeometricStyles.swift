import UIKit

// MARK: - BackgroundGeneratorService + Geometric Styles & Overlays

extension BackgroundGeneratorService {

    // MARK: - Geometric — tessellated crystal facets

    func drawGeometric(
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

    func drawWatercolor(
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

    func drawStainedGlass(
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

            let sorted = points.enumerated()
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

    func drawWaves(gc: CGContext, rect: CGRect, palette: ColorPalette, complexity: Float, rng: inout SeededRNG) {
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
                // Dramatically increase alpha and contrast
                let alpha = CGFloat(0.3 + complexity * 0.4) * falloff

                // Slight wobble for organic feel
                gc.saveGState()
                let scaleX = CGFloat(1.0 + (rng.nextFloat() - 0.5) * 0.15)
                let scaleY = CGFloat(1.0 + (rng.nextFloat() - 0.5) * 0.15)
                gc.translateBy(x: center.x, y: center.y)
                gc.scaleBy(x: scaleX, y: scaleY)
                gc.translateBy(x: -center.x, y: -center.y)

                // Increased edge thickness for contrast
                let lineWidth = CGFloat(2.5 + complexity * 4.0) * falloff + 1.0
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

    func drawPrism(gc: CGContext, rect: CGRect, palette: ColorPalette, complexity: Float, rng: inout SeededRNG) {
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

    func drawTopography(
        gc: CGContext,
        rect: CGRect,
        palette: ColorPalette,
        complexity: Float,
        rng: inout SeededRNG,
        seed: UInt32
    ) {
        let allColors = palette.cgColors + [palette.accentCGColor]
        let noise = NoiseUtility(seed: seed)

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

        // Pre-compute height grid with added noise for rugged topography
        var grid: [[CGFloat]] = Array(repeating: Array(repeating: 0, count: cols + 1), count: rows + 1)
        for r in 0...rows {
            for c in 0...cols {
                let x = CGFloat(c) * step
                let y = CGFloat(r) * step
                let baseHeight = heightAt(x, y)
                // Add noise
                let n = CGFloat(noise.fbm(x: Double(x) * 0.005, y: Double(y) * 0.005))
                grid[r][c] = min(max(baseHeight + (n - 0.5) * 0.4, 0.0), 1.0)
            }
        }

        for level in 0..<contourLevels {
            let threshold = CGFloat(level + 1) / CGFloat(contourLevels + 1)
            let colorIdx = level % allColors.count
            let color = UIColor(cgColor: allColors[colorIdx])
            // Drastically higher opacity and width for impact
            let alpha = CGFloat(0.40 + complexity * 0.40)

            gc.setStrokeColor(color.withAlphaComponent(alpha).cgColor)
            gc.setLineWidth(CGFloat(1.5 + complexity * 1.5))

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

}
