import Foundation
import SwiftData
import OSLog

@MainActor @Observable
final class SettingsViewModel {
    var preferences: UserPreferences?
    var isPremium = false
    var errorMessage: String?

    private let preferencesService: PreferencesServiceProtocol
    private let entitlementService: EntitlementServiceProtocol
    private let logger = Logger(subsystem: "com.lumen.app", category: "Settings")

    init(
        preferencesService: PreferencesServiceProtocol = PreferencesService.shared,
        entitlementService: EntitlementServiceProtocol = EntitlementService.shared
    ) {
        self.preferencesService = preferencesService
        self.entitlementService = entitlementService
    }

    func load(modelContext: ModelContext) async {
        do {
            preferences = try preferencesService.getOrCreate(modelContext: modelContext)
            isPremium = await entitlementService.isPremium()
        } catch {
            logger.error("Settings load error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func save(modelContext: ModelContext) {
        do {
            preferences?.updatedAt = .now
            try preferencesService.save(modelContext: modelContext)
        } catch {
            logger.error("Settings save error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func exportData(modelContext: ModelContext) -> Data? {
        // Export favorites and custom affirmations as JSON
        do {
            let favorites = try FavoriteService.shared.fetchFavorites(modelContext: modelContext)
            let texts = favorites.map { $0.text }
            return try JSONEncoder().encode(texts)
        } catch {
            logger.error("Export error: \(error.localizedDescription)")
            return nil
        }
    }

    func deleteAllData(modelContext: ModelContext) {
        do {
            try modelContext.delete(model: Favorite.self)
            try modelContext.delete(model: SeenEvent.self)
            try modelContext.delete(model: Dislike.self)
            try modelContext.delete(model: UserPreferences.self)
            try modelContext.save()

            // Re-create defaults
            let prefs = UserPreferences()
            modelContext.insert(prefs)
            try modelContext.save()
            preferences = prefs
        } catch {
            logger.error("Delete all data error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
}
