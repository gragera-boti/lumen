import Dependencies
import Foundation
import SwiftData
import Testing

@testable import Lumen

@Suite("FavoritesViewModel Tests")
@MainActor struct FavoritesViewModelTests {

    // MARK: - Mock

    private final class MockFavoriteService: FavoriteServiceProtocol, @unchecked Sendable {
        var favorites: [Affirmation] = []
        var toggleCalledWith: String?
        var shouldThrow = false

        func toggleFavorite(affirmation: Affirmation, modelContext: ModelContext) throws {
            if shouldThrow { throw NSError(domain: "test", code: 1) }
            toggleCalledWith = affirmation.id
        }

        func fetchFavorites(modelContext: ModelContext) throws -> [Affirmation] {
            if shouldThrow { throw NSError(domain: "test", code: 1) }
            return favorites
        }
    }

    private final class MockWidgetService: WidgetServiceProtocol, @unchecked Sendable {
        func updateWidget(affirmationText: String, gradientColors: [String]) {}
        func updateFavoritesWidget(favorites: [(text: String, gradientColors: [String])]) {}
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

    private func createInMemoryContext() throws -> ModelContext {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Affirmation.self, AppTheme.self, configurations: configuration)
        return ModelContext(container)
    }

    // MARK: - Tests

    @Test("initial state")
    func initialState() {
        let vm = withDependencies {
            $0.widgetService = MockWidgetService()
            $0.favoriteService = MockFavoriteService()
            $0.cardCustomizationService = MockCardCustomizationService()
        } operation: {
            FavoritesViewModel()
        }
        #expect(vm.favorites.isEmpty)
        #expect(!vm.isLoading)
        #expect(vm.errorMessage == nil)
    }

    @Test("loadFavorites partitions userCreated and curatedFavorites")
    func loadFavorites_success() async throws {
        let mockService = MockFavoriteService()
        let userAff = Affirmation(id: "u1", text: "My own.")
        userAff.source = .user
        let curatedAff = Affirmation(id: "c1", text: "Curated.")
        curatedAff.source = .bundled
        mockService.favorites = [userAff, curatedAff]

        let vm = withDependencies {
            $0.favoriteService = mockService
            $0.widgetService = MockWidgetService()
            $0.cardCustomizationService = MockCardCustomizationService()
        } operation: {
            FavoritesViewModel()
        }

        let context = try createInMemoryContext()
        await vm.loadFavorites(modelContext: context)

        #expect(!vm.isLoading)
        #expect(vm.userCreated.count == 1)
        #expect(vm.userCreated.first?.id == "u1")
        #expect(vm.curatedFavorites.count == 1)
        #expect(vm.curatedFavorites.first?.id == "c1")
        #expect(vm.allFavorites.count == 2)
    }

    @Test("toggleFavorite re-loads favorites list")
    func toggleFavorite() async throws {
        let mockService = MockFavoriteService()
        let curatedAff = Affirmation(id: "c1", text: "Curated.")
        mockService.favorites = [curatedAff] // initial

        let vm = withDependencies {
            $0.favoriteService = mockService
            $0.widgetService = MockWidgetService()
            $0.cardCustomizationService = MockCardCustomizationService()
        } operation: {
            FavoritesViewModel()
        }

        let context = try createInMemoryContext()
        await vm.toggleFavorite(curatedAff, modelContext: context)

        #expect(mockService.toggleCalledWith == "c1")
    }

    @Test("removeFavorite removes from lists locally")
    func removeFavorite() throws {
        let mockService = MockFavoriteService()
        let userAff = Affirmation(id: "u1", text: "My own.")
        userAff.source = .user
        let curatedAff = Affirmation(id: "c1", text: "Curated.")
        curatedAff.source = .bundled

        let vm = withDependencies {
            $0.favoriteService = mockService
            $0.widgetService = MockWidgetService()
            $0.cardCustomizationService = MockCardCustomizationService()
        } operation: {
            FavoritesViewModel()
        }

        vm.userCreated = [userAff]
        vm.curatedFavorites = [curatedAff]

        let context = try createInMemoryContext()
        vm.removeFavorite(userAff, modelContext: context)

        #expect(mockService.toggleCalledWith == "u1")
        #expect(vm.userCreated.isEmpty)
        #expect(vm.curatedFavorites.count == 1)

        vm.removeFavorite(curatedAff, modelContext: context)
        #expect(mockService.toggleCalledWith == "c1")
        #expect(vm.curatedFavorites.isEmpty)
    }

    @Test("deleteUserAffirmation deletes model and removes from list")
    func deleteUserAffirmation() throws {
        let vm = withDependencies {
            $0.favoriteService = MockFavoriteService()
            $0.widgetService = MockWidgetService()
            $0.cardCustomizationService = MockCardCustomizationService()
        } operation: {
            FavoritesViewModel()
        }

        let context = try createInMemoryContext()
        let userAff = Affirmation(id: "u1", text: "Delete me.")
        userAff.source = .user
        context.insert(userAff)
        
        vm.userCreated = [userAff]

        vm.deleteUserAffirmation(userAff, modelContext: context)

        #expect(vm.userCreated.isEmpty)
    }
}
