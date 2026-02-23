import Foundation
import OSLog
import UserNotifications

@MainActor
final class NotificationService: NotificationServiceProtocol {
    static let shared = NotificationService()
    private let logger = Logger(subsystem: "com.gragera.lumen", category: "NotificationService")
    private let center = UNUserNotificationCenter.current()

    func requestPermission() async throws -> Bool {
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        logger.info("Notification permission: \(granted)")
        return granted
    }

    func permissionStatus() async -> NotificationPermission {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return .granted
        case .denied:
            return .denied
        case .notDetermined:
            return .unknown
        @unknown default:
            return .unknown
        }
    }

    func scheduleReminders(settings: ReminderSettings, affirmationTexts: [String]) async throws {
        await cancelAllReminders()

        guard settings.enabled, settings.countPerDay > 0 else { return }
        guard !affirmationTexts.isEmpty else { return }

        let windowStart = settings.windowStartDate
        let windowEnd = settings.windowEndDate

        guard let startHour = windowStart.hour,
            let startMinute = windowStart.minute,
            let endHour = windowEnd.hour,
            let endMinute = windowEnd.minute
        else { return }

        let startMinutes = startHour * 60 + startMinute
        let endMinutes = endHour * 60 + endMinute
        let totalMinutes = endMinutes > startMinutes ? endMinutes - startMinutes : (1440 - startMinutes) + endMinutes
        let interval = totalMinutes / max(settings.countPerDay, 1)

        // Schedule for next 7 days
        for day in 0..<7 {
            for i in 0..<settings.countPerDay {
                let offsetMinutes = startMinutes + i * interval + Int.random(in: -5...5)
                let hour = (offsetMinutes / 60) % 24
                let minute = offsetMinutes % 60

                var dateComponents = DateComponents()
                dateComponents.hour = hour
                dateComponents.minute = minute

                let calendar = Calendar.current
                guard let targetDate = calendar.date(byAdding: .day, value: day, to: .now),
                    let scheduled = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: targetDate),
                    scheduled > .now
                else { continue }

                let affirmationText = affirmationTexts[
                    (day * settings.countPerDay + i) % affirmationTexts.count
                ]

                let content = UNMutableNotificationContent()
                content.title = "Lumen"
                content.body = affirmationText
                content.sound = .default

                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: scheduled),
                    repeats: false
                )

                let request = UNNotificationRequest(
                    identifier: "lumen_reminder_\(day)_\(i)",
                    content: content,
                    trigger: trigger
                )

                try await center.add(request)
            }
        }

        logger.info("Scheduled reminders for 7 days, \(settings.countPerDay)/day")
    }

    func cancelAllReminders() async {
        center.removeAllPendingNotificationRequests()
        logger.info("Cancelled all pending reminders")
    }
}
