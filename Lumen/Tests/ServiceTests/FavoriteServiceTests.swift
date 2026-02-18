import XCTest
import SwiftData
@testable import Lumen

@MainActor
final class FavoriteServiceTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private let service = FavoriteService.shared

    override func setUp() async throws {
        let schema = Schema([
            Affirmation.self, Category.self, Favorite.self,
            SeenEvent.self, Dislike.self, AppTheme.self,
            UserPreferences.self, EntitlementState.self,
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        context = ModelContext(container)
    }

    override func tearDown() {
        container = nil
        context = nil
    }

    // MARK: - toggleFavorite

    func test_toggleFavorite_createsFavorite() throws {
        let aff = Affirmation(id: "aff_1", text: "Test")
        context.insert(aff)
        try context.save()

        try service.toggleFavorite(affirmation: aff, modelContext: context)

        XCTAssertNotNil(aff.favorite)
        XCTAssertTrue(aff.isFavorited)
    }

    func test_toggleFavorite_removesFavorite() throws {
        let aff = Affirmation(id: "aff_1", text: "Test")
        context.insert(aff)
        let fav = Favorite(affirmation: aff)
        context.insert(fav)
        try context.save()

        try service.toggleFavorite(affirmation: aff, modelContext: context)

        XCTAssertNil(aff.favorite)
        XCTAssertFalse(aff.isFavorited)
    }

    func test_toggleFavorite_doubleToggleRestoresOriginal() throws {
        let aff = Affirmation(id: "aff_1", text: "Test")
        context.insert(aff)
        try context.save()

        try service.toggleFavorite(affirmation: aff, modelContext: context)
        XCTAssertTrue(aff.isFavorited)

        try service.toggleFavorite(affirmation: aff, modelContext: context)
        XCTAssertFalse(aff.isFavorited)
    }

    // MARK: - fetchFavorites

    func test_fetchFavorites_returnsEmpty() throws {
        let result = try service.fetchFavorites(modelContext: context)
        XCTAssertTrue(result.isEmpty)
    }

    func test_fetchFavorites_returnsFavoritedAffirmations() throws {
        let aff1 = Affirmation(id: "aff_1", text: "First")
        let aff2 = Affirmation(id: "aff_2", text: "Second")
        context.insert(aff1)
        context.insert(aff2)

        let fav = Favorite(affirmation: aff1)
        context.insert(fav)
        try context.save()

        let result = try service.fetchFavorites(modelContext: context)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, "aff_1")
    }

    func test_fetchFavorites_orderedByMostRecent() throws {
        let aff1 = Affirmation(id: "aff_1", text: "First")
        let aff2 = Affirmation(id: "aff_2", text: "Second")
        context.insert(aff1)
        context.insert(aff2)

        let fav1 = Favorite(affirmation: aff1, favoritedAt: Date(timeIntervalSince1970: 1000))
        let fav2 = Favorite(affirmation: aff2, favoritedAt: Date(timeIntervalSince1970: 2000))
        context.insert(fav1)
        context.insert(fav2)
        try context.save()

        let result = try service.fetchFavorites(modelContext: context)
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result.first?.id, "aff_2") // most recent
    }
}
