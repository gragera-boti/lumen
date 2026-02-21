import Foundation

/// Service for managing local notification permissions and scheduling daily reminders.
@MainActor
protocol NotificationServiceProtocol: Sendable {
    /// Request notification authorization from the user.
    /// - Returns: `true` if permission was granted.
    func requestPermission() async throws -> Bool

    /// Schedule daily reminder notifications for the next 7 days.
    /// - Parameters:
    ///   - settings: The user's reminder timing and frequency preferences.
    ///   - affirmationTexts: Pool of affirmation texts to rotate through notifications.
    func scheduleReminders(settings: ReminderSettings, affirmationTexts: [String]) async throws

    /// Cancel all pending reminder notifications.
    func cancelAllReminders() async

    /// Query the current notification permission status without prompting the user.
    /// - Returns: The current ``NotificationPermission`` state.
    func permissionStatus() async -> NotificationPermission
}

enum NotificationPermission: Sendable {
    case unknown
    case granted
    case denied
}
