import Dependencies
import Foundation
import SwiftData
import SwiftUI
import Testing

@testable import Lumen

// MARK: - Customization Refresh Tests

/// Tests that views properly refresh after saving a card customization.
/// Covers the reload flow for Feed, CategoryFeed, and Favorites ViewModels.
@Suite("Customization Refresh")
@MainActor
struct CustomizationRefreshTests {

    // MARK: - Mocks

    private final class MockFeedService: FeedServiceProtocol, @unchecked Sendable {
        var batch: (daily: Affirmation?, feed: [Affirmation]) = (nil, [])

        func nextAffirmation(
            preferences: UserPreferences,
            isPremium: Bool,
            modelContext: ModelContext
        ) throws -> Affirmation? { nil }
        func dailyAffirmation(
            preferences: UserPreferences,
            isPremium: Bool,
            modelContext: ModelContext
        ) throws -> Affirmation? { nil }
        func loadBatch(
            count: Int,
            preferences: UserPreferences,
            isPremium: Bool,
            modelContext: ModelContext
        ) throws -> (daily: Affirmation?, feed: [Affirmation]) { batch }
        func recordSeen(affirmation: Affirmation, source: SeenSource, modelContext: ModelContext) throws {}
    }

    private final class MockFavoriteService: FavoriteServiceProtocol, @unchecked Sendable {
        func toggleFavorite(affirmation: Affirmation, modelContext: ModelContext) throws {}
        func fetchFavorites(modelContext: ModelContext) throws -> [Affirmation] { [] }
    }

    private final class MockShareService: ShareServiceProtocol, @unchecked Sendable {
        @MainActor func renderShareImage(
            text: String,
            font: Font,
            letterSpacing: CGFloat,
            gradientColors: [SwiftUI.Color],
            backgroundImage: UIImage?,
            size: CGSize,
            showWatermark: Bool
        ) -> UIImage? { nil }
    }

    private actor MockBackgroundGenerator: BackgroundGeneratorProtocol {
        var generateCallCount = 0
        var lastRequest: BackgroundRequest?

        func generate(request: BackgroundRequest) async throws -> GeneratedBackground {
            generateCallCount += 1
            lastRequest = request

            let tempDir = FileManager.default.temporaryDirectory
            let imagePath = tempDir.appendingPathComponent("mock_bg_\(UUID().uuidString).png")
            let thumbnailPath = tempDir.appendingPathComponent("mock_thumb_\(UUID().uuidString).png")
            if let imageData = UIImage(systemName: "circle.fill")?.pngData() {
                try imageData.write(to: imagePath)
                try imageData.write(to: thumbnailPath)
            }

            return GeneratedBackground(
                themeId: "mock_\(generateCallCount)",
                imagePath: imagePath,
                thumbnailPath: thumbnailPath,
                metadata: GenerationMetadata(
                    style: request.style.rawValue,
                    palette: request.palette.rawValue,
                    mood: request.mood.rawValue,
                    seed: request.seed ?? 0,
                    complexity: request.complexity,
                    width: Int(request.size.width),
                    height: Int(request.size.height),
                    durationMs: 10
                )
            )
        }

        func cancelGeneration() async {}
    }

    private let container: ModelContainer
    private let context: ModelContext
    private let mockFeedService = MockFeedService()
    private let mockFavoriteService = MockFavoriteService()
    private let mockShareService = MockShareService()

    init() throws {
        let schema = Schema([
            Affirmation.self, Category.self, Favorite.self, SeenEvent.self,
            Dislike.self, AppTheme.self, UserPreferences.self,
            EntitlementState.self, CardCustomization.self,
        ])
        container = try ModelContainer(
            for: schema,
            configurations: [
                ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            ]
        )
        context = ModelContext(container)
    }

    private func makeFeedViewModel(
        backgroundGenerator: (any BackgroundGeneratorProtocol)? = nil
    ) -> FeedViewModel {
        let mockBG = backgroundGenerator ?? MockBackgroundGenerator()
        return withDependencies {
            $0.feedService = mockFeedService
            $0.favoriteService = mockFavoriteService
            $0.shareService = mockShareService
            $0.cardCustomizationService = CardCustomizationService.shared
            $0.backgroundGenerator = mockBG
        } operation: {
            FeedViewModel()
        }
    }

    private func makeCategoryFeedViewModel() -> CategoryFeedViewModel {
        withDependencies {
            $0.favoriteService = mockFavoriteService
            $0.shareService = mockShareService
            $0.cardCustomizationService = CardCustomizationService.shared
        } operation: {
            CategoryFeedViewModel()
        }
    }

    private func makeCardEditorViewModel(
        affirmation: Affirmation,
        existingCustomization: CardCustomization? = nil
    ) -> CardEditorViewModel {
        withDependencies {
            $0.cardCustomizationService = CardCustomizationService.shared
        } operation: {
            CardEditorViewModel(
                affirmation: affirmation,
                existingCustomization: existingCustomization
            )
        }
    }

    // MARK: - FeedViewModel Tests

