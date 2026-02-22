import Testing
import SwiftUI
import SwiftData
@testable import Lumen

// MARK: - Customization Refresh Tests

/// Tests that views properly refresh after saving a card customization.
/// Covers the reload flow for Feed, CategoryFeed, and Favorites ViewModels.
@Suite("Customization Refresh")
@MainActor
struct CustomizationRefreshTests {

    // MARK: - Mocks

    private final class MockFeedService: FeedServiceProtocol {
        var batch: (daily: Affirmation?, feed: [Affirmation]) = (nil, [])

        func nextAffirmation(preferences: UserPreferences, isPremium: Bool, mood: Mood?, modelContext: ModelContext) throws -> Affirmation? { nil }
        func dailyAffirmation(preferences: UserPreferences, isPremium: Bool, mood: Mood?, modelContext: ModelContext) throws -> Affirmation? { nil }
        func loadBatch(count: Int, preferences: UserPreferences, isPremium: Bool, mood: Mood?, modelContext: ModelContext) throws -> (daily: Affirmation?, feed: [Affirmation]) { batch }
        func recordSeen(affirmation: Affirmation, source: SeenSource, modelContext: ModelContext) throws {}
    }

    private final class MockFavoriteService: FavoriteServiceProtocol {
        func toggleFavorite(affirmation: Affirmation, modelContext: ModelContext) throws {}
        func fetchFavorites(modelContext: ModelContext) throws -> [Affirmation] { [] }
    }

    private final class MockShareService: ShareServiceProtocol {
        @MainActor func renderShareImage(text: String, gradientColors: [SwiftUI.Color], size: CGSize, showWatermark: Bool) -> UIImage? { nil }
    }

    private final class MockMoodService: MoodServiceProtocol {
        func recordMood(_ mood: Mood, modelContext: ModelContext) throws {}
        func todaysMood(modelContext: ModelContext) throws -> MoodEntry? { nil }
        func moodHistory(limit: Int, modelContext: ModelContext) throws -> [MoodEntry] { [] }
    }

