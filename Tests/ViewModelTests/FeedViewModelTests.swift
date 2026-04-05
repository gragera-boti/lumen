import Dependencies
import Foundation
import SwiftData
import SwiftUI
import Testing

@testable import Lumen

@Suite("FeedViewModel Tests")
@MainActor struct FeedViewModelTests {

    // MARK: - Mocks

    private final class MockFeedService: FeedServiceProtocol, @unchecked Sendable {
        var mockedFeed: [Affirmation] = []
        var mockedDaily: Affirmation?
        var loadBatchCallCount = 0
        var nextAffirmationCallCount = 0
        var recordedSeenAffirmationId: String?

        func nextAffirmation(preferences: UserPreferences, isPremium: Bool, modelContext: ModelContext) throws -> Affirmation? {
            nextAffirmationCallCount += 1
            return Affirmation(id: UUID().uuidString, text: "Next")
        }

        func dailyAffirmation(preferences: UserPreferences, isPremium: Bool, modelContext: ModelContext) throws -> Affirmation? {
            mockedDaily
        }

        func loadBatch(count: Int, preferences: UserPreferences, isPremium: Bool, modelContext: ModelContext) throws -> (daily: Affirmation?, feed: [Affirmation]) {
            loadBatchCallCount += 1
            return (mockedDaily, mockedFeed)
        }

        func recordSeen(affirmation: Affirmation, source: SeenSource, modelContext: ModelContext) throws {
            recordedSeenAffirmationId = affirmation.id
        }
    }

    private final class MockFavoriteService: FavoriteServiceProtocol, @unchecked Sendable {
        func toggleFavorite(affirmation: Affirmation, modelContext: ModelContext) throws {}
        func fetchFavorites(modelContext: ModelContext) throws -> [Affirmation] { [] }
    }

    private final class MockWidgetService: WidgetServiceProtocol, @unchecked Sendable {
        func updateWidget(entries: [(text: String, gradientColors: [String], backgroundImage: UIImage?)]) {}
        func updateFavoritesWidget(favorites: [(text: String, gradientColors: [String], backgroundImage: UIImage?)]) {}
    }

    private final class MockCardCustomizationService: CardCustomizationServiceProtocol, @unchecked Sendable {
        var stubbedCustomizations: [CardCustomization] = []
        func customization(for affirmationId: String, modelContext: ModelContext) throws -> CardCustomization? { nil }
        func allCustomizations(modelContext: ModelContext) throws -> [CardCustomization] { stubbedCustomizations }
        func save(_ customization: CardCustomization, modelContext: ModelContext) throws {}
        func delete(for affirmationId: String, modelContext: ModelContext) throws {}
        func hasCustomization(for affirmationId: String, modelContext: ModelContext) throws -> Bool { false }
    }

    private final class MockBackgroundGenerator: BackgroundGeneratorProtocol, @unchecked Sendable {
        func generate(request: BackgroundRequest) async throws -> GeneratedBackground {
            GeneratedBackground(imagePath: URL(fileURLWithPath: ""), thumbnailPath: URL(fileURLWithPath: ""), style: .aurora, palette: .ocean, request: request)
        }
        func cancelGeneration() async {}
    }

    private final class MockShareService: ShareServiceProtocol, @unchecked Sendable {
        @MainActor func renderShareImage(text: String, font: Font, letterSpacing: CGFloat, gradientColors: [Color], backgroundImage: UIImage?, size: CGSize, showWatermark: Bool) -> UIImage? {
            UIImage()
        }
    }

    private func createInMemoryContext() throws -> ModelContext {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Affirmation.self, UserPreferences.self, AppTheme.self, configurations: configuration)
        return ModelContext(container)
    }

    // MARK: - Tests

    @Test("initial state")
    func initialState() {
        let vm = FeedViewModel()
        #expect(vm.cards.isEmpty)
        #expect(vm.currentIndex == 0)
        #expect(!vm.isLoading)
        #expect(vm.errorMessage == nil)
    }

    @Test("loadFeed utilizes feedService and sets state")
    func loadFeed_success() async throws {
        let feedService = MockFeedService()
        let a1 = Affirmation(id: "a1", text: "Test 1")
        let a2 = Affirmation(id: "a2", text: "Test 2")
        feedService.mockedFeed = [a1, a2]
        let daily = Affirmation(id: "d1", text: "Daily")
        feedService.mockedDaily = daily

        let vm = withDependencies {
            $0.feedService = feedService
            $0.favoriteService = MockFavoriteService()
            $0.widgetService = MockWidgetService()
            $0.cardCustomizationService = MockCardCustomizationService()
            $0.backgroundGenerator = MockBackgroundGenerator()
            $0.shareService = MockShareService()
        } operation: {
            FeedViewModel()
        }

        let context = try createInMemoryContext()
        await vm.loadFeed(preferences: UserPreferences(), isPremium: true, modelContext: context)

        #expect(feedService.loadBatchCallCount == 1)
        #expect(vm.cards.count == 2)
        #expect(vm.cards.first?.id == "a1")
        #expect(vm.dailyAffirmation?.id == "d1")
    }

    @Test("loadMoreIfNeeded gets next batch when near end")
    func loadMoreIfNeeded_triggers() throws {
        let feedService = MockFeedService()
        let vm = withDependencies {
            $0.feedService = feedService
            $0.favoriteService = MockFavoriteService()
            $0.widgetService = MockWidgetService()
            $0.cardCustomizationService = MockCardCustomizationService()
            $0.backgroundGenerator = MockBackgroundGenerator()
        } operation: {
            FeedViewModel()
        }

        let a1 = Affirmation(id: "a1", text: "Test 1")
        vm.cards = [a1]
        vm.currentIndex = 0

        let context = try createInMemoryContext()
        vm.loadMoreIfNeeded(preferences: UserPreferences(), isPremium: true, modelContext: context)

        // Near end because count is 1 and index is 0, difference is less than 5
        #expect(feedService.nextAffirmationCallCount == 10) // Tries to fetch 10
        #expect(vm.cards.count == 11)
    }

    @Test("insertLatestUserAffirmation prepends properly")
    func insertLatestUserAffirmation() throws {
        let feedService = MockFeedService()
        let vm = withDependencies {
            $0.feedService = feedService
            $0.favoriteService = MockFavoriteService()
            $0.widgetService = MockWidgetService()
            $0.cardCustomizationService = MockCardCustomizationService()
            $0.backgroundGenerator = MockBackgroundGenerator()
        } operation: {
            FeedViewModel()
        }

        let context = try createInMemoryContext()
        let userAff = Affirmation(id: "u1", text: "My Affirmation")
        userAff.source = .user
        context.insert(userAff)
        try context.save()

        let a1 = Affirmation(id: "a1", text: "A1")
        vm.cards = [a1]
        vm.currentIndex = 0 // Insert at currentIndex

        vm.insertLatestUserAffirmation(modelContext: context)

        #expect(vm.cards.count == 2)
        #expect(vm.cards[0].id == "u1") // inserted at currentIndex
    }

    @Test("swipeToNext and swipeToPrevious")
    func swipeInteractions() {
        let vm = FeedViewModel()
        let a1 = Affirmation(id: "a1", text: "First")
        let a2 = Affirmation(id: "a2", text: "Second")
        vm.cards = [a1, a2]
        vm.currentIndex = 0

        vm.swipeToNext()
        #expect(vm.currentIndex == 1)

        vm.swipeToNext()
        #expect(vm.currentIndex == 1)

        vm.swipeToPrevious()
        #expect(vm.currentIndex == 0)

        vm.swipeToPrevious()
        #expect(vm.currentIndex == 0)
    }
}
