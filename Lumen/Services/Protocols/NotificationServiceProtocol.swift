import Foundation

protocol NotificationServiceProtocol: Sendable {
    func requestPermission() async throws -> Bool
    func scheduleReminders(settings: ReminderSettings, affirmationTexts: [String]) async throws
    func cancelAllReminders() async
    func permissionStatus() async -> NotificationPermission
}

enum NotificationPermission: Sendable {
    case unknown
    case granted
    case denied
}
