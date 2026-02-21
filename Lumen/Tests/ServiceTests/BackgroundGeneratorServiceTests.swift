import XCTest
@testable import Lumen

@MainActor
final class BackgroundGeneratorServiceTests: XCTestCase {
    private let service = BackgroundGeneratorService.shared

    // MARK: - Generation

    func test_generate_producesImage() async throws {
        let request = BackgroundRequest(
            style: .aurora,
            palette: .oceanBreeze,
            mood: .calm,
            complexity: 0.5
        )

        let result = try await service.generate(request: request)

        XCTAssertFalse(result.themeId.isEmpty)
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.imagePath.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.thumbnailPath.path))
        XCTAssertTrue(result.metadata.durationMs >= 0)
        XCTAssertEqual(result.metadata.style, "aurora")
        XCTAssertEqual(result.metadata.palette, "oceanBreeze")

        try? FileManager.default.removeItem(at: result.imagePath)
        try? FileManager.default.removeItem(at: result.thumbnailPath)
    }

    func test_generate_allStyleCombinations() async throws {
        for style in GeneratorStyle.allCases {
            let request = BackgroundRequest(
                style: style,
                palette: .warmFlame,
                mood: .calm,
                complexity: 0.5
            )

            let result = try await service.generate(request: request)
            XCTAssertTrue(
                FileManager.default.fileExists(atPath: result.imagePath.path),
                "Failed for style: \(style.rawValue)"
            )

            try? FileManager.default.removeItem(at: result.imagePath)
            try? FileManager.default.removeItem(at: result.thumbnailPath)
        }
    }

    func test_generate_allPalettes() async throws {
        for palette in ColorPalette.allCases {
            let request = BackgroundRequest(
                style: .bokeh,
                palette: palette,
                mood: .hopeful,
                complexity: 0.7
            )

            let result = try await service.generate(request: request)
            XCTAssertTrue(
                FileManager.default.fileExists(atPath: result.imagePath.path),
                "Failed for palette: \(palette.rawValue)"
            )

            try? FileManager.default.removeItem(at: result.imagePath)
            try? FileManager.default.removeItem(at: result.thumbnailPath)
        }
    }

    func test_generate_allMoods() async throws {
        for mood in GeneratorMood.allCases {
            let request = BackgroundRequest(
                style: .mist,
                palette: .nightFade,
                mood: mood,
                complexity: 0.5
            )

            let result = try await service.generate(request: request)
            XCTAssertTrue(
                FileManager.default.fileExists(atPath: result.imagePath.path),
                "Failed for mood: \(mood.rawValue)"
            )

            try? FileManager.default.removeItem(at: result.imagePath)
            try? FileManager.default.removeItem(at: result.thumbnailPath)
        }
    }

    func test_generate_newStyles() async throws {
        let newStyles: [GeneratorStyle] = [.geometric, .watercolor, .stainedGlass, .waves, .prism, .topography]

        for style in newStyles {
            let request = BackgroundRequest(
                style: style,
                palette: .electric,
                mood: .energized,
                complexity: 0.8
            )

            let result = try await service.generate(request: request)
            XCTAssertTrue(
                FileManager.default.fileExists(atPath: result.imagePath.path),
                "Failed for new style: \(style.rawValue)"
            )
            XCTAssertEqual(result.metadata.style, style.rawValue)

            try? FileManager.default.removeItem(at: result.imagePath)
            try? FileManager.default.removeItem(at: result.thumbnailPath)
        }
    }

    func test_generate_seedReproducibility() async throws {
        let request = BackgroundRequest(
            style: .dunes,
            palette: .nightFade,
            mood: .focused,
            complexity: 0.3,
            seed: 42
        )

        let result1 = try await service.generate(request: request)
        let result2 = try await service.generate(request: request)

        let data1 = try Data(contentsOf: result1.imagePath)
        let data2 = try Data(contentsOf: result2.imagePath)

        XCTAssertEqual(data1, data2, "Same seed should produce identical images")

        try? FileManager.default.removeItem(at: result1.imagePath)
        try? FileManager.default.removeItem(at: result1.thumbnailPath)
        try? FileManager.default.removeItem(at: result2.imagePath)
        try? FileManager.default.removeItem(at: result2.thumbnailPath)
    }

    func test_cancelGeneration_doesNotCrash() {
        service.cancelGeneration()
    }

    // MARK: - Color palettes

    func test_allPalettes_haveThreeColors() {
        for palette in ColorPalette.allCases {
            XCTAssertEqual(palette.cgColors.count, 3, "\(palette.rawValue) should have 3 colors")
        }
    }

    func test_allPalettes_haveAccentColor() {
        for palette in ColorPalette.allCases {
            XCTAssertNotNil(palette.accentCGColor, "\(palette.rawValue) should have accent")
        }
    }

    func test_newPalettes_exist() {
        let newPalettes: [ColorPalette] = [.cherry, .auroraGreen, .desert, .sakura, .electric, .slate]
        for palette in newPalettes {
            XCTAssertEqual(palette.cgColors.count, 3)
        }
    }

    // MARK: - Seeded RNG

    func test_seededRNG_deterministic() {
        var rng1 = SeededRNG(seed: 123)
        var rng2 = SeededRNG(seed: 123)

        for _ in 0..<100 {
            XCTAssertEqual(rng1.next(), rng2.next())
        }
    }

    func test_seededRNG_differentSeeds() {
        var rng1 = SeededRNG(seed: 1)
        var rng2 = SeededRNG(seed: 2)

        XCTAssertNotEqual(rng1.next(), rng2.next())
    }
}
