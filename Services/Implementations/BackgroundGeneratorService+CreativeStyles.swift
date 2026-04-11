import UIKit

// MARK: - BackgroundGeneratorService + Advanced Algorithmic Styles

extension BackgroundGeneratorService {

    // MARK: - Ethereal Flow (Flow Field)
    func drawEtherealFlow(gc: CGContext, rect: CGRect, palette: ColorPalette, complexity: Float, rng: inout SeededRNG, seed: UInt32) {
        let noise = NoiseUtility(seed: seed)
        let particleCount = 3000 + Int(complexity * 4000)
        let allColors = palette.cgColors + [palette.accentCGColor]

        for i in 0..<particleCount {
            var x = Double(rng.nextFloat()) * rect.width
            var y = Double(rng.nextFloat()) * rect.height
            
            let isHighlight = i % 20 == 0
            
            let colorIdx = Int(rng.next() % UInt64(allColors.count))
            let color = isHighlight ? UIColor.white : UIColor(cgColor: allColors[colorIdx])
            
            // Higher opacity for much sharper look
            let alpha = isHighlight ? (0.5 + rng.nextFloat() * 0.4) : (0.1 + rng.nextFloat() * 0.2)
            gc.setStrokeColor(color.withAlphaComponent(CGFloat(alpha)).cgColor)
            gc.setLineWidth(CGFloat(isHighlight ? 1.5 : 0.8 + complexity * 1.5))
            
            gc.beginPath()
            gc.move(to: CGPoint(x: x, y: y))
            
            // Step through field
            let steps = 20 + Int(rng.nextFloat() * 30)
            for _ in 0..<steps {
                let angle = noise.fbm(x: x * 0.003, y: y * 0.003) * .pi * 4.0
                x += cos(angle) * 5.0
                y += sin(angle) * 5.0
                gc.addLine(to: CGPoint(x: x, y: y))
            }
            gc.strokePath()
        }
    }

    // MARK: - Neural Growth (Reaction Diffusion simulation approximation)
    func drawNeuralGrowth(gc: CGContext, rect: CGRect, palette: ColorPalette, complexity: Float, rng: inout SeededRNG, seed: UInt32) {
        let noise = NoiseUtility(seed: seed)
        let blobCount = 50 + Int(complexity * 100)
        let allColors = palette.cgColors + [palette.accentCGColor]
        
        for i in 0..<blobCount {
            let x = Double(rng.nextFloat()) * rect.width
            let y = Double(rng.nextFloat()) * rect.height
            
            let baseSize = Double(10 + rng.nextFloat() * 40)
            
            let path = CGMutablePath()
            let segments = 20
            
            for s in 0...segments {
                let angle = (Double(s) / Double(segments)) * .pi * 2.0
                
                // Use noise to warp the radius
                let n = noise.fbm(x: x + cos(angle) * 2.0, y: y + sin(angle) * 2.0)
                let radius = baseSize + (n * baseSize * 1.5)
                
                let px = x + cos(angle) * radius
                let py = y + sin(angle) * radius
                
                if s == 0 {
                    path.move(to: CGPoint(x: px, y: py))
                } else {
                    path.addLine(to: CGPoint(x: px, y: py))
                }
            }
            path.closeSubpath()
            
            let color = UIColor(cgColor: allColors[i % allColors.count])
            gc.setFillColor(color.withAlphaComponent(CGFloat(0.1 + rng.nextFloat() * 0.2)).cgColor)
            gc.addPath(path)
            gc.fillPath()
            
            gc.setStrokeColor(color.withAlphaComponent(CGFloat(0.3 + rng.nextFloat() * 0.2)).cgColor)
            gc.setLineWidth(1.0)
            gc.addPath(path)
            gc.strokePath()
        }
    }

