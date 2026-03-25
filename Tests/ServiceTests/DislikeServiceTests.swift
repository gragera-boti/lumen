import Foundation
import SwiftData
import Testing

@testable import Lumen

@Suite("DislikeService Tests")
@MainActor struct DislikeServiceTests {
    private var container: ModelContainer
    private var context: ModelContext
    private let service = DislikeService.shared

    init() throws {
        let schema = Schema([
            Affirmation.self, Category.self, Favorite.self,
            SeenEvent.self, Dislike.self, AppTheme.self,
            UserPreferences.self, EntitlementState.self,
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        context = ModelContext(container)
    }

    @Test("dislike creates dislike")
    func dislike_createsDislike() throws {
        let aff = Affirmation(id: "aff_1", text: "Test")
        context.insert(aff)
        try context.save()

        try service.dislike(affirmation: aff, reason: "Not for me", modelContext: context)

        #expect(aff.isDisliked)
        #expect(aff.dislike?.reason == "Not for me")
    }

    @Test("dislike does not duplicate")
    func dislike_doesNotDuplicate() throws {
        let aff = Affirmation(id: "aff_1", text: "Test")
        context.insert(aff)
        let existing = Dislike(affirmation: aff, reason: "first")
        context.insert(existing)
        try context.save()

        try service.dislike(affirmation: aff, reason: "second", modelContext: context)

        #expect(aff.dislike?.reason == "first")
    }

    @Test("undislike removes dislike")
    func undislike_removesDislike() throws {
        let aff = Affirmation(id: "aff_1", text: "Test")
        context.insert(aff)
        let dislike = Dislike(affirmation: aff)
        context.insert(dislike)
        try context.save()

        #expect(aff.isDisliked)

        try service.undislike(affirmation: aff, modelContext: context)

        #expect(!aff.isDisliked)
    }

    @Test("undislike is noop when not disliked")
    func undislike_noopWhenNotDisliked() throws {
        let aff = Affirmation(id: "aff_1", text: "Test")
        context.insert(aff)
        try context.save()

        try service.undislike(affirmation: aff, modelContext: context)
        #expect(!aff.isDisliked)
    }
}
