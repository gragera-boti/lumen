import Dependencies
import Foundation
import OSLog
import SwiftData

@MainActor @Observable
final class SettingsViewModel {
    var preferences: UserPreferences?
    var isPremium = false
    var errorMessage: String?
    var isCloudSyncEnabled = false
    var cloudSyncStatusText = ""

    @ObservationIgnored @Dependency(\.preferencesService) private var preferencesService
    @ObservationIgnored @Dependency(\.entitlementService) private var entitlementService
    @ObservationIgnored @Dependency(\.cloudSyncService) private var cloudSyncService
    private let logger = Logger(subsystem: "com.gragera.lumen", category: "Settings")

    func load(modelContext: ModelContext) async {
        do {
            preferences = try preferencesService.getOrCreate(modelContext: modelContext)
            isPremium = await entitlementService.isPremium()
            isCloudSyncEnabled = cloudSyncService.isSyncEnabled()
            let status = await cloudSyncService.syncStatus()
            cloudSyncStatusText = status.displayText
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

    func resetOnboarding(modelContext: ModelContext) {
        do {
            if let prefs = preferences {
                prefs.hasCompletedOnboarding = false
                prefs.selectedCategoryIds = []
                prefs.updatedAt = .now
                try preferencesService.save(modelContext: modelContext)
                logger.info("Onboarding reset")
            }
        } catch {
            logger.error("Reset onboarding error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func toggleCloudSync(_ enabled: Bool) {
        cloudSyncService.setSyncEnabled(enabled)
        isCloudSyncEnabled = enabled
        if enabled {
            cloudSyncStatusText = "iCloud sync enabled — syncing now"
        } else {
            cloudSyncStatusText = CloudSyncStatus.disabled.displayText
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