    // MARK: - Symmetry Harmony (Hypotrochoids)
    func drawHarmony(gc: CGContext, rect: CGRect, palette: ColorPalette, complexity: Float, rng: inout SeededRNG) {
        let allColors = palette.cgColors + [palette.accentCGColor]
        let loopCount = 3 + Int(complexity * 4)
        
        for i in 0..<loopCount {
            let cx = rect.midX + CGFloat(rng.nextFloat() - 0.5) * rect.width * 0.4
            let cy = rect.midY + CGFloat(rng.nextFloat() - 0.5) * rect.height * 0.4
            
            let R = Double(100 + rng.nextFloat() * 150)
            let r = Double(20 + rng.nextFloat() * 80)
            let d = Double(30 + rng.nextFloat() * 100)
            
            let color = UIColor(cgColor: allColors[i % allColors.count])
            gc.setStrokeColor(color.withAlphaComponent(CGFloat(0.15 + complexity * 0.15)).cgColor)
            gc.setLineWidth(CGFloat(0.5 + complexity * 1.0))
            
            gc.beginPath()
            var first = true
            
            // Draw an orbital path
            // Usually hypotrochoids loop fully after lcm(R,r) rotations, using large steps here
            for t in stride(from: 0.0, to: .pi * 40.0, by: 0.05) {
                let x = (R - r) * cos(t) + d * cos(((R - r) / r) * t)
                let y = (R - r) * sin(t) - d * sin(((R - r) / r) * t)
                
                let px = cx + CGFloat(x)
                let py = cy + CGFloat(y)
                
                if first {
                    gc.move(to: CGPoint(x: px, y: py))
                    first = false
                } else {
                    gc.addLine(to: CGPoint(x: px, y: py))
                }
            }
            gc.strokePath()
        }
    }

    // MARK: - Crystalline Shards (Advanced Voronoi Layers)
    func drawShards(gc: CGContext, rect: CGRect, palette: ColorPalette, complexity: Float, rng: inout SeededRNG) {
        let allColors = palette.cgColors + [palette.accentCGColor]
        // Simple faux-voronoi by drawing many intersecting angular shards
        let shardCount = 40 + Int(complexity * 80)
        
        for i in 0..<shardCount {
            let path = CGMutablePath()
            let cx = CGFloat(rng.nextFloat()) * rect.width
            let cy = CGFloat(rng.nextFloat()) * rect.height
            
            let pointsCount = 3 + Int(rng.nextFloat() * 3) // Triangles, quads, pentagons
            let radius = CGFloat(20 + rng.nextFloat() * 120)
            
            var first = true
            for p in 0..<pointsCount {
                let angle = (CGFloat(p) / CGFloat(pointsCount)) * .pi * 2 + CGFloat(rng.nextFloat())
                let r = radius * CGFloat(0.5 + rng.nextFloat() * 0.5)
                
                let px = cx + cos(angle) * r
                let py = cy + sin(angle) * r
                
                if first {
                    path.move(to: CGPoint(x: px, y: py))
                    first = false
                } else {
                    path.addLine(to: CGPoint(x: px, y: py))
                }
            }
            path.closeSubpath()
            
            let color = UIColor(cgColor: allColors[i % allColors.count])
            gc.setFillColor(color.withAlphaComponent(CGFloat(0.05 + rng.nextFloat() * 0.15)).cgColor)
            gc.addPath(path)
            gc.fillPath()
            
            // Draw rim
            gc.setStrokeColor(UIColor.white.withAlphaComponent(CGFloat(0.1 + rng.nextFloat() * 0.2)).cgColor)
            gc.setLineWidth(0.5)
            gc.addPath(path)
            gc.strokePath()
        }
    }

    // MARK: - Hyphae (Branching attraction)
    func drawHyphae(gc: CGContext, rect: CGRect, palette: ColorPalette, complexity: Float, rng: inout SeededRNG, seed: UInt32) {
        let noise = NoiseUtility(seed: seed)
        let allColors = palette.cgColors + [palette.accentCGColor]
        
        // Root system growing downward / outward
        let roots = 3 + Int(complexity * 4)
        
        for i in 0..<roots {
            var x = Double(rng.nextFloat()) * rect.width
            var y = rect.height * Double(rng.nextFloat() * 0.3) // start in top third
            
            let color = UIColor(cgColor: allColors[i % allColors.count])
            
            recursiveBranch(gc: gc, x: x, y: y, angle: .pi / 2, depth: 0, maxDepth: 4 + Int(complexity * 3), length: Double(rect.height * 0.15), noise: noise, color: color, rng: &rng)
        }
    }
    
    private func recursiveBranch(gc: CGContext, x: Double, y: Double, angle: Double, depth: Int, maxDepth: Int, length: Double, noise: NoiseUtility, color: UIColor, rng: inout SeededRNG) {
        if depth > maxDepth { return }
        
        let n = noise.noise2D(x: x * 0.01, y: y * 0.01)
        let modifiedAngle = angle + (n - 0.5) * .pi * 0.8
        
        let nx = x + cos(modifiedAngle) * length
        let ny = y + sin(modifiedAngle) * length
        
        gc.setStrokeColor(color.withAlphaComponent(CGFloat(0.4 - Double(depth) * 0.05)).cgColor)
        gc.setLineWidth(CGFloat(maxDepth - depth) * 1.5)
        
        gc.beginPath()
        gc.move(to: CGPoint(x: x, y: y))
        gc.addLine(to: CGPoint(x: nx, y: ny))
        gc.strokePath()
        
        // Branching
        let branches = 1 + Int(rng.nextFloat() * 3) // 1 to 3 branches
        for _ in 0..<branches {
            recursiveBranch(gc: gc, x: nx, y: ny, angle: modifiedAngle + Double(rng.nextFloat() - 0.5) * .pi * 0.6, depth: depth + 1, maxDepth: maxDepth, length: length * (0.6 + Double(rng.nextFloat() * 0.3)), noise: noise, color: color, rng: &rng)
        }
    }

