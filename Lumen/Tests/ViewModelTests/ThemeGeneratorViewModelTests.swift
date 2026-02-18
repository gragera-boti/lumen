import XCTest
@testable import Lumen

@MainActor
final class ThemeGeneratorViewModelTests: XCTestCase {

    // MARK: - Mock

    private final class MockMLService: MLBackgroundServiceProtocol {
        var capability: GeneratorCapability = .supported(tier: .mid)
        var modelReady = false
        var shouldThrow = false
        var generateCalled = false
        var cancelCalled = false

        func checkCapability() -> GeneratorCapability { capability }
        func isModelReady() async -> Bool { modelReady }

        func downloadModel(progress: @escaping @Sendable (Double) -> Void) async throws {
            for i in 0...5 {
                progress(Double(i) / 5.0)
            }
            modelReady = true
        }

        func deleteModel() async throws { modelReady = false }
        func modelSizeBytes() async -> UInt64? { modelReady ? 500_000_000 : nil }

        func generate(request: BackgroundGenerationRequest) async throws -> GeneratedBackground {
            if shouldThrow { throw MLBackgroundError.generationFailed("Test error") }
            generateCalled = true

            // Create temp files
            let dir = FileManager.default.temporaryDirectory
            let imagePath = dir.appendingPathComponent("\(UUID().uuidString).png")
            let thumbPath = dir.appendingPathComponent("\(UUID().uuidString)_thumb.jpg")

            // Write minimal data
            try Data([0xFF, 0xD8]).write(to: imagePath)
            try Data([0xFF, 0xD8]).write(to: thumbPath)

            return GeneratedBackground(
                themeId: "test_theme",
                imagePath: imagePath,
                thumbnailPath: thumbPath,
                metadata: GenerationMetadata(
                    model: "test", styleId: "abstract", seed: 42, steps: 20,
                    guidanceScale: 7.0, size: 512, prompt: "test", durationMs: 100
                )
            )
        }

        func cancelGeneration() { cancelCalled = true }
    }

    private final class MockAnalytics: AnalyticsServiceProtocol {
        var events: [AnalyticsEvent] = []
        func log(event: AnalyticsEvent) { events.append(event) }
        func setOptOut(_ optOut: Bool) {}
    }

    // MARK: - Tests

    func test_initialState() {
        let vm = ThemeGeneratorViewModel()
        XCTAssertEqual(vm.selectedStyle, .abstract)
        XCTAssertEqual(vm.selectedColor, .warm)
        XCTAssertEqual(vm.selectedMood, .calm)
        XCTAssertFalse(vm.isGenerating)
        XCTAssertFalse(vm.canGenerate)
    }

    func test_checkCapability_supported() async {
        let mock = MockMLService()
        mock.capability = .supported(tier: .high)
        let vm = ThemeGeneratorViewModel(mlService: mock)

        await vm.checkDeviceCapability()

        XCTAssertTrue(vm.canGenerate)
        XCTAssertNil(vm.capabilityMessage)
    }

    func test_checkCapability_unsupported() async {
        let mock = MockMLService()
        mock.capability = .unsupported(reason: "Too old")
        let vm = ThemeGeneratorViewModel(mlService: mock)

        await vm.checkDeviceCapability()

        XCTAssertFalse(vm.canGenerate)
        XCTAssertEqual(vm.capabilityMessage, "Too old")
    }

    func test_downloadModel() async {
        let mock = MockMLService()
        let vm = ThemeGeneratorViewModel(mlService: mock)

        await vm.downloadModel()

        XCTAssertTrue(vm.isModelReady)
        XCTAssertFalse(vm.isDownloadingModel)
    }

    func test_deleteModel() async {
        let mock = MockMLService()
        mock.modelReady = true
        let vm = ThemeGeneratorViewModel(mlService: mock)

        await vm.deleteModel()

        XCTAssertFalse(vm.isModelReady)
    }

    func test_generate_success() async {
        let mock = MockMLService()
        let analytics = MockAnalytics()
        let vm = ThemeGeneratorViewModel(mlService: mock, analyticsService: analytics)

        await vm.generate()

        XCTAssertTrue(mock.generateCalled)
        XCTAssertNotNil(vm.savedThemeId)
        XCTAssertFalse(vm.isGenerating)
        XCTAssertEqual(analytics.events.count, 2) // started + completed
    }

    func test_generate_failure() async {
        let mock = MockMLService()
        mock.shouldThrow = true
        let vm = ThemeGeneratorViewModel(mlService: mock)

        await vm.generate()

        XCTAssertNotNil(vm.errorMessage)
        XCTAssertNil(vm.savedThemeId)
    }

    func test_cancelGeneration() {
        let mock = MockMLService()
        let vm = ThemeGeneratorViewModel(mlService: mock)

        vm.cancelGeneration()

        XCTAssertTrue(mock.cancelCalled)
        XCTAssertFalse(vm.isGenerating)
    }
}
