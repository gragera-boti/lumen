import Foundation

/// iCloud sync service — premium-only feature.
protocol CloudSyncServiceProtocol: Sendable {
    /// Whether iCloud sync is enabled by the user.
    func isSyncEnabled() -> Bool

    /// Enable or disable iCloud sync. Requires premium.
    func setSyncEnabled(_ enabled: Bool)

    /// Current sync status description.
    func syncStatus() async -> CloudSyncStatus
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
