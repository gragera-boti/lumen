import Foundation

/// A fast, lightweight implementation of Simple / Perlin-like Noise in pure Swift.
/// Used for generating organic, fluid-like backgrounds (e.g. flow fields, topography, mist).
struct NoiseUtility: Sendable {
    private let perm: [Int]

    init(seed: UInt32) {
        var rng = LCG(seed: seed)
        var p = [Int](0..<256)
        p.shuffle(using: &rng)
        self.perm = p + p // Duplicate array to avoid modulo operations
    }

    // 2D Simplex/Perlin-like Noise implementation
    func noise2D(x: Double, y: Double) -> Double {
        let x0 = floor(x)
        let y0 = floor(y)
        
        let ix = Int(x0) & 255
        let iy = Int(y0) & 255
        
        let fx = x - x0
        let fy = y - y0
        
        let u = fade(fx)
        let v = fade(fy)
        
        let a = perm[ix] + iy
        let b = perm[ix + 1] + iy
        
        let aa = perm[a % 512]
        let ab = perm[(a + 1) % 512]
        let ba = perm[b % 512]
        let bb = perm[(b + 1) % 512]
        
        // Final blend
        let res = lerp(
            lerp(grad(perm[aa], x: fx, y: fy), grad(perm[ba], x: fx - 1, y: fy), t: u),
            lerp(grad(perm[ab], x: fx, y: fy - 1), grad(perm[bb], x: fx - 1, y: fy - 1), t: u),
            t: v
        )
        // Normalize roughly to [0, 1] range rather than [-1, 1] for easier color mapping
        return (res + 1.0) / 2.0
    }

    // Fractional Brownian Motion (fBm) - Multiple octaves of noise for detail
    func fbm(x: Double, y: Double, octaves: Int = 4, persistence: Double = 0.5, lacunarity: Double = 2.0) -> Double {
        var total: Double = 0.0
        var frequency: Double = 1.0
        var amplitude: Double = 1.0
        var maxValue: Double = 0.0  // Used for normalizing result to 0.0 - 1.0

        for _ in 0..<octaves {
            total += noise2D(x: x * frequency, y: y * frequency) * amplitude

            maxValue += amplitude

            amplitude *= persistence
            frequency *= lacunarity
        }

        return total / maxValue
    }

    private func fade(_ t: Double) -> Double {
        return t * t * t * (t * (t * 6 - 15) + 10)
    }

    private func lerp(_ a: Double, _ b: Double, t: Double) -> Double {
        return a + t * (b - a)
    }

    private func grad(_ hash: Int, x: Double, y: Double) -> Double {
        let h = hash & 15
        let u = h < 8 ? x : y
        let v = h < 4 ? y : h == 12 || h == 14 ? x : 0.0
        return ((h & 1) == 0 ? u : -u) + ((h & 2) == 0 ? v : -v)
    }
}

// Simple deterministic random number generator for scrambling the permutation table
private struct LCG: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt32) {
        state = UInt64(seed)
    }
    mutating func next() -> UInt64 {
        state = 6364136223846793005 &* state &+ 1442695040888963407
        return state
    }
}
