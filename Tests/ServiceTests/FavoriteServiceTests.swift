import Foundation
import SwiftData
import Testing

@testable import Lumen

@Suite("FavoriteService Tests")
@MainActor struct FavoriteServiceTests {
    private var container: ModelContainer
    private var context: ModelContext
    private let service = FavoriteService.shared

    @MainActor init() throws {
        container = try TestContainerFactory.makeContainer()
        context = ModelContext(container)
    }

    // MARK: - toggleFavorite

    @Test("toggleFavorite creates favorite")
    func toggleFavorite_createsFavorite() throws {
        let aff = Affirmation(id: "aff_1", text: "Test")
        context.insert(aff)
        try context.save()

        try service.toggleFavorite(affirmation: aff, modelContext: context)

        #expect(aff.favorite != nil)
        #expect(aff.isFavorited)
    }

    @Test("toggleFavorite removes favorite")
    func toggleFavorite_removesFavorite() throws {
        let aff = Affirmation(id: "aff_1", text: "Test")
        context.insert(aff)
        let fav = Favorite(affirmation: aff)
        context.insert(fav)
        try context.save()

        try service.toggleFavorite(affirmation: aff, modelContext: context)

        #expect(aff.favorite == nil)
        #expect(!aff.isFavorited)
    }

    @Test("toggleFavorite double toggle restores original")
    func toggleFavorite_doubleToggleRestoresOriginal() throws {
        let aff = Affirmation(id: "aff_1", text: "Test")
        context.insert(aff)
        try context.save()

        try service.toggleFavorite(affirmation: aff, modelContext: context)
        #expect(aff.isFavorited)

        try service.toggleFavorite(affirmation: aff, modelContext: context)
        #expect(!aff.isFavorited)
    }

    // MARK: - fetchFavorites

    @Test("fetchFavorites returns empty")
    func fetchFavorites_returnsEmpty() throws {
        let result = try service.fetchFavorites(modelContext: context)
        #expect(result.isEmpty)
    }

    @Test("fetchFavorites returns favorited affirmations")
    func fetchFavorites_returnsFavoritedAffirmations() throws {
        let aff1 = Affirmation(id: "aff_1", text: "First")
        let aff2 = Affirmation(id: "aff_2", text: "Second")
        context.insert(aff1)
        context.insert(aff2)

        let fav = Favorite(affirmation: aff1)
        context.insert(fav)
        try context.save()

        let result = try service.fetchFavorites(modelContext: context)
        #expect(result.count == 1)
        #expect(result.first?.id == "aff_1")
    }

    @Test("fetchFavorites ordered by most recent")
    func fetchFavorites_orderedByMostRecent() throws {
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
        #expect(result.count == 2)
        #expect(result.first?.id == "aff_2")
    }
}
