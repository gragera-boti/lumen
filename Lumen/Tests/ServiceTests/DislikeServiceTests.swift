import XCTest
import SwiftData
@testable import Lumen

@MainActor
final class DislikeServiceTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private let service = DislikeService.shared

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

    func test_dislike_createsDislike() throws {
        let aff = Affirmation(id: "aff_1", text: "Test")
        context.insert(aff)
        try context.save()

        try service.dislike(affirmation: aff, reason: "Not for me", modelContext: context)

        XCTAssertTrue(aff.isDisliked)
        XCTAssertEqual(aff.dislike?.reason, "Not for me")
    }

    func test_dislike_doesNotDuplicate() throws {
        let aff = Affirmation(id: "aff_1", text: "Test")
        context.insert(aff)
        let existing = Dislike(affirmation: aff, reason: "first")
        context.insert(existing)
        try context.save()

        try service.dislike(affirmation: aff, reason: "second", modelContext: context)

        // Should still have the first reason
        XCTAssertEqual(aff.dislike?.reason, "first")
    }

    func test_undislike_removesDislike() throws {
        let aff = Affirmation(id: "aff_1", text: "Test")
        context.insert(aff)
        let dislike = Dislike(affirmation: aff)
        context.insert(dislike)
        try context.save()

        XCTAssertTrue(aff.isDisliked)

        try service.undislike(affirmation: aff, modelContext: context)

        XCTAssertFalse(aff.isDisliked)
    }

    func test_undislike_noopWhenNotDisliked() throws {
        let aff = Affirmation(id: "aff_1", text: "Test")
        context.insert(aff)
        try context.save()

        // Should not throw
        try service.undislike(affirmation: aff, modelContext: context)
        XCTAssertFalse(aff.isDisliked)
    }
}
