import Foundation
import Testing

@testable import Lumen

@Suite("BackgroundGeneratorService Tests")
@MainActor struct BackgroundGeneratorServiceTests {
    private let service = BackgroundGeneratorService.shared

    // MARK: - Generation

    @Test("generate produces image")
    func generate_producesImage() async throws {
        let request = BackgroundRequest(
            style: .aurora,
            palette: .oceanBreeze,
            mood: .calm,
            complexity: 0.5
        )

        let result = try await service.generate(request: request)

        #expect(!result.themeId.isEmpty)
        #expect(FileManager.default.fileExists(atPath: result.imagePath.path))
        #expect(FileManager.default.fileExists(atPath: result.thumbnailPath.path))
        #expect(result.metadata.durationMs >= 0)
        #expect(result.metadata.style == "aurora")
        #expect(result.metadata.palette == "oceanBreeze")

        try? FileManager.default.removeItem(at: result.imagePath)
        try? FileManager.default.removeItem(at: result.thumbnailPath)
    }

    @Test("generate all style combinations")
    func generate_allStyleCombinations() async throws {
        for style in GeneratorStyle.allCases {
            let request = BackgroundRequest(
                style: style,
                palette: .warmFlame,
                mood: .calm,
                complexity: 0.5
            )

            let result = try await service.generate(request: request)
            #expect(
                FileManager.default.fileExists(atPath: result.imagePath.path),
                "Failed for style: \(style.rawValue)"
            )

            try? FileManager.default.removeItem(at: result.imagePath)
            try? FileManager.default.removeItem(at: result.thumbnailPath)
        }
    }

    @Test("generate all palettes")
    func generate_allPalettes() async throws {
        for palette in ColorPalette.allCases {
            let request = BackgroundRequest(
                style: .bokeh,
                palette: palette,
                mood: .hopeful,
                complexity: 0.7
            )

            let result = try await service.generate(request: request)
            #expect(
                FileManager.default.fileExists(atPath: result.imagePath.path),
                "Failed for palette: \(palette.rawValue)"
            )

            try? FileManager.default.removeItem(at: result.imagePath)
            try? FileManager.default.removeItem(at: result.thumbnailPath)
        }
    }

    @Test("generate all moods")
    func generate_allMoods() async throws {
        for mood in GeneratorMood.allCases {
            let request = BackgroundRequest(
                style: .mist,
                palette: .nightFade,
                mood: mood,
                complexity: 0.5
            )

            let result = try await service.generate(request: request)
            #expect(
                FileManager.default.fileExists(atPath: result.imagePath.path),
                "Failed for mood: \(mood.rawValue)"
            )

            try? FileManager.default.removeItem(at: result.imagePath)
            try? FileManager.default.removeItem(at: result.thumbnailPath)
        }
    }

    @Test("generate new styles")
    func generate_newStyles() async throws {
        let newStyles: [GeneratorStyle] = [.geometric, .watercolor, .stainedGlass, .waves, .prism, .topography]

        for style in newStyles {
            let request = BackgroundRequest(
                style: style,
                palette: .electric,
                mood: .energized,
                complexity: 0.8
            )

            let result = try await service.generate(request: request)
            #expect(
                FileManager.default.fileExists(atPath: result.imagePath.path),
                "Failed for new style: \(style.rawValue)"
            )
            #expect(result.metadata.style == style.rawValue)

            try? FileManager.default.removeItem(at: result.imagePath)
            try? FileManager.default.removeItem(at: result.thumbnailPath)
        }
    }

    @Test("generate seed reproducibility")
    func generate_seedReproducibility() async throws {
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

        #expect(data1 == data2, "Same seed should produce identical images")

        try? FileManager.default.removeItem(at: result1.imagePath)
        try? FileManager.default.removeItem(at: result1.thumbnailPath)
        try? FileManager.default.removeItem(at: result2.imagePath)
        try? FileManager.default.removeItem(at: result2.thumbnailPath)
    }

    @Test("cancelGeneration does not crash")
    func cancelGeneration_doesNotCrash() async {
        await service.cancelGeneration()
    }

    // MARK: - Color palettes

    @Test("all palettes have three colors")
    func allPalettes_haveThreeColors() {
        for palette in ColorPalette.allCases {
            #expect(palette.cgColors.count == 3, "\(palette.rawValue) should have 3 colors")
        }
    }

    @Test("all palettes have accent color")
    func allPalettes_haveAccentColor() {
        for palette in ColorPalette.allCases {
            #expect(palette.accentCGColor != nil, "\(palette.rawValue) should have accent")
        }
    }

    @Test("new palettes exist")
    func newPalettes_exist() {
        let newPalettes: [ColorPalette] = [.cherry, .auroraGreen, .desert, .sakura, .electric, .slate]
        for palette in newPalettes {
            #expect(palette.cgColors.count == 3)
        }
    }

    // MARK: - Seeded RNG

    @Test("seeded RNG is deterministic")
    func seededRNG_deterministic() {
        var rng1 = SeededRNG(seed: 123)
        var rng2 = SeededRNG(seed: 123)

        for _ in 0..<100 {
            #expect(rng1.next() == rng2.next())
        }
    }

    @Test("seeded RNG different seeds produce different values")
    func seededRNG_differentSeeds() {
        var rng1 = SeededRNG(seed: 1)
        var rng2 = SeededRNG(seed: 2)

        #expect(rng1.next() != rng2.next())
    }
}
