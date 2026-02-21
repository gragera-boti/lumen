import XCTest
@testable import Lumen

@MainActor
final class ThemeGeneratorViewModelTests: XCTestCase {

    // MARK: - Mocks

    private final class MockGenerator: BackgroundGeneratorProtocol, @unchecked Sendable {
        var generateCalled = false
        var cancelCalled = false
        var shouldThrow = false

        func generate(request: BackgroundRequest) async throws -> GeneratedBackground {
            if shouldThrow { throw BackgroundGeneratorError.generationFailed("Test error") }
            generateCalled = true

            let dir = FileManager.default.temporaryDirectory
            let imagePath = dir.appendingPathComponent("\(UUID().uuidString).png")
            let thumbPath = dir.appendingPathComponent("\(UUID().uuidString)_thumb.jpg")
            try Data([0x89, 0x50]).write(to: imagePath)
            try Data([0xFF, 0xD8]).write(to: thumbPath)

            return GeneratedBackground(
                themeId: "test_theme",
                imagePath: imagePath,
                thumbnailPath: thumbPath,
                metadata: GenerationMetadata(
                    style: "aurora", palette: "warmFlame", mood: "calm",
                    seed: 42, complexity: 0.5, width: 512, height: 512, durationMs: 50
                )
            )
        }

        func cancelGeneration() { cancelCalled = true }
    }

    private final class MockAIGenerator: AIBackgroundServiceProtocol, @unchecked Sendable {
        var modelReady = false
        var generateCalled = false
        var cancelCalled = false

        func isModelReady() async -> Bool { modelReady }
        func setDownloadProgressHandler(_ handler: (@Sendable (Double) -> Void)?) {}
        func setStepProgressHandler(_ handler: (@Sendable (Int, Int) -> Void)?) {}
        func setLoadPhaseHandler(_ handler: (@Sendable (String, Double) -> Void)?) {}
        func loadModel() async throws { modelReady = true }
        func unloadModel() async { modelReady = false }
        func generate(request: AIBackgroundRequest) async throws -> GeneratedBackground {
            generateCalled = true
            let dir = FileManager.default.temporaryDirectory
            let imagePath = dir.appendingPathComponent("\(UUID().uuidString).jpg")
            let thumbPath = dir.appendingPathComponent("\(UUID().uuidString)_thumb.jpg")
            try Data([0xFF, 0xD8]).write(to: imagePath)
            try Data([0xFF, 0xD8]).write(to: thumbPath)
            return GeneratedBackground(
                themeId: "ai_test",
                imagePath: imagePath,
                thumbnailPath: thumbPath,
                metadata: GenerationMetadata(
                    style: "ai_ethereal", palette: "ai_0", mood: "ethereal",
                    seed: 42, complexity: 0.5, width: 1170, height: 2532, durationMs: 5000
                )
            )
        }
        func cancelGeneration() { cancelCalled = true }
        func pregenerate(count: Int, device: AIDeviceProfile) async throws -> [GeneratedBackground] { [] }
        func cachedBackgrounds() async -> [GeneratedBackground] { [] }
        func removeCached(themeId: String) async throws {}
    }

    private final class MockAnalytics: AnalyticsServiceProtocol, @unchecked Sendable {
        var events: [AnalyticsEvent] = []
        func log(event: AnalyticsEvent) { events.append(event) }
        func setOptOut(_ optOut: Bool) {}
    }

    private final class MockEntitlementService: EntitlementServiceProtocol, @unchecked Sendable {
        var premium = true
        func isPremium() async -> Bool { premium }
        func purchase(productId: String) async throws {}
        func restorePurchases() async throws {}
        func availableProducts() async throws -> [ProductInfo] { [] }
    }

    // MARK: - Tests

    func test_initialState() {
        let vm = ThemeGeneratorViewModel()
        XCTAssertEqual(vm.selectedMode, .procedural)
        XCTAssertEqual(vm.selectedStyle, .aurora)
        XCTAssertEqual(vm.selectedPalette, .warmFlame)
        XCTAssertEqual(vm.selectedMood, .calm)
        XCTAssertFalse(vm.isGenerating)
        XCTAssertNil(vm.generatedImage)
        XCTAssertNil(vm.savedThemeId)
        XCTAssertEqual(vm.aiLoadState, .idle)
    }

    func test_proceduralGenerate_success() async {
        let mock = MockGenerator()
        let ai = MockAIGenerator()
        let analytics = MockAnalytics()
        let entitlement = MockEntitlementService()
        let vm = ThemeGeneratorViewModel(
            generator: mock, aiGenerator: ai,
            analyticsService: analytics, entitlementService: entitlement
        )

        await vm.generate()

        XCTAssertTrue(mock.generateCalled)
        XCTAssertNotNil(vm.savedThemeId)
        XCTAssertFalse(vm.isGenerating)
        XCTAssertNil(vm.errorMessage)
        XCTAssertEqual(analytics.events.count, 2)
    }

    func test_proceduralGenerate_failure() async {
        let mock = MockGenerator()
        mock.shouldThrow = true
        let ai = MockAIGenerator()
        let entitlement = MockEntitlementService()
        let vm = ThemeGeneratorViewModel(
            generator: mock, aiGenerator: ai,
            entitlementService: entitlement
        )

        await vm.generate()

        XCTAssertNotNil(vm.errorMessage)
        XCTAssertNil(vm.savedThemeId)
        XCTAssertFalse(vm.isGenerating)
    }

    func test_cancel_callsBothGenerators() {
        let mock = MockGenerator()
        let ai = MockAIGenerator()
        let vm = ThemeGeneratorViewModel(generator: mock, aiGenerator: ai)

        vm.cancelGeneration()

        XCTAssertTrue(mock.cancelCalled)
        XCTAssertFalse(vm.isGenerating)
    }

    func test_aiMode_requiresPremium() async {
        let mock = MockGenerator()
        let ai = MockAIGenerator()
        let entitlement = MockEntitlementService()
        entitlement.premium = false
        let vm = ThemeGeneratorViewModel(
            generator: mock, aiGenerator: ai,
            entitlementService: entitlement
        )
        vm.selectedMode = .ai

        await vm.generate()

        XCTAssertTrue(vm.showPaywallPrompt)
        XCTAssertFalse(ai.generateCalled)
    }

    func test_promptLibrary_hasAllCategories() {
        let categories = Set(AIBackgroundPrompt.library.map(\.category))
        XCTAssertEqual(categories.count, AIBackgroundPrompt.PromptCategory.allCases.count)
    }

    func test_promptLibrary_hasSufficientPrompts() {
        // At least 6 per category
        for category in AIBackgroundPrompt.PromptCategory.allCases {
            let count = AIBackgroundPrompt.library.filter { $0.category == category }.count
            XCTAssertGreaterThanOrEqual(count, 6, "Category \(category.rawValue) needs at least 6 prompts")
        }
    }

    func test_randomPrompt_returnsFromCorrectCategory() {
        for _ in 0..<20 {
            let category = AIBackgroundPrompt.PromptCategory.allCases.randomElement()!
            let prompt = AIBackgroundPrompt.random(category: category)
            XCTAssertEqual(prompt.category, category)
        }
    }
}
