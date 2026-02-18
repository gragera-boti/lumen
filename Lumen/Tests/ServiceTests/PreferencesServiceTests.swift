import XCTest
import SwiftData
@testable import Lumen

@MainActor
final class PreferencesServiceTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private let service = PreferencesService.shared

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

    // MARK: - getOrCreate

    func test_getOrCreate_createsDefaultPreferences() throws {
        let prefs = try service.getOrCreate(modelContext: context)

        XCTAssertEqual(prefs.locale, "en-GB")
        XCTAssertEqual(prefs.tonePreset, .gentle)
        XCTAssertTrue(prefs.gentleMode)
        XCTAssertTrue(prefs.selectedCategoryIds.isEmpty)
        XCTAssertFalse(prefs.includeSensitiveTopics)
        XCTAssertFalse(prefs.hasCompletedOnboarding)
        XCTAssertFalse(prefs.analyticsOptOut)
    }

    func test_getOrCreate_returnsExistingPreferences() throws {
        let existing = UserPreferences(tonePreset: .energetic, selectedCategoryIds: ["cat_calm"])
        context.insert(existing)
        try context.save()

        let prefs = try service.getOrCreate(modelContext: context)

        XCTAssertEqual(prefs.tonePreset, .energetic)
        XCTAssertEqual(prefs.selectedCategoryIds, ["cat_calm"])
    }

    func test_getOrCreate_doesNotDuplicate() throws {
        _ = try service.getOrCreate(modelContext: context)
        _ = try service.getOrCreate(modelContext: context)

        let descriptor = FetchDescriptor<UserPreferences>()
        let all = try context.fetch(descriptor)
        XCTAssertEqual(all.count, 1)
    }

    // MARK: - Codable nested types

    func test_contentFilters_roundTrips() throws {
        let prefs = try service.getOrCreate(modelContext: context)

        var filters = prefs.contentFilters
        filters.spiritual = true
        filters.bodyFocus = true
        prefs.contentFilters = filters

        XCTAssertTrue(prefs.contentFilters.spiritual)
        XCTAssertTrue(prefs.contentFilters.bodyFocus)
        XCTAssertFalse(prefs.contentFilters.manifestation)
    }

    func test_reminderSettings_roundTrips() throws {
        let prefs = try service.getOrCreate(modelContext: context)

        var reminders = prefs.reminders
        reminders.countPerDay = 5
        reminders.windowStart = "08:00"
        prefs.reminders = reminders

        XCTAssertEqual(prefs.reminders.countPerDay, 5)
        XCTAssertEqual(prefs.reminders.windowStart, "08:00")
    }

    func test_voiceSettings_roundTrips() throws {
        let prefs = try service.getOrCreate(modelContext: context)

        var voice = prefs.voice
        voice.rate = 1.3
        voice.language = "es-ES"
        prefs.voice = voice

        XCTAssertEqual(prefs.voice.rate, 1.3)
        XCTAssertEqual(prefs.voice.language, "es-ES")
    }
}
