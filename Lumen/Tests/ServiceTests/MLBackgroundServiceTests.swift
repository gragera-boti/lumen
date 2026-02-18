import XCTest
@testable import Lumen

@MainActor
final class MLBackgroundServiceTests: XCTestCase {
    private let service = MLBackgroundService.shared

    // MARK: - Capability

    func test_checkCapability_returnsResult() {
        let capability = service.checkCapability()

        switch capability {
        case .supported(let tier):
            // On any modern device/simulator, should be supported
            XCTAssertTrue(tier.steps > 0)
            XCTAssertTrue(tier.guidanceScale > 0)
        case .unsupported(let reason):
            // Thermal or memory constraint — acceptable
            XCTAssertFalse(reason.isEmpty)
        }
    }

    // MARK: - Generation request

    func test_prompt_composition() {
        let request = BackgroundGenerationRequest(
            styleId: .abstract,
            colorFamily: .warm,
            mood: .calm,
            detailLevel: 0.5
        )

        let prompt = request.prompt
        XCTAssertTrue(prompt.contains("abstract"))
        XCTAssertTrue(prompt.contains("warm"))
        XCTAssertTrue(prompt.contains("calm"))
        XCTAssertTrue(prompt.contains("medium detail"))
    }

    func test_prompt_lowDetail() {
        let request = BackgroundGenerationRequest(detailLevel: 0.1)
        XCTAssertTrue(request.prompt.contains("minimal"))
    }

    func test_prompt_highDetail() {
        let request = BackgroundGenerationRequest(detailLevel: 0.9)
        XCTAssertTrue(request.prompt.contains("high detail"))
    }

    func test_negativePrompt_containsSafetyTerms() {
        let negative = BackgroundGenerationRequest.negativePrompt
        XCTAssertTrue(negative.contains("people"))
        XCTAssertTrue(negative.contains("violence"))
        XCTAssertTrue(negative.contains("nsfw"))
        XCTAssertTrue(negative.contains("nude"))
        XCTAssertTrue(negative.contains("explicit"))
    }

    // MARK: - Generation

    func test_generate_producesImage() async throws {
        let request = BackgroundGenerationRequest(
            styleId: .mist,
            colorFamily: .cool,
            mood: .hopeful,
            detailLevel: 0.5
        )

        let result = try await service.generate(request: request)

        XCTAssertFalse(result.themeId.isEmpty)
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.imagePath.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.thumbnailPath.path))
        XCTAssertTrue(result.metadata.durationMs >= 0)
        XCTAssertEqual(result.metadata.styleId, "mist")

        // Clean up
        try? FileManager.default.removeItem(at: result.imagePath)
        try? FileManager.default.removeItem(at: result.thumbnailPath)
    }

    func test_generate_allStyleCombinations() async throws {
        // Verify every style/color/mood combination produces a valid image
        for style in GeneratorStyle.allCases {
            for color in ColorFamily.allCases {
                let request = BackgroundGenerationRequest(
                    styleId: style,
                    colorFamily: color,
                    mood: .calm,
                    detailLevel: 0.5
                )

                let result = try await service.generate(request: request)
                XCTAssertTrue(
                    FileManager.default.fileExists(atPath: result.imagePath.path),
                    "Failed for \(style.rawValue)/\(color.rawValue)"
                )

                // Clean up
                try? FileManager.default.removeItem(at: result.imagePath)
                try? FileManager.default.removeItem(at: result.thumbnailPath)
            }
        }
    }

    func test_cancelGeneration_doesNotCrash() {
        service.cancelGeneration()
        // Should be a no-op when nothing is generating
    }

    // MARK: - Device tiers

    func test_deviceTier_steps() {
        XCTAssertEqual(DeviceTier.high.steps, 25)
        XCTAssertEqual(DeviceTier.mid.steps, 20)
        XCTAssertEqual(DeviceTier.low.steps, 12)
    }

    func test_outputSize_pixels() {
        XCTAssertEqual(GeneratorOutputSize.standard.pixels, 512)
        XCTAssertEqual(GeneratorOutputSize.large.pixels, 768)
    }
}
