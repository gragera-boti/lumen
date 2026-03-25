import UIKit

// MARK: - BackgroundGeneratorService + Overlays & File Management

extension BackgroundGeneratorService {

    // MARK: - Layer 4: Light leak

    func drawLightLeak(gc: CGContext, rect: CGRect, mood: GeneratorMood, rng: inout SeededRNG) {
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

    func drawGrain(gc: CGContext, rect: CGRect, rng: inout SeededRNG) {
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

    func saveImage(_ image: UIImage, themeId: String) throws -> (URL, URL) {
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

    func generatedThemesDirectory() -> URL {
        if let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.gragera.lumen"
        ) {
            return container.appendingPathComponent("themes/generated")
        }
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return appSupport.appendingPathComponent("themes/generated")
    }
}
