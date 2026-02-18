import Foundation
import SwiftData
import UIKit
import OSLog

@MainActor @Observable
final class FeedViewModel {
    // MARK: - State

    var cards: [Affirmation] = []
    var currentIndex: Int = 0
    var dailyAffirmation: Affirmation?
    var isPlayingTTS = false
    var isLoading = false
    var errorMessage: String?
    var showRelaxFiltersPrompt = false

    var currentCard: Affirmation? {
        guard currentIndex >= 0, currentIndex < cards.count else { return nil }
        return cards[currentIndex]
    }

    // MARK: - Dependencies

    private let feedService: FeedServiceProtocol
    private let favoriteService: FavoriteServiceProtocol
    private let speechService: SpeechServiceProtocol
    private let shareService: ShareServiceProtocol
    private let logger = Logger(subsystem: "com.lumen.app", category: "Feed")

    init(
        feedService: FeedServiceProtocol = FeedService.shared,
        favoriteService: FavoriteServiceProtocol = FavoriteService.shared,
        speechService: SpeechServiceProtocol = SpeechService.shared,
        shareService: ShareServiceProtocol = ShareService.shared
    ) {
        self.feedService = feedService
        self.favoriteService = favoriteService
        self.speechService = speechService
        self.shareService = shareService
    }

    // MARK: - Actions

    func loadFeed(preferences: UserPreferences, isPremium: Bool, modelContext: ModelContext) {
        isLoading = true
        defer { isLoading = false }

        do {
            // Load daily affirmation
            dailyAffirmation = try feedService.dailyAffirmation(
                preferences: preferences,
                isPremium: isPremium,
                modelContext: modelContext
            )

            // Pre-load batch of cards
            var batch: [Affirmation] = []
            let seen = Set<String>()
            for _ in 0..<20 {
                if let next = try feedService.nextAffirmation(
                    preferences: preferences,
                    isPremium: isPremium,
                    modelContext: modelContext
                ), !seen.contains(next.id) {
                    batch.append(next)
                }
            }

            if batch.isEmpty {
                showRelaxFiltersPrompt = true
            } else {
                cards = batch
                currentIndex = 0
                showRelaxFiltersPrompt = false
            }
        } catch {
            logger.error("Feed load error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func loadMoreIfNeeded(preferences: UserPreferences, isPremium: Bool, modelContext: ModelContext) {
        guard currentIndex >= cards.count - 5 else { return }

        do {
            for _ in 0..<10 {
                if let next = try feedService.nextAffirmation(
                    preferences: preferences,
                    isPremium: isPremium,
                    modelContext: modelContext
                ) {
                    cards.append(next)
                }
            }
        } catch {
            logger.error("Load more error: \(error.localizedDescription)")
        }
    }

    func recordSeen(modelContext: ModelContext) {
        guard let card = currentCard else { return }
        do {
            try feedService.recordSeen(affirmation: card, source: .feed, modelContext: modelContext)
        } catch {
            logger.error("Record seen error: \(error.localizedDescription)")
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

    func toggleTTS(voice: VoiceSettings) {
        guard let card = currentCard else { return }

        if isPlayingTTS {
            speechService.stop()
            isPlayingTTS = false
        } else {
            isPlayingTTS = true
            Task {
                await speechService.speak(text: card.text, voice: voice)
                isPlayingTTS = false
            }
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
}
