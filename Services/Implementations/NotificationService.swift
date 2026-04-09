import Foundation
import OSLog
import UserNotifications
import UIKit

@MainActor
final class NotificationService: NSObject, NotificationServiceProtocol, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()
    var pendingTapURL: URL?
    private let logger = Logger(subsystem: "com.gragera.lumen", category: "NotificationService")
    private let center = UNUserNotificationCenter.current()

    private override init() {
        super.init()
    }

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

    func scheduleReminders(settings: ReminderSettings, affirmations: [(id: String, text: String)]) async throws {
        await cancelAllReminders()

        guard settings.enabled, settings.countPerDay > 0 else { return }
        guard !affirmations.isEmpty else { return }

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

                let affirmation = affirmations[
                    (day * settings.countPerDay + i) % affirmations.count
                ]

                let content = UNMutableNotificationContent()
                content.title = "Lumen"
                content.body = affirmation.text
                content.sound = .default
                content.userInfo = ["affirmationId": affirmation.id]

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

    func scheduleTestReminder(id: String, text: String) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Lumen"
        content.body = text
        content.sound = .default
        content.userInfo = ["affirmationId": id]

        // Schedule for 5 seconds in the future
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(
            identifier: "lumen_reminder_test",
            content: content,
            trigger: trigger
        )
        try await center.add(request)
        logger.info("Scheduled test reminder for 5 seconds from now")
    }

    // MARK: - UNUserNotificationCenterDelegate

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        if let affirmationId = userInfo["affirmationId"] as? String,
           let url = URL(string: "lumen://affirmation/\(affirmationId)") {
            Task { @MainActor in
                NotificationService.shared.pendingTapURL = url
                NotificationCenter.default.post(name: Notification.Name("didReceiveNotificationTap"), object: url)
            }
        }
        completionHandler()
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .list])
        } else {
            completionHandler([.alert, .sound])
        }
    }
}
