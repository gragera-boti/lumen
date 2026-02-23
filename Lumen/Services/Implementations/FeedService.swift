import Foundation
import SwiftData
import OSLog

struct FeedService: FeedServiceProtocol {
    static let shared = FeedService()
    private let logger = Logger(subsystem: "com.gragera.lumen", category: "FeedService")
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

    func loadBatch(
        count: Int,
        preferences: UserPreferences,
        isPremium: Bool,
        modelContext: ModelContext
    ) throws -> (daily: Affirmation?, feed: [Affirmation]) {
        let allAffirmations = try modelContext.fetch(FetchDescriptor<Affirmation>())
        let recentSeenIds = try recentlySeenIds(modelContext: modelContext)
        let dislikedIds = try dislikedAffirmationIds(modelContext: modelContext)

        let selectedIds = preferences.selectedCategoryIds
        let gentleMode = preferences.gentleMode
        let includeSensitive = preferences.includeSensitiveTopics
        let includeSpiritual = preferences.contentFilters.spiritual

        let candidates = allAffirmations.filter { affirmation in
            let hasMatchingCategory = affirmation.categories.contains { selectedIds.contains($0.id) }
            guard hasMatchingCategory else { return false }
            guard !recentSeenIds.contains(affirmation.id) else { return false }
            guard !dislikedIds.contains(affirmation.id) else { return false }
            if affirmation.isSensitiveTopic && !includeSensitive { return false }
            if gentleMode {
                if affirmation.intensity == .high { return false }
                if affirmation.isAbsolute { return false }
            }
            if affirmation.tone == .spiritual && !includeSpiritual { return false }
            if affirmation.isPremium && !isPremium { return false }
            return true
        }

        // Daily affirmation
        let daily: Affirmation?
        if candidates.isEmpty {
            daily = nil
        } else {
            let daySeed = Calendar.current.ordinality(of: .day, in: .era, for: .now) ?? 0
            daily = candidates[daySeed % candidates.count]
        }

        // Weighted batch pick (no duplicates)
        let favoriteTags = (try? recentFavoriteTags(limit: 20, modelContext: modelContext)) ?? []
        let preferredTones: [Tone] = [preferences.tonePreset]

        let scored: [(Affirmation, Double)] = candidates.map { affirmation in
            var score = 1.0
            if preferredTones.contains(affirmation.tone) {
                let toneIndex = preferredTones.firstIndex(of: affirmation.tone) ?? 0
                score *= toneIndex == 0 ? 1.3 : 1.15
            }
            let overlap = Set(affirmation.tags).intersection(favoriteTags).count
            score *= 1.0 + min(Double(overlap), 3.0) * 0.08
            return (affirmation, score)
        }

        var feed: [Affirmation] = []
        var usedIds = Set<String>()
        var remaining = scored

        for _ in 0..<count {
            guard !remaining.isEmpty else { break }

            let totalWeight = remaining.reduce(0) { $0 + $1.1 }
            guard totalWeight > 0 else { break }

            var random = Double.random(in: 0..<totalWeight)
            var pickedIndex = remaining.count - 1

            for (i, (_, weight)) in remaining.enumerated() {
                random -= weight
                if random <= 0 {
                    pickedIndex = i
                    break
                }
            }

            let picked = remaining[pickedIndex].0
            if !usedIds.contains(picked.id) {
                feed.append(picked)
                usedIds.insert(picked.id)
            }
            remaining.remove(at: pickedIndex)
        }

        return (daily, feed)
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
        let includeSpiritual = preferences.contentFilters.spiritual

        let recentSeenIds = try recentlySeenIds(modelContext: modelContext)
        let dislikedIds = try dislikedAffirmationIds(modelContext: modelContext)

        let allAffirmations = try modelContext.fetch(FetchDescriptor<Affirmation>())

        return allAffirmations.filter { affirmation in
            let hasMatchingCategory = affirmation.categories.contains { selectedIds.contains($0.id) }
            guard hasMatchingCategory else { return false }
            guard !recentSeenIds.contains(affirmation.id) else { return false }
            guard !dislikedIds.contains(affirmation.id) else { return false }
            if affirmation.isSensitiveTopic && !includeSensitive { return false }
            if gentleMode {
                if affirmation.intensity == .high { return false }
                if affirmation.isAbsolute { return false }
            }
            if affirmation.tone == .spiritual && !includeSpiritual { return false }
            if affirmation.isPremium && !isPremium { return false }
            return true
        }
    }

    private func relaxedFetch(
        preferences: UserPreferences,
        modelContext: ModelContext
    ) throws -> Affirmation? {
        let allAffirmations = try modelContext.fetch(FetchDescriptor<Affirmation>())
        let selectedIds = preferences.selectedCategoryIds

        let relaxed = allAffirmations.filter { aff in
            aff.categories.contains { selectedIds.contains($0.id) }
        }

        return relaxed.randomElement()
    }

    private func weightedPick(
        from candidates: [Affirmation],
        preferences: UserPreferences,
        modelContext: ModelContext
    ) -> Affirmation? {
        let favoriteTags = (try? recentFavoriteTags(limit: 20, modelContext: modelContext)) ?? []
        let preferredTones: [Tone] = [preferences.tonePreset]

        let scored: [(Affirmation, Double)] = candidates.map { affirmation in
            var score = 1.0
            if preferredTones.contains(affirmation.tone) {
                let toneIndex = preferredTones.firstIndex(of: affirmation.tone) ?? 0
                score *= toneIndex == 0 ? 1.3 : 1.15
            }
            let overlap = Set(affirmation.tags).intersection(favoriteTags).count
            score *= 1.0 + min(Double(overlap), 3.0) * 0.08
            return (affirmation, score)
        }

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