    private actor MockBackgroundGenerator: BackgroundGeneratorProtocol {
        var generateCallCount = 0
        var lastRequest: BackgroundRequest?

        func generate(request: BackgroundRequest) async throws -> GeneratedBackground {
            generateCallCount += 1
            lastRequest = request

            // Write a tiny image to a temp file so the path resolves
            let tempDir = FileManager.default.temporaryDirectory
            let imagePath = tempDir.appendingPathComponent("mock_bg_\(UUID().uuidString).png")
            let thumbnailPath = tempDir.appendingPathComponent("mock_thumb_\(UUID().uuidString).png")
            let imageData = UIImage(systemName: "circle.fill")!.pngData()!
            try imageData.write(to: imagePath)
            try imageData.write(to: thumbnailPath)

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

    init() throws {
        let schema = Schema([
            Affirmation.self, Category.self, Favorite.self, SeenEvent.self,
            Dislike.self, AppTheme.self, UserPreferences.self,
            EntitlementState.self, MoodEntry.self, CardCustomization.self,
        ])
        container = try ModelContainer(for: schema, configurations: [
            ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        ])
        context = ModelContext(container)
    }

    // MARK: - FeedViewModel Tests

    @Test("reloadCustomizations updates customizations dict after save")
    func feedVM_reloadPicksUpNewCustomization() throws {
        let affirmation = Affirmation(id: "test_1", text: "Original text")
        context.insert(affirmation)
        try context.save()

        let vm = FeedViewModel(
            feedService: MockFeedService(),
            favoriteService: MockFavoriteService(),
            shareService: MockShareService(),
            moodService: MockMoodService(),
            customizationService: CardCustomizationService.shared
        )
        vm.cards = [affirmation]

        // Initially no customizations
        vm.reloadCustomizations(modelContext: context)
        #expect(vm.customizations.isEmpty)

        // Save a customization
        let customization = CardCustomization(
            affirmationId: "test_1",
            backgroundStyle: "aurora",
            colorPalette: "nightFade",
            backgroundSeed: 42,
            fontStyleOverride: "serif"
        )
        context.insert(customization)
        try context.save()

        // Reload should pick it up
        vm.reloadCustomizations(modelContext: context)
        #expect(vm.customizations["test_1"] != nil)
        #expect(vm.customizations["test_1"]?.backgroundStyle == "aurora")
        #expect(vm.customizations["test_1"]?.fontStyleOverride == "serif")
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

        let vm = FeedViewModel(
            feedService: MockFeedService(),
            favoriteService: MockFavoriteService(),
            shareService: MockShareService(),
            moodService: MockMoodService(),
            customizationService: CardCustomizationService.shared
        )
        vm.cards = [affirmation]

        vm.reloadCustomizations(modelContext: context)
        #expect(vm.customizations["test_2"] != nil)

        // Delete the customization
        context.delete(customization)
        try context.save()

        vm.reloadCustomizations(modelContext: context)
        #expect(vm.customizations["test_2"] == nil)
    }

    @Test("reloadCustomizations triggers background regeneration for changed customization")
    func feedVM_reloadRegeneratesBackground() async throws {
        let affirmation = Affirmation(id: "test_3", text: "Regen test")
        context.insert(affirmation)
        try context.save()

        let mockGenerator = MockBackgroundGenerator()
        let vm = FeedViewModel(
            feedService: MockFeedService(),
            favoriteService: MockFavoriteService(),
            shareService: MockShareService(),
            moodService: MockMoodService(),
            customizationService: CardCustomizationService.shared,
            backgroundGenerator: mockGenerator
        )
        vm.cards = [affirmation]

        // Save a customization
        let customization = CardCustomization(
            affirmationId: "test_3",
            backgroundStyle: "cosmos",
            colorPalette: "electric",
            backgroundSeed: 99
        )
        context.insert(customization)
        try context.save()

        vm.reloadCustomizations(modelContext: context)

        // Give the background generation task time to run
        try await Task.sleep(for: .milliseconds(500))

        let callCount = await mockGenerator.generateCallCount
        #expect(callCount >= 1, "Expected background generator to be called after customization reload")

        // Should have a background image now
        #expect(vm.cardBackgrounds["test_3"] != nil)
    }

    // MARK: - CategoryFeedViewModel Tests

    @Test("CategoryFeedViewModel reloadCustomizations updates dict")
    func categoryFeedVM_reloadPicksUpCustomization() throws {
        let affirmation = Affirmation(id: "cat_1", text: "Category text")
        context.insert(affirmation)
        try context.save()

        let vm = CategoryFeedViewModel(
            favoriteService: MockFavoriteService(),
            shareService: MockShareService(),
            customizationService: CardCustomizationService.shared
        )
        vm.cards = [affirmation]

        vm.loadCustomizations(modelContext: context)
        #expect(vm.customizations.isEmpty)

        let customization = CardCustomization(
            affirmationId: "cat_1",
            colorPalette: "sakura",
            fontStyleOverride: "elegant"
        )
        context.insert(customization)
        try context.save()

        vm.reloadCustomizations(modelContext: context)
        #expect(vm.customizations["cat_1"]?.colorPalette == "sakura")
        #expect(vm.customizations["cat_1"]?.fontStyleOverride == "elegant")
    }

    // MARK: - CardEditorViewModel save + reload round-trip

    @Test("CardEditorViewModel save creates customization that reload picks up")
    func editorSave_roundTrip() throws {
        let affirmation = Affirmation(id: "rt_1", text: "Round trip", source: .user)
        context.insert(affirmation)
        try context.save()

        let editorVM = CardEditorViewModel(
            affirmation: affirmation,
            existingCustomization: nil,
            customizationService: CardCustomizationService.shared
        )

        // Change some properties
        editorVM.selectedStyle = .watercolor
        editorVM.selectedPalette = .deepForest
        editorVM.selectedFontStyle = .typewriter
        editorVM.customText = "Updated text"
        editorVM.backgroundSeed = 777

        #expect(editorVM.hasChanges)

        try editorVM.save(modelContext: context)

        // Now create a FeedViewModel and reload
        let feedVM = FeedViewModel(
            feedService: MockFeedService(),
            favoriteService: MockFavoriteService(),
            shareService: MockShareService(),
            moodService: MockMoodService(),
            customizationService: CardCustomizationService.shared
        )
        feedVM.cards = [affirmation]
        feedVM.reloadCustomizations(modelContext: context)

        let c = feedVM.customizations["rt_1"]
        #expect(c != nil)
        #expect(c?.backgroundStyle == "watercolor")
        #expect(c?.colorPalette == "deepForest")
        #expect(c?.fontStyleOverride == "typewriter")
        #expect(c?.customText == "Updated text")
        #expect(c?.backgroundSeed == 777)
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

        let editorVM = CardEditorViewModel(
            affirmation: affirmation,
            existingCustomization: existing,
            customizationService: CardCustomizationService.shared
        )

        try editorVM.resetToDefaults(modelContext: context)

        let feedVM = FeedViewModel(
            feedService: MockFeedService(),
            favoriteService: MockFavoriteService(),
            shareService: MockShareService(),
            moodService: MockMoodService(),
            customizationService: CardCustomizationService.shared
        )
        feedVM.cards = [affirmation]
        feedVM.reloadCustomizations(modelContext: context)

        #expect(feedVM.customizations["rst_1"] == nil, "Customization should be deleted after reset")
    }
}