    // MARK: - Julia Nebula
    func drawJuliaNebula(gc: CGContext, rect: CGRect, palette: ColorPalette, complexity: Float, rng: inout SeededRNG) {
        let allColors = palette.cgColors + [palette.accentCGColor]
        
        // Extremely simplified "fractal cloud" using recursive layered circles instead of a true pixel shader
        // (A true Julia map per-pixel would be wildly slow in CoreGraphics - this is a vector approximation)
        let clusterCount = 10 + Int(complexity * 20)
        
        for i in 0..<clusterCount {
            let cx = CGFloat(rng.nextFloat()) * rect.width
            let cy = CGFloat(rng.nextFloat()) * rect.height
            let color = UIColor(cgColor: allColors[i % allColors.count])
            
            drawFractalCluster(gc: gc, x: cx, y: cy, radius: CGFloat(40 + rng.nextFloat() * 100), depth: 0, maxDepth: 3, color: color, rng: &rng)
        }
    }
    
    private func drawFractalCluster(gc: CGContext, x: CGFloat, y: CGFloat, radius: CGFloat, depth: Int, maxDepth: Int, color: UIColor, rng: inout SeededRNG) {
        if depth > maxDepth { return }
        
        let alpha = CGFloat(0.1 + (1.0 - CGFloat(depth)/CGFloat(maxDepth)) * 0.2)
        gc.setFillColor(color.withAlphaComponent(alpha).cgColor)
        gc.fillEllipse(in: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))
        
