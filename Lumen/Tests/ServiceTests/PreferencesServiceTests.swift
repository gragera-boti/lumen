import Foundation
import SwiftData
import Testing

@testable import Lumen

@Suite("PreferencesService Tests")
@MainActor struct PreferencesServiceTests {
    private var container: ModelContainer
    private var context: ModelContext
    private let service = PreferencesService.shared

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

    // MARK: - getOrCreate

    @Test("getOrCreate creates default preferences")
    func getOrCreate_createsDefaultPreferences() throws {
        let prefs = try service.getOrCreate(modelContext: context)

        #expect(prefs.locale == "en-GB")
        #expect(prefs.tonePreset == .gentle)
        #expect(prefs.gentleMode)
        #expect(prefs.selectedCategoryIds.isEmpty)
        #expect(!prefs.includeSensitiveTopics)
        #expect(!prefs.hasCompletedOnboarding)
        #expect(!prefs.analyticsOptOut)
    }

    @Test("getOrCreate returns existing preferences")
    func getOrCreate_returnsExistingPreferences() throws {
        let existing = UserPreferences(tonePreset: .energetic, selectedCategoryIds: ["cat_calm"])
        context.insert(existing)
        try context.save()

        let prefs = try service.getOrCreate(modelContext: context)

        #expect(prefs.tonePreset == .energetic)
        #expect(prefs.selectedCategoryIds == ["cat_calm"])
    }

    @Test("getOrCreate does not duplicate")
    func getOrCreate_doesNotDuplicate() throws {
        _ = try service.getOrCreate(modelContext: context)
        _ = try service.getOrCreate(modelContext: context)

        let descriptor = FetchDescriptor<UserPreferences>()
        let all = try context.fetch(descriptor)
        #expect(all.count == 1)
    }

    // MARK: - Codable nested types

    @Test("contentFilters round trips")
    func contentFilters_roundTrips() throws {
        let prefs = try service.getOrCreate(modelContext: context)

        var filters = prefs.contentFilters
        filters.spiritual = true
        filters.bodyFocus = true
        prefs.contentFilters = filters

        #expect(prefs.contentFilters.spiritual)
        #expect(prefs.contentFilters.bodyFocus)
        #expect(!prefs.contentFilters.manifestation)
    }

    @Test("reminderSettings round trips")
    func reminderSettings_roundTrips() throws {
        let prefs = try service.getOrCreate(modelContext: context)

        var reminders = prefs.reminders
        reminders.countPerDay = 5
        reminders.windowStart = "08:00"
        prefs.reminders = reminders

        #expect(prefs.reminders.countPerDay == 5)
        #expect(prefs.reminders.windowStart == "08:00")
    }
}
