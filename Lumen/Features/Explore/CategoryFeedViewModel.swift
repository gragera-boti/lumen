import Foundation
import SwiftData
import UIKit
import OSLog

@MainActor @Observable
final class CategoryFeedViewModel {
    // MARK: - State

    var cards: [Affirmation] = []
    var currentIndex: Int = 0
    var categoryName: String = ""
    var isLoading = false
    var errorMessage: String?

    var currentCard: Affirmation? {
        guard currentIndex >= 0, currentIndex < cards.count else { return nil }
        return cards[currentIndex]
    }

    // MARK: - Dependencies

    private let favoriteService: FavoriteServiceProtocol
    private let shareService: ShareServiceProtocol
    private let logger = Logger(subsystem: "com.gragera.lumen", category: "CategoryFeed")

    init(
        favoriteService: FavoriteServiceProtocol = FavoriteService.shared,
        shareService: ShareServiceProtocol = ShareService.shared
    ) {
        self.favoriteService = favoriteService
        self.shareService = shareService
    }

    // MARK: - Actions

    func loadCategory(
        categoryId: String,
        preferences: UserPreferences,
        isPremium: Bool,
        modelContext: ModelContext
    ) {
        isLoading = true
        defer { isLoading = false }

        do {
            // Fetch category
            var catDescriptor = FetchDescriptor<Category>(
                predicate: #Predicate { $0.id == categoryId }
            )
            catDescriptor.fetchLimit = 1
            if let category = try modelContext.fetch(catDescriptor).first {
                categoryName = category.name
            }

            // Fetch affirmations for this category
            let gentleMode = preferences.gentleMode
            let includeSensitive = preferences.includeSensitiveTopics
            let descriptor = FetchDescriptor<Affirmation>()
            let allAffirmations = try modelContext.fetch(descriptor)

            cards = allAffirmations.filter { affirmation in
                let belongsToCategory = affirmation.categories.contains { $0.id == categoryId }
                guard belongsToCategory else { return false }

                if affirmation.isSensitiveTopic && !includeSensitive { return false }
                if gentleMode && (affirmation.intensity == .high || affirmation.isAbsolute) { return false }
                if affirmation.isPremium && !isPremium { return false }

                return true
            }.shuffled()

            currentIndex = 0
        } catch {
            logger.error("Category feed load error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func toggleFavorite(modelContext: ModelContext) {
        guard let card = currentCard else { return }
        do {
            try favoriteService.toggleFavorite(affirmation: card, modelContext: modelContext)
        } catch {
            logger.error("Favorite error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func swipeToNext() {
        if currentIndex < cards.count - 1 {
            currentIndex += 1
        }
    }

    func swipeToPrevious() {
        if currentIndex > 0 {
            currentIndex -= 1
        }
    }

    func shareImage(isPremium: Bool) -> UIImage? {
        guard let card = currentCard else { return nil }
        let gradientIndex = abs(card.id.hashValue) % LumenTheme.Colors.gradients.count
        let colors = LumenTheme.Colors.gradients[gradientIndex]
        return shareService.renderShareImage(
            text: card.text,
            gradientColors: colors,
            size: CGSize(width: 1080, height: 1920),
            showWatermark: !isPremium
        )
    }
}