        // Satellite clusters
        let sats = 2 + Int(rng.nextFloat() * 3)
        for _ in 0..<sats {
            let angle = CGFloat(rng.nextFloat()) * .pi * 2
            let dist = radius * CGFloat(0.8 + rng.nextFloat() * 0.6)
            let sr = radius * CGFloat(0.3 + rng.nextFloat() * 0.4)
            
            drawFractalCluster(gc: gc, x: x + cos(angle) * dist, y: y + sin(angle) * dist, radius: sr, depth: depth + 1, maxDepth: maxDepth, color: color, rng: &rng)
        }
    }
    
    // MARK: - CoreGraphics Implementations of Metal Styles
    
    func drawLiquidWarp(gc: CGContext, rect: CGRect, palette: ColorPalette, complexity: Float, rng: inout SeededRNG, seed: UInt32) {
        let noise = NoiseUtility(seed: seed)
        let allColors = palette.cgColors + [palette.accentCGColor]
        
        let pathCount = 30 + Int(complexity * 50)
        gc.setBlendMode(.overlay)
        
        for k in 0..<pathCount {
            let path = CGMutablePath()
            var first = true
            let yBase = Double(k) / Double(pathCount) * rect.height
            
            for x in stride(from: 0.0, through: Double(rect.width), by: 5.0) {
                // Domain warped
                let qx = noise.fbm(x: x * 0.005, y: yBase * 0.005)
                let qy = noise.fbm(x: x * 0.005 + 10, y: yBase * 0.005 + 10)
                let n = noise.fbm(x: x * 0.002 + qx * 50, y: yBase * 0.002 + qy * 50)
                
                let py = yBase + (n - 0.5) * 400.0
                if first {
                    path.move(to: CGPoint(x: x, y: py))
                    first = false
                } else {
                    path.addLine(to: CGPoint(x: x, y: py))
                }
            }
            
            let color = UIColor(cgColor: allColors[k % allColors.count])
            gc.setStrokeColor(color.withAlphaComponent(0.2).cgColor)
            gc.setLineWidth(CGFloat(10 + rng.nextFloat() * 40))
            gc.addPath(path)
            gc.strokePath()
        }
    }

    func drawMetaballs(gc: CGContext, rect: CGRect, palette: ColorPalette, complexity: Float, rng: inout SeededRNG, seed: UInt32) {
        let allColors = palette.cgColors + [palette.accentCGColor]
        let blobCount = 15 + Int(complexity * 15)
        
        gc.setBlendMode(.screen)
        
        for i in 0..<blobCount {
            let cx = CGFloat(rng.nextFloat()) * rect.width
            let cy = CGFloat(rng.nextFloat()) * rect.height
            let radius = CGFloat(100 + rng.nextFloat() * 300)
            
            let color = UIColor(cgColor: allColors[i % allColors.count])
            
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colors = [color.withAlphaComponent(0.6).cgColor, color.withAlphaComponent(0.0).cgColor] as CFArray
            let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 1.0])!
            
            gc.drawRadialGradient(gradient, startCenter: CGPoint(x: cx, y: cy), startRadius: 0, endCenter: CGPoint(x: cx, y: cy), endRadius: radius, options: .drawsBeforeStartLocation)
        }
    }

    func drawNebula(gc: CGContext, rect: CGRect, palette: ColorPalette, complexity: Float, rng: inout SeededRNG, seed: UInt32) {
        let allColors = palette.cgColors + [palette.accentCGColor]
        let layerCount = 10 + Int(complexity * 10)
        
        // Draw cloud puffs
        for i in 0..<layerCount {
            let cx = CGFloat(rng.nextFloat()) * rect.width
            let cy = CGFloat(rng.nextFloat()) * rect.height
            let radius = CGFloat(200 + rng.nextFloat() * 400)
            
            let color = UIColor(cgColor: allColors[i % allColors.count])
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colors = [color.withAlphaComponent(CGFloat(0.1 + rng.nextFloat() * 0.15)).cgColor, UIColor.clear.cgColor] as CFArray
            let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 1.0])!
            
            gc.setBlendMode(rng.nextFloat() > 0.5 ? .screen : .overlay)
            gc.drawRadialGradient(gradient, startCenter: CGPoint(x: cx, y: cy), startRadius: 0, endCenter: CGPoint(x: cx, y: cy), endRadius: radius, options: .drawsBeforeStartLocation)
        }
        
        // Draw stars
        gc.setBlendMode(.normal)
        let starCount = 300 + Int(complexity * 500)
        gc.setFillColor(UIColor.white.cgColor)
        for _ in 0..<starCount {
            let x = CGFloat(rng.nextFloat()) * rect.width
            let y = CGFloat(rng.nextFloat()) * rect.height
            let s = CGFloat(1.0 + rng.nextFloat() * 2.0)
            gc.fillEllipse(in: CGRect(x: x, y: y, width: s, height: s))
        }
    }

    func drawIridescence(gc: CGContext, rect: CGRect, palette: ColorPalette, complexity: Float, rng: inout SeededRNG, seed: UInt32) {
        let noise = NoiseUtility(seed: seed)
        let steps = 100 + Int(complexity * 100)
        let allColors = palette.cgColors + [palette.accentCGColor]
        
        for k in 0..<steps {
            let y = Double(k) / Double(steps) * rect.height
            
            let path = CGMutablePath()
            var first = true
            
            for x in stride(from: 0.0, through: Double(rect.width), by: 2.0) {
                let n1 = noise.fbm(x: x * 0.01, y: y * 0.01)
                
                // Interference waves
                let interference = sin(n1 * 20.0 + x * 0.02 + y * 0.01)
                
                let py = y + interference * 50.0
                if first {
                    path.move(to: CGPoint(x: x, y: py))
                    first = false
                } else {
                    path.addLine(to: CGPoint(x: x, y: py))
                }
            }
            
            let colorIdx = Int(rng.next() % UInt64(allColors.count))
            let nextColorIdx = (colorIdx + 1) % allColors.count
            
            let color = UIColor(cgColor: allColors[colorIdx])
            let color2 = UIColor(cgColor: allColors[nextColorIdx])
            
            let blColor = color.mixed(with: color2, by: CGFloat(k) / CGFloat(steps)) ?? color
            
            gc.setStrokeColor(blColor.withAlphaComponent(0.15).cgColor)
            gc.setLineWidth(5.0)
            gc.addPath(path)
            gc.strokePath()
        }
    }
}

// Helper for Iridescence
extension UIColor {
    func mixed(with other: UIColor, by amount: CGFloat) -> UIColor? {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        
        guard self.getRed(&r1, green: &g1, blue: &b1, alpha: &a1) else { return nil }
        guard other.getRed(&r2, green: &g2, blue: &b2, alpha: &a2) else { return nil }
        
        return UIColor(
            red: r1 * (1.0 - amount) + r2 * amount,
            green: g1 * (1.0 - amount) + g2 * amount,
            blue: b1 * (1.0 - amount) + b2 * amount,
            alpha: a1 * (1.0 - amount) + a2 * amount
        )
    }
}
