import Dependencies
import Foundation
import SwiftData
import SwiftUI
import Testing

@testable import Lumen

@Suite("CategoryFeedViewModel Tests")
@MainActor struct CategoryFeedViewModelTests {

    // MARK: - Mocks

    private final class MockFavoriteService: FavoriteServiceProtocol, @unchecked Sendable {
        var toggledAffirmationId: String?

        func toggleFavorite(affirmation: Affirmation, modelContext: ModelContext) throws {
            toggledAffirmationId = affirmation.id
        }
        func fetchFavorites(modelContext: ModelContext) throws -> [Affirmation] { [] }
    }

    private final class MockShareService: ShareServiceProtocol, @unchecked Sendable {
        @MainActor func renderShareImage(
            text: String,
            font: Font,
            letterSpacing: CGFloat,
            gradientColors: [Color],
            backgroundImage: UIImage?,
            size: CGSize,
            showWatermark: Bool
        ) -> UIImage? {
            UIImage()
        }
    }

    private final class MockCardCustomizationService: CardCustomizationServiceProtocol, @unchecked Sendable {
        var stubbedCustomizations: [CardCustomization] = []
        func customization(for affirmationId: String, modelContext: ModelContext) throws -> CardCustomization? { nil }
        func allCustomizations(modelContext: ModelContext) throws -> [CardCustomization] {
            return stubbedCustomizations
        }
        func save(_ customization: CardCustomization, modelContext: ModelContext) throws {}
        func delete(for affirmationId: String, modelContext: ModelContext) throws {}
        func hasCustomization(for affirmationId: String, modelContext: ModelContext) throws -> Bool { false }
    }

    private final class MockFeedService: FeedServiceProtocol, @unchecked Sendable {
        var recordedSeenId: String?
        func nextAffirmation(preferences: UserPreferences, isPremium: Bool, modelContext: ModelContext) throws -> Affirmation? { nil }
        func dailyAffirmation(preferences: UserPreferences, isPremium: Bool, modelContext: ModelContext) throws -> Affirmation? { nil }
        func loadBatch(count: Int, preferences: UserPreferences, isPremium: Bool, modelContext: ModelContext) throws -> (daily: Affirmation?, feed: [Affirmation]) { (nil, []) }
        func recordSeen(affirmation: Affirmation, source: SeenSource, modelContext: ModelContext) throws {
            recordedSeenId = affirmation.id
        }
    }

    private final class MockBackgroundGenerator: BackgroundGeneratorProtocol, @unchecked Sendable {
        func generate(request: BackgroundRequest) async throws -> GeneratedBackground {
            GeneratedBackground(imagePath: URL(fileURLWithPath: ""), thumbnailPath: URL(fileURLWithPath: ""), style: .aurora, palette: .ocean, request: request)
        }
        func cancelGeneration() async {}
    }

    private func createInMemoryContext() throws -> ModelContext {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Category.self, Affirmation.self, UserPreferences.self, AppTheme.self, configurations: configuration)
        return ModelContext(container)
    }

    // MARK: - Tests

    @Test("initial state")
    func initialState() {
        let vm = CategoryFeedViewModel()
        #expect(vm.cards.isEmpty)
        #expect(vm.currentIndex == 0)
        #expect(vm.currentCard == nil)
        #expect(!vm.isLoading)
    }

    @Test("loadCategory success loads affirmations for category")
    func loadCategory_success() async throws {
        let vm = withDependencies {
            $0.favoriteService = MockFavoriteService()
            $0.shareService = MockShareService()
            $0.cardCustomizationService = MockCardCustomizationService()
            $0.feedService = MockFeedService()
            $0.backgroundGenerator = MockBackgroundGenerator()
        } operation: {
            CategoryFeedViewModel()
        }

        let context = try createInMemoryContext()
        let cat = Category(id: "c1", name: "Relationships", icon: "heart")
        context.insert(cat)

        let aff1 = Affirmation(id: "a1", text: "I am loved.")
        let aff2 = Affirmation(id: "a2", text: "I am confident.")
        aff1.categories = [cat]
        context.insert(aff1)
        context.insert(aff2)

        let prefs = UserPreferences()
        
        await vm.loadCategory(categoryId: "c1", preferences: prefs, isPremium: true, modelContext: context)

        #expect(!vm.isLoading)
        #expect(vm.categoryName == "Relationships")
        #expect(vm.cards.count == 1)
        #expect(vm.cards.first?.id == "a1")
    }

    @Test("recordSeen invokes feedService correctly")
    func recordSeen() async throws {
        let feedService = MockFeedService()
        let vm = withDependencies {
            $0.feedService = feedService
            $0.cardCustomizationService = MockCardCustomizationService()
            $0.shareService = MockShareService()
            $0.favoriteService = MockFavoriteService()
            $0.backgroundGenerator = MockBackgroundGenerator()
        } operation: {
            CategoryFeedViewModel()
        }

        let aff = Affirmation(id: "a1", text: "I am seen.")
        vm.cards = [aff]
        vm.currentIndex = 0

        let context = try createInMemoryContext()
        vm.recordSeen(modelContext: context)

        #expect(feedService.recordedSeenId == "a1")
    }

    @Test("toggleFavorite invokes favoriteService correctly")
    func toggleFavorite() async throws {
        let favoriteService = MockFavoriteService()
        let vm = withDependencies {
            $0.feedService = MockFeedService()
            $0.cardCustomizationService = MockCardCustomizationService()
            $0.shareService = MockShareService()
            $0.favoriteService = favoriteService
            $0.backgroundGenerator = MockBackgroundGenerator()
        } operation: {
            CategoryFeedViewModel()
        }

        let aff = Affirmation(id: "a1", text: "I am favorite.")
        vm.cards = [aff]
        vm.currentIndex = 0

        let context = try createInMemoryContext()
        vm.toggleFavorite(modelContext: context)

        #expect(favoriteService.toggledAffirmationId == "a1")
    }

    @Test("swipeToNext and swipeToPrevious changes index bounds")
    func swipeInteractions() {
        let vm = CategoryFeedViewModel()
        let aff1 = Affirmation(id: "a1", text: "1")
        let aff2 = Affirmation(id: "a2", text: "2")
        vm.cards = [aff1, aff2]

        vm.swipeToNext()
        #expect(vm.currentIndex == 1)
        #expect(vm.currentCard?.id == "a2")

        vm.swipeToNext() // Should not exceed bounds
        #expect(vm.currentIndex == 1)

        vm.swipeToPrevious()
        #expect(vm.currentIndex == 0)
        #expect(vm.currentCard?.id == "a1")

        vm.swipeToPrevious() // Should not go below zero
        #expect(vm.currentIndex == 0)
    }
}
