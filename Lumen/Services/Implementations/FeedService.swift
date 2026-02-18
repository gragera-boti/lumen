import Foundation
import SwiftData
import OSLog

final class FeedService: FeedServiceProtocol, @unchecked Sendable {
    static let shared = FeedService()
    private let logger = Logger(subsystem: "com.lumen.app", category: "FeedService")
    private let recentLimit = 50

    func nextAffirmation(
        preferences: UserPreferences,
        isPremium: Bool,
        modelContext: ModelContext
    ) throws -> Affirmation? {
        let candidates = try fetchCandidates(
            preferences: preferences,
            isPremium: isPremium,
            modelContext: modelContext
        )

        guard !candidates.isEmpty else {
            logger.warning("No candidates found, relaxing constraints…")
            return try relaxedFetch(preferences: preferences, modelContext: modelContext)
        }

        return weightedPick(from: candidates, preferences: preferences, modelContext: modelContext)
    }

    func dailyAffirmation(
        preferences: UserPreferences,
        isPremium: Bool,
        modelContext: ModelContext
    ) throws -> Affirmation? {
        // Deterministic daily pick based on date seed
        let candidates = try fetchCandidates(
            preferences: preferences,
            isPremium: isPremium,
            modelContext: modelContext
        )
        guard !candidates.isEmpty else { return nil }

        let daySeed = Calendar.current.ordinality(of: .day, in: .era, for: .now) ?? 0
        let index = daySeed % candidates.count
        return candidates[index]
    }

    func recordSeen(
        affirmation: Affirmation,
        source: SeenSource,
        modelContext: ModelContext
    ) throws {
        let event = SeenEvent(affirmation: affirmation, source: source)
        modelContext.insert(event)
        try modelContext.save()
    }

    // MARK: - Candidate query

    private func fetchCandidates(
        preferences: UserPreferences,
        isPremium: Bool,
        modelContext: ModelContext
    ) throws -> [Affirmation] {
        let selectedIds = preferences.selectedCategoryIds
        let gentleMode = preferences.gentleMode
        let includeSensitive = preferences.includeSensitiveTopics
        let tonePreset = preferences.tonePreset
        let includeSpiritual = preferences.contentFilters.spiritual

        // Get recently seen IDs to exclude
        let recentSeenIds = try recentlySeenIds(modelContext: modelContext)
        // Get disliked IDs to exclude
        let dislikedIds = try dislikedAffirmationIds(modelContext: modelContext)

        // Fetch all matching affirmations
        let descriptor = FetchDescriptor<Affirmation>()
        let allAffirmations = try modelContext.fetch(descriptor)

        return allAffirmations.filter { affirmation in
            // Category match
            let hasMatchingCategory = affirmation.categories.contains { selectedIds.contains($0.id) }
            guard hasMatchingCategory else { return false }

            // Exclude recently seen
            guard !recentSeenIds.contains(affirmation.id) else { return false }

            // Exclude disliked
            guard !dislikedIds.contains(affirmation.id) else { return false }

            // Sensitive topic filter
            if affirmation.isSensitiveTopic && !includeSensitive { return false }

            // Gentle mode: exclude high intensity and absolutes
            if gentleMode {
                if affirmation.intensity == .high { return false }
                if affirmation.isAbsolute { return false }
            }

            // Spiritual filter
            if affirmation.tone == .spiritual && !includeSpiritual { return false }

            // Premium gating
            if affirmation.isPremium && !isPremium { return false }

            return true
        }
    }

    private func relaxedFetch(
        preferences: UserPreferences,
        modelContext: ModelContext
    ) throws -> Affirmation? {
        // Relax: allow older seen items
        let descriptor = FetchDescriptor<Affirmation>()
        let all = try modelContext.fetch(descriptor)
        let selectedIds = preferences.selectedCategoryIds

        let relaxed = all.filter { aff in
            aff.categories.contains { selectedIds.contains($0.id) }
        }

        return relaxed.randomElement()
    }

    private func weightedPick(
        from candidates: [Affirmation],
        preferences: UserPreferences,
        modelContext: ModelContext
    ) -> Affirmation? {
        // Get recent favorite tags for similarity boost
        let favoriteTags = (try? recentFavoriteTags(limit: 20, modelContext: modelContext)) ?? []

        var scored: [(Affirmation, Double)] = candidates.map { affirmation in
            var score = 1.0

            // Tone match boost
            if affirmation.tone == preferences.tonePreset {
                score *= 1.15
            }

            // Tag similarity to favorites
            let overlap = Set(affirmation.tags).intersection(favoriteTags).count
            score *= 1.0 + min(Double(overlap), 3.0) * 0.08

            return (affirmation, score)
        }

        // Weighted random selection
        let totalWeight = scored.reduce(0) { $0 + $1.1 }
        guard totalWeight > 0 else { return candidates.randomElement() }

        var random = Double.random(in: 0..<totalWeight)
        for (affirmation, weight) in scored {
            random -= weight
            if random <= 0 { return affirmation }
        }

        return scored.last?.0
    }

    // MARK: - Helpers

    private func recentlySeenIds(modelContext: ModelContext) throws -> Set<String> {
        var descriptor = FetchDescriptor<SeenEvent>(
            sortBy: [SortDescriptor(\.seenAt, order: .reverse)]
        )
        descriptor.fetchLimit = recentLimit
        let events = try modelContext.fetch(descriptor)
        return Set(events.compactMap { $0.affirmation?.id })
    }

    private func dislikedAffirmationIds(modelContext: ModelContext) throws -> Set<String> {
        let descriptor = FetchDescriptor<Dislike>()
        let dislikes = try modelContext.fetch(descriptor)
        return Set(dislikes.compactMap { $0.affirmation?.id })
    }

    private func recentFavoriteTags(limit: Int, modelContext: ModelContext) throws -> Set<String> {
        var descriptor = FetchDescriptor<Favorite>(
            sortBy: [SortDescriptor(\.favoritedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        let favorites = try modelContext.fetch(descriptor)
        let tags = favorites.compactMap { $0.affirmation?.tags }.flatMap { $0 }
        return Set(tags)
    }
}
