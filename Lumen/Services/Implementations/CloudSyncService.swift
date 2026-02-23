import CloudKit
import Foundation
import OSLog

@MainActor
final class CloudSyncService: CloudSyncServiceProtocol {
    static let shared = CloudSyncService()

    private let logger = Logger(subsystem: "com.gragera.lumen", category: "CloudSync")
    private let defaults = UserDefaults.standard
    private let enabledKey = "lumen.cloudSync.enabled"
    private let lastSyncKey = "lumen.cloudSync.lastSync"

    func isSyncEnabled() -> Bool {
        defaults.bool(forKey: enabledKey)
    }

    func setSyncEnabled(_ enabled: Bool) {
        defaults.set(enabled, forKey: enabledKey)
        logger.info("iCloud sync \(enabled ? "enabled" : "disabled")")

        if enabled {
            // Post notification so the app can reconfigure the container
            NotificationCenter.default.post(name: .cloudSyncToggled, object: nil)
        }
    }

    /// Whether CloudKit container is configured in the app entitlements.
    private let isCloudKitConfigured = true

    func syncStatus() async -> CloudSyncStatus {
        guard isSyncEnabled() else { return .disabled }
        guard isCloudKitConfigured else {
            // CloudKit container not yet configured — report status from local state only
            if let lastSync = defaults.object(forKey: lastSyncKey) as? Date {
                return .synced(lastSync: lastSync)
            }
            return .syncing
        }

        do {
            let status = try await CKContainer.default().accountStatus()
            switch status {
            case .available:
                if let lastSync = defaults.object(forKey: lastSyncKey) as? Date {
                    return .synced(lastSync: lastSync)
                }
                return .syncing
            case .noAccount:
                return .noAccount
            case .restricted, .couldNotDetermine:
                return .error("iCloud unavailable")
            case .temporarilyUnavailable:
                return .error("iCloud temporarily unavailable")
            @unknown default:
                return .error("Unknown iCloud status")
            }
        } catch {
            return .error(error.localizedDescription)
        }
    }

    func markSynced() {
        defaults.set(Date(), forKey: lastSyncKey)
    }
}

extension Notification.Name {
    static let cloudSyncToggled = Notification.Name("lumen.cloudSyncToggled")
}
