import XCTest
import SwiftData
@testable import Lumen

@MainActor
final class ContentServiceTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private let service = ContentService.shared

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

    // MARK: - fetchCategories

    func test_fetchCategories_returnsEmpty_whenNoData() throws {
        let result = try service.fetchCategories(modelContext: context, locale: "en-GB")
        XCTAssertTrue(result.isEmpty)
    }

    func test_fetchCategories_returnsSortedByOrder() throws {
        let cat1 = Category(id: "c1", name: "B Category", sortOrder: 2)
        let cat2 = Category(id: "c2", name: "A Category", sortOrder: 1)
        context.insert(cat1)
        context.insert(cat2)
        try context.save()

        let result = try service.fetchCategories(modelContext: context, locale: "en-GB")
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result.first?.id, "c2") // lower sortOrder first
    }

    func test_fetchCategories_filtersLocale() throws {
        let catEN = Category(id: "c1", locale: "en-GB", name: "English")
        let catES = Category(id: "c2", locale: "es-ES", name: "Spanish")
        context.insert(catEN)
        context.insert(catES)
        try context.save()

        let result = try service.fetchCategories(modelContext: context, locale: "en-GB")
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.name, "English")
    }

    // MARK: - fetchAffirmation

    func test_fetchAffirmation_findsById() throws {
        let aff = Affirmation(id: "test_123", text: "Hello world")
        context.insert(aff)
        try context.save()

        let result = try service.fetchAffirmation(byId: "test_123", modelContext: context)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.text, "Hello world")
    }

    func test_fetchAffirmation_returnsNilForMissingId() throws {
        let result = try service.fetchAffirmation(byId: "nonexistent", modelContext: context)
        XCTAssertNil(result)
    }
}
