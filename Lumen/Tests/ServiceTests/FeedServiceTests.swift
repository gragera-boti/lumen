import XCTest
import SwiftData
@testable import Lumen

@MainActor
final class FeedServiceTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private let service = FeedService.shared

    override func setUp() async throws {
        let schema = Schema([
            Affirmation.self,
            Lumen.Category.self,
            Favorite.self,
            SeenEvent.self,
            Dislike.self,
            AppTheme.self,
            UserPreferences.self,
            EntitlementState.self,
            MoodEntry.self,
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        context = ModelContext(container)
    }

    override func tearDown() {
        container = nil
        context = nil
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

    func test_nextAffirmation_returnsCandidateMatchingCategory() throws {
        let cat = makeCategory()
        let aff = makeAffirmation(category: cat)
        try context.save()

        let prefs = makePreferences()
        let result = try service.nextAffirmation(preferences: prefs, isPremium: false, mood: nil, modelContext: context)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.id, aff.id)
    }

    func test_nextAffirmation_excludesWrongCategory() throws {
        let cat1 = makeCategory(id: "cat_calm", name: "Calm")
        let cat2 = makeCategory(id: "cat_focus", name: "Focus")
        _ = makeAffirmation(category: cat2)
        try context.save()

        let prefs = makePreferences(categoryIds: [cat1.id])
        let result = try service.nextAffirmation(preferences: prefs, isPremium: false, mood: nil, modelContext: context)

        XCTAssertNil(result)
    }

    func test_nextAffirmation_gentleMode_excludesHighIntensity() throws {
        let cat = makeCategory()
        _ = makeAffirmation(intensity: .high, category: cat)
        try context.save()

        let prefs = makePreferences(gentleMode: true)
        let result = try service.nextAffirmation(preferences: prefs, isPremium: false, mood: nil, modelContext: context)

        XCTAssertNil(result)
    }

    func test_nextAffirmation_gentleMode_excludesAbsolute() throws {
        let cat = makeCategory()
        _ = makeAffirmation(isAbsolute: true, category: cat)
        try context.save()

        let prefs = makePreferences(gentleMode: true)
        let result = try service.nextAffirmation(preferences: prefs, isPremium: false, mood: nil, modelContext: context)

        XCTAssertNil(result)
    }

    func test_nextAffirmation_gentleModeOff_allowsHighIntensity() throws {
        let cat = makeCategory()
        let aff = makeAffirmation(intensity: .high, category: cat)
        try context.save()

        let prefs = makePreferences(gentleMode: false)
        let result = try service.nextAffirmation(preferences: prefs, isPremium: false, mood: nil, modelContext: context)

        XCTAssertEqual(result?.id, aff.id)
    }

    func test_nextAffirmation_excludesSensitiveWhenNotOptedIn() throws {
        let cat = makeCategory()
        _ = makeAffirmation(isSensitive: true, category: cat)
        try context.save()

        let prefs = makePreferences(includeSensitive: false)
        let result = try service.nextAffirmation(preferences: prefs, isPremium: false, mood: nil, modelContext: context)

        XCTAssertNil(result)
    }

    func test_nextAffirmation_includesSensitiveWhenOptedIn() throws {
        let cat = makeCategory()
        let aff = makeAffirmation(isSensitive: true, category: cat)
        try context.save()

        let prefs = makePreferences(includeSensitive: true)
        let result = try service.nextAffirmation(preferences: prefs, isPremium: false, mood: nil, modelContext: context)

        XCTAssertEqual(result?.id, aff.id)
    }

    func test_nextAffirmation_excludesPremiumWhenNotPremium() throws {
        let cat = makeCategory()
        _ = makeAffirmation(isPremium: true, category: cat)
        try context.save()

        let prefs = makePreferences()
        let result = try service.nextAffirmation(preferences: prefs, isPremium: false, mood: nil, modelContext: context)

        XCTAssertNil(result)
    }

    func test_nextAffirmation_includesPremiumWhenPremium() throws {
        let cat = makeCategory()
        let aff = makeAffirmation(isPremium: true, category: cat)
        try context.save()

        let prefs = makePreferences()
        let result = try service.nextAffirmation(preferences: prefs, isPremium: true, mood: nil, modelContext: context)

        XCTAssertEqual(result?.id, aff.id)
    }

    func test_nextAffirmation_excludesSpiritualWhenFilterOff() throws {
        let cat = makeCategory()
        _ = makeAffirmation(tone: .spiritual, category: cat)
        try context.save()

        // Default content filters have spiritual = false
        let prefs = makePreferences()
        let result = try service.nextAffirmation(preferences: prefs, isPremium: false, mood: nil, modelContext: context)

        XCTAssertNil(result)
    }

    // MARK: - dailyAffirmation

    func test_dailyAffirmation_returnsSameResultOnSameDay() throws {
        let cat = makeCategory()
        for i in 0..<5 {
            _ = makeAffirmation(id: "aff_\(i)", text: "Text \(i)", category: cat)
        }
        try context.save()

        let prefs = makePreferences()
        let result1 = try service.dailyAffirmation(preferences: prefs, isPremium: false, mood: nil, modelContext: context)
        let result2 = try service.dailyAffirmation(preferences: prefs, isPremium: false, mood: nil, modelContext: context)

        XCTAssertEqual(result1?.id, result2?.id)
    }

    func test_dailyAffirmation_returnsNilWhenNoCandidates() throws {
        let prefs = makePreferences()
        let result = try service.dailyAffirmation(preferences: prefs, isPremium: false, mood: nil, modelContext: context)

        XCTAssertNil(result)
    }

    // MARK: - recordSeen

    func test_recordSeen_createsSeenEvent() throws {
        let cat = makeCategory()
        let aff = makeAffirmation(category: cat)
        try context.save()

        try service.recordSeen(affirmation: aff, source: .feed, modelContext: context)

        let descriptor = FetchDescriptor<SeenEvent>()
        let events = try context.fetch(descriptor)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.source, .feed)
    }
}
