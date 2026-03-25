import Dependencies
import Foundation
import Testing
import UIKit

@testable import Lumen

@Suite("ThemeGeneratorViewModel Tests")
@MainActor struct ThemeGeneratorViewModelTests {

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
            let thumbPath = dir.appendingPathComponent("\(UUID().uuidString)_thumb.png")
            // Create a valid 1x1 pixel image
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1))
            let imageData = renderer.pngData { ctx in
                UIColor.blue.setFill()
                ctx.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
            }
            try imageData.write(to: imagePath)
            try imageData.write(to: thumbPath)

            return GeneratedBackground(
                themeId: "test_theme",
                imagePath: imagePath,
                thumbnailPath: thumbPath,
                metadata: GenerationMetadata(
                    style: "aurora",
                    palette: "warmFlame",
                    mood: "calm",
                    seed: 42,
                    complexity: 0.5,
                    width: 512,
                    height: 512,
                    durationMs: 50
                )
            )
        }

        func cancelGeneration() async { cancelCalled = true }
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
            let imagePath = dir.appendingPathComponent("\(UUID().uuidString).png")
            let thumbPath = dir.appendingPathComponent("\(UUID().uuidString)_thumb.png")
            let renderer = await UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1))
            let imageData = await renderer.pngData { ctx in
                UIColor.red.setFill()
                ctx.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
            }
            try imageData.write(to: imagePath)
            try imageData.write(to: thumbPath)
            return GeneratedBackground(
                themeId: "ai_test",
                imagePath: imagePath,
                thumbnailPath: thumbPath,
                metadata: GenerationMetadata(
                    style: "ai_ethereal",
                    palette: "ai_0",
                    mood: "ethereal",
                    seed: 42,
                    complexity: 0.5,
                    width: 1170,
                    height: 2532,
                    durationMs: 5000
                )
            )
        }
        func cancelGeneration() async { cancelCalled = true }
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
        func configure() {}
        func isPremium() async -> Bool { premium }
        func purchase(productId: String) async throws {}
        func restorePurchases() async throws {}
        func availableProducts() async throws -> [ProductInfo] { [] }
    }

    // MARK: - Tests

    @Test("initial state")
    func initialState() {
        let vm = ThemeGeneratorViewModel()
        #expect(vm.selectedMode == .procedural)
        #expect(vm.selectedStyle == .aurora)
        #expect(vm.selectedPalette == .warmFlame)
        #expect(vm.selectedMood == .calm)
        #expect(!vm.isGenerating)
        #expect(vm.generatedImage == nil)
        #expect(vm.savedThemeId == nil)
        #expect(vm.aiLoadState == .idle)
    }

    @Test("procedural generate success")
    func proceduralGenerate_success() async {
        let mock = MockGenerator()
        let mockAI = MockAIGenerator()
        let analytics = MockAnalytics()
        let entitlement = MockEntitlementService()
        let vm = withDependencies {
            $0.backgroundGenerator = mock
            $0.aiBackgroundService = mockAI
            $0.analyticsService = analytics
            $0.entitlementService = entitlement
        } operation: {
            ThemeGeneratorViewModel()
        }

        await vm.generate()

        #expect(mock.generateCalled)
        #expect(vm.savedThemeId != nil)
        #expect(!vm.isGenerating)
        #expect(vm.errorMessage == nil)
        #expect(analytics.events.count == 2)
    }

    @Test("procedural generate failure")
    func proceduralGenerate_failure() async {
        let mock = MockGenerator()
        mock.shouldThrow = true
        let mockAI = MockAIGenerator()
        let entitlement = MockEntitlementService()
        let analytics = MockAnalytics()
        let vm = withDependencies {
            $0.backgroundGenerator = mock
            $0.aiBackgroundService = mockAI
            $0.entitlementService = entitlement
            $0.analyticsService = analytics
        } operation: {
            ThemeGeneratorViewModel()
        }

        await vm.generate()

        #expect(vm.errorMessage != nil)
        #expect(vm.savedThemeId == nil)
        #expect(!vm.isGenerating)
    }

    @Test("cancel calls both generators")
    func cancel_callsBothGenerators() async {
        let mock = MockGenerator()
        let mockAI = MockAIGenerator()
        let vm = withDependencies {
            $0.backgroundGenerator = mock
            $0.aiBackgroundService = mockAI
        } operation: {
            ThemeGeneratorViewModel()
        }

        await vm.cancelGeneration()

        #expect(mock.cancelCalled)
        #expect(!vm.isGenerating)
    }

    @Test("AI mode requires premium")
    func aiMode_requiresPremium() async {
        let mock = MockGenerator()
        let mockAI = MockAIGenerator()
        let entitlement = MockEntitlementService()
        entitlement.premium = false
        let vm = withDependencies {
            $0.backgroundGenerator = mock
            $0.aiBackgroundService = mockAI
            $0.entitlementService = entitlement
        } operation: {
            ThemeGeneratorViewModel()
        }
        vm.selectedMode = .ai

        await vm.generate()

        #expect(vm.showPaywallPrompt)
        #expect(!mockAI.generateCalled)
    }

    @Test("prompt library has all categories")
    func promptLibrary_hasAllCategories() {
        let categories = Set(AIBackgroundPrompt.library.map(\.category))
        #expect(categories.count == AIBackgroundPrompt.PromptCategory.allCases.count)
    }

    @Test("prompt library has sufficient prompts")
    func promptLibrary_hasSufficientPrompts() {
        for category in AIBackgroundPrompt.PromptCategory.allCases {
            let count = AIBackgroundPrompt.library.filter { $0.category == category }.count
            #expect(count >= 6, "Category \(category.rawValue) needs at least 6 prompts")
        }
    }

    @Test("random prompt returns from correct category")
    func randomPrompt_returnsFromCorrectCategory() {
        for _ in 0..<20 {
            let category = AIBackgroundPrompt.PromptCategory.allCases.randomElement()
            guard let category else { continue }
            let prompt = AIBackgroundPrompt.random(category: category)
            #expect(prompt.category == category)
        }
    }
}