    @Test("reloadCustomizations updates customizations dict after save")
    func feedVM_reloadPicksUpNewCustomization() throws {
        let affirmation = Affirmation(id: "test_1", text: "Original text")
        context.insert(affirmation)
        try context.save()

        let viewModel = makeFeedViewModel()
        viewModel.cards = [affirmation]

        viewModel.reloadCustomizations(modelContext: context)
        #expect(viewModel.customizations.isEmpty)

        let customization = CardCustomization(
            affirmationId: "test_1",
            backgroundStyle: "aurora",
            colorPalette: "nightFade",
            backgroundSeed: 42,
            fontStyleOverride: "serif"
        )
        context.insert(customization)
        try context.save()

        viewModel.reloadCustomizations(modelContext: context)
        #expect(viewModel.customizations["test_1"] != nil)
        #expect(viewModel.customizations["test_1"]?.backgroundStyle == "aurora")
        #expect(viewModel.customizations["test_1"]?.fontStyleOverride == "serif")
    }

    @Test("reloadCustomizations clears removed customization")
    func feedVM_reloadClearsDeleted() throws {
        let affirmation = Affirmation(id: "test_2", text: "Some text")
        context.insert(affirmation)

        let customization = CardCustomization(
            affirmationId: "test_2",
            backgroundStyle: "bokeh",
            colorPalette: "warmFlame"
        )
        context.insert(customization)
        try context.save()

        let viewModel = makeFeedViewModel()
        viewModel.cards = [affirmation]

        viewModel.reloadCustomizations(modelContext: context)
        #expect(viewModel.customizations["test_2"] != nil)

        context.delete(customization)
        try context.save()

        viewModel.reloadCustomizations(modelContext: context)
        #expect(viewModel.customizations["test_2"] == nil)
    }

    @Test("reloadCustomizations triggers background regeneration for changed customization")
    func feedVM_reloadRegeneratesBackground() async throws {
        let affirmation = Affirmation(id: "test_3", text: "Regen test")
        context.insert(affirmation)
        try context.save()

        let mockGenerator = MockBackgroundGenerator()
        let viewModel = makeFeedViewModel(backgroundGenerator: mockGenerator)
        viewModel.cards = [affirmation]

        let customization = CardCustomization(
            affirmationId: "test_3",
            backgroundStyle: "cosmos",
            colorPalette: "electric",
            backgroundSeed: 99
        )
        context.insert(customization)
        try context.save()

        viewModel.reloadCustomizations(modelContext: context)

        try await Task.sleep(for: .milliseconds(500))

        let callCount = await mockGenerator.generateCallCount
        #expect(callCount >= 1, "Expected background generator to be called after customization reload")
        #expect(viewModel.cardBackgrounds["test_3"] != nil)
    }

    // MARK: - CategoryFeedViewModel Tests

    @Test("CategoryFeedViewModel reloadCustomizations updates dict")
    func categoryFeedVM_reloadPicksUpCustomization() throws {
        let affirmation = Affirmation(id: "cat_1", text: "Category text")
        context.insert(affirmation)
        try context.save()

        let viewModel = makeCategoryFeedViewModel()
        viewModel.cards = [affirmation]

        viewModel.loadCustomizations(modelContext: context)
        #expect(viewModel.customizations.isEmpty)

        let customization = CardCustomization(
            affirmationId: "cat_1",
            colorPalette: "sakura",
            fontStyleOverride: "elegant"
        )
        context.insert(customization)
        try context.save()

        viewModel.reloadCustomizations(modelContext: context)
        #expect(viewModel.customizations["cat_1"]?.colorPalette == "sakura")
        #expect(viewModel.customizations["cat_1"]?.fontStyleOverride == "elegant")
    }

    // MARK: - CardEditorViewModel save + reload round-trip

    @Test("CardEditorViewModel save creates customization that reload picks up")
    func editorSave_roundTrip() throws {
        let affirmation = Affirmation(id: "rt_1", text: "Round trip", source: .user)
        context.insert(affirmation)
        try context.save()

        let editorVM = makeCardEditorViewModel(affirmation: affirmation)

        editorVM.selectedStyle = .watercolor
        editorVM.selectedPalette = .deepForest
        editorVM.selectedFontStyle = .zilla
        editorVM.customText = "Updated text"
        editorVM.backgroundSeed = 777

        #expect(editorVM.hasChanges)

        try editorVM.save(modelContext: context)

        let feedVM = makeFeedViewModel()
        feedVM.cards = [affirmation]
        feedVM.reloadCustomizations(modelContext: context)

        let saved = feedVM.customizations["rt_1"]
        #expect(saved != nil)
        #expect(saved?.backgroundStyle == "watercolor")
        #expect(saved?.colorPalette == "deepForest")
        #expect(saved?.fontStyleOverride == "zilla")
        #expect(saved?.customText == "Updated text")
        #expect(saved?.backgroundSeed == 777)
    }

    @Test("CardEditorViewModel resetToDefaults clears customization")
    func editorReset_clearsCustomization() throws {
        let affirmation = Affirmation(id: "rst_1", text: "Reset test")
        context.insert(affirmation)

        let existing = CardCustomization(
            affirmationId: "rst_1",
            backgroundStyle: "prism",
            colorPalette: "cherry"
        )
        context.insert(existing)
        try context.save()

        let editorVM = makeCardEditorViewModel(
            affirmation: affirmation,
            existingCustomization: existing
        )

        try editorVM.resetToDefaults(modelContext: context)

        let feedVM = makeFeedViewModel()
        feedVM.cards = [affirmation]
        feedVM.reloadCustomizations(modelContext: context)

        #expect(feedVM.customizations["rst_1"] == nil, "Customization should be deleted after reset")
    }
}
