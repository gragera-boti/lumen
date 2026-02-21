import Foundation

/// iCloud sync service — premium-only feature.
protocol CloudSyncServiceProtocol: Sendable {
    /// Whether iCloud sync is currently enabled by the user.
    /// - Returns: `true` if sync is enabled.
    func isSyncEnabled() -> Bool

    /// Enable or disable iCloud sync. Posts a ``Notification.Name.cloudSyncToggled`` notification when enabled.
    /// - Parameter enabled: `true` to enable sync; `false` to disable.
    func setSyncEnabled(_ enabled: Bool)

    /// Query the current iCloud sync status.
    /// - Returns: The current ``CloudSyncStatus``.
    func syncStatus() async -> CloudSyncStatus

    /// Mark the current time as the last successful sync.
    func markSynced()
}

enum CloudSyncStatus: Equatable {
    case disabled
    case syncing
    case synced(lastSync: Date)
    case error(String)
    case noAccount

    var displayText: String {
        switch self {
        case .disabled: return "Sync is off"
        case .syncing: return "Syncing…"
        case .synced(let date):
            let fmt = RelativeDateTimeFormatter()
            fmt.unitsStyle = .short
            return "Synced \(fmt.localizedString(for: date, relativeTo: .now))"
        case .error(let msg): return "Sync error: \(msg)"
        case .noAccount: return "No iCloud account"
        }
    }
}
