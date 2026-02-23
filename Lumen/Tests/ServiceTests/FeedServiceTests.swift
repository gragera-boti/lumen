import Foundation
import SwiftData
import Testing

@testable import Lumen

@Suite("FeedService Tests")
@MainActor struct FeedServiceTests {
    private var container: ModelContainer
    private var context: ModelContext
    private let service = FeedService.shared

    init() throws {
        let schema = Schema([
            Affirmation.self,
            Lumen.Category.self,
            Favorite.self,
            SeenEvent.self,
            Dislike.self,
            AppTheme.self,
            UserPreferences.self,
            EntitlementState.self,
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        context = ModelContext(container)
    }

    // MARK: - Helpers

    private func makeCategory(id: String = "cat_calm", name: String = "Calm") -> Lumen.Category {
        let cat = Lumen.Category(id: id, name: name)
        context.insert(cat)
        return cat
    }

    private func makeAffirmation(
        id: String = UUID().uuidString,
        text: String = "Test affirmation",
        tone: Tone = .gentle,
        intensity: Intensity = .low,
        isAbsolute: Bool = false,
        isSensitive: Bool = false,
        isPremium: Bool = false,
        category: Lumen.Category
    ) -> Affirmation {
        let aff = Affirmation(
            id: id,
            text: text,
            tone: tone,
            intensity: intensity,
            isAbsolute: isAbsolute,
            isSensitiveTopic: isSensitive,
            isPremium: isPremium,
            tags: ["test"]
        )
        context.insert(aff)
        aff.categories.append(category)
        return aff
    }

    private func makePreferences(
        categoryIds: [String] = ["cat_calm"],
        tone: Tone = .gentle,
        gentleMode: Bool = true,
        includeSensitive: Bool = false
    ) -> UserPreferences {
        let prefs = UserPreferences(
            tonePreset: tone,
            gentleMode: gentleMode,
            selectedCategoryIds: categoryIds,
            includeSensitiveTopics: includeSensitive
        )
        context.insert(prefs)
        try? context.save()
        return prefs
    }

    // MARK: - nextAffirmation

    @Test("nextAffirmation returns candidate matching category")
    func nextAffirmation_returnsCandidateMatchingCategory() throws {
        let cat = makeCategory()
        let aff = makeAffirmation(category: cat)
        try context.save()

        let prefs = makePreferences()
        let result = try service.nextAffirmation(preferences: prefs, isPremium: false, modelContext: context)

        #expect(result != nil)
        #expect(result?.id == aff.id)
    }

    @Test("nextAffirmation excludes wrong category")
    func nextAffirmation_excludesWrongCategory() throws {
        let cat1 = makeCategory(id: "cat_calm", name: "Calm")
        let cat2 = makeCategory(id: "cat_focus", name: "Focus")
        _ = makeAffirmation(category: cat2)
        try context.save()

        let prefs = makePreferences(categoryIds: [cat1.id])
        let result = try service.nextAffirmation(preferences: prefs, isPremium: false, modelContext: context)

        #expect(result == nil)
    }

    @Test("nextAffirmation gentle mode excludes high intensity")
    func nextAffirmation_gentleMode_excludesHighIntensity() throws {
        let cat = makeCategory()
        _ = makeAffirmation(intensity: .high, category: cat)
        try context.save()

        let prefs = makePreferences(gentleMode: true)
        let result = try service.nextAffirmation(preferences: prefs, isPremium: false, modelContext: context)

        #expect(result == nil)
    }

    @Test("nextAffirmation gentle mode excludes absolute")
    func nextAffirmation_gentleMode_excludesAbsolute() throws {
        let cat = makeCategory()
        _ = makeAffirmation(isAbsolute: true, category: cat)
        try context.save()

        let prefs = makePreferences(gentleMode: true)
        let result = try service.nextAffirmation(preferences: prefs, isPremium: false, modelContext: context)

        #expect(result == nil)
    }

    @Test("nextAffirmation gentle mode off allows high intensity")
    func nextAffirmation_gentleModeOff_allowsHighIntensity() throws {
        let cat = makeCategory()
        let aff = makeAffirmation(intensity: .high, category: cat)
        try context.save()

        let prefs = makePreferences(gentleMode: false)
        let result = try service.nextAffirmation(preferences: prefs, isPremium: false, modelContext: context)

        #expect(result?.id == aff.id)
    }

    @Test("nextAffirmation excludes sensitive when not opted in")
    func nextAffirmation_excludesSensitiveWhenNotOptedIn() throws {
        let cat = makeCategory()
        _ = makeAffirmation(isSensitive: true, category: cat)
        try context.save()

        let prefs = makePreferences(includeSensitive: false)
        let result = try service.nextAffirmation(preferences: prefs, isPremium: false, modelContext: context)

        #expect(result == nil)
    }

    @Test("nextAffirmation includes sensitive when opted in")
    func nextAffirmation_includesSensitiveWhenOptedIn() throws {
        let cat = makeCategory()
        let aff = makeAffirmation(isSensitive: true, category: cat)
        try context.save()

        let prefs = makePreferences(includeSensitive: true)
        let result = try service.nextAffirmation(preferences: prefs, isPremium: false, modelContext: context)

        #expect(result?.id == aff.id)
    }

    @Test("nextAffirmation excludes premium when not premium")
    func nextAffirmation_excludesPremiumWhenNotPremium() throws {
        let cat = makeCategory()
        _ = makeAffirmation(isPremium: true, category: cat)
        try context.save()

        let prefs = makePreferences()
        let result = try service.nextAffirmation(preferences: prefs, isPremium: false, modelContext: context)

        #expect(result == nil)
    }

    @Test("nextAffirmation includes premium when premium")
    func nextAffirmation_includesPremiumWhenPremium() throws {
        let cat = makeCategory()
        let aff = makeAffirmation(isPremium: true, category: cat)
        try context.save()

        let prefs = makePreferences()
        let result = try service.nextAffirmation(preferences: prefs, isPremium: true, modelContext: context)

        #expect(result?.id == aff.id)
    }

    @Test("nextAffirmation excludes spiritual when filter off")
    func nextAffirmation_excludesSpiritualWhenFilterOff() throws {
        let cat = makeCategory()
        _ = makeAffirmation(tone: .spiritual, category: cat)
        try context.save()

        let prefs = makePreferences()
        let result = try service.nextAffirmation(preferences: prefs, isPremium: false, modelContext: context)

        #expect(result == nil)
    }

    // MARK: - dailyAffirmation

    @Test("dailyAffirmation returns same result on same day")
    func dailyAffirmation_returnsSameResultOnSameDay() throws {
        let cat = makeCategory()
        for i in 0..<5 {
            _ = makeAffirmation(id: "aff_\(i)", text: "Text \(i)", category: cat)
        }
        try context.save()

        let prefs = makePreferences()
        let result1 = try service.dailyAffirmation(preferences: prefs, isPremium: false, modelContext: context)
        let result2 = try service.dailyAffirmation(preferences: prefs, isPremium: false, modelContext: context)

        #expect(result1?.id == result2?.id)
    }

    @Test("dailyAffirmation returns nil when no candidates")
    func dailyAffirmation_returnsNilWhenNoCandidates() throws {
        let prefs = makePreferences()
        let result = try service.dailyAffirmation(preferences: prefs, isPremium: false, modelContext: context)

        #expect(result == nil)
    }

    // MARK: - recordSeen

    @Test("recordSeen creates seen event")
    func recordSeen_createsSeenEvent() throws {
        let cat = makeCategory()
        let aff = makeAffirmation(category: cat)
        try context.save()

        try service.recordSeen(affirmation: aff, source: .feed, modelContext: context)

        let descriptor = FetchDescriptor<SeenEvent>()
        let events = try context.fetch(descriptor)
        #expect(events.count == 1)
        #expect(events.first?.source == .feed)
    }
}
