import Foundation
import SwiftData
import Testing

@testable import Lumen

@Suite("ContentService Tests")
@MainActor struct ContentServiceTests {
    private var container: ModelContainer
    private var context: ModelContext
    private let service = ContentService.shared

    init() throws {
        let schema = LumenApp.appSchema
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        context = ModelContext(container)
    }

    // MARK: - fetchCategories

    @Test("fetchCategories returns empty when no data")
    func fetchCategories_returnsEmpty_whenNoData() throws {
        let result = try service.fetchCategories(modelContext: context, locale: "en-GB")
        #expect(result.isEmpty)
    }

    @Test("fetchCategories returns sorted by order")
    func fetchCategories_returnsSortedByOrder() throws {
        let cat1 = Category(id: "c1", name: "B Category", sortOrder: 2)
        let cat2 = Category(id: "c2", name: "A Category", sortOrder: 1)
        context.insert(cat1)
        context.insert(cat2)
        try context.save()

        let result = try service.fetchCategories(modelContext: context, locale: "en-GB")
        #expect(result.count == 2)
        #expect(result.first?.id == "c2")
    }

    @Test("fetchCategories filters by locale")
    func fetchCategories_filtersLocale() throws {
        let catEN = Category(id: "c1", locale: "en-GB", name: "English")
        let catES = Category(id: "c2", locale: "es-ES", name: "Spanish")
        context.insert(catEN)
        context.insert(catES)
        try context.save()

        let result = try service.fetchCategories(modelContext: context, locale: "en-GB")
        #expect(result.count == 1)
        #expect(result.first?.name == "English")
    }

    // MARK: - fetchAffirmation

    @Test("fetchAffirmation finds by ID")
    func fetchAffirmation_findsById() throws {
        let aff = Affirmation(id: "test_123", text: "Hello world")
        context.insert(aff)
        try context.save()

        let result = try service.fetchAffirmation(byId: "test_123", modelContext: context)
        #expect(result != nil)
        #expect(result?.text == "Hello world")
    }

    @Test("fetchAffirmation returns nil for missing ID")
    func fetchAffirmation_returnsNilForMissingId() throws {
        let result = try service.fetchAffirmation(byId: "nonexistent", modelContext: context)
        #expect(result == nil)
    }
}
