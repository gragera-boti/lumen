import Foundation

struct ReminderSettings: Codable, Equatable {
    var enabled: Bool
    var countPerDay: Int
    var windowStart: String
    var windowEnd: String
    var quietStart: String
    var quietEnd: String

    static let defaults = ReminderSettings(
        enabled: false,
        countPerDay: 3,
        windowStart: "09:00",
        windowEnd: "21:00",
        quietStart: "22:00",
        quietEnd: "07:00"
    )

    var windowStartDate: DateComponents {
        parseTime(windowStart)
    }

    var windowEndDate: DateComponents {
        parseTime(windowEnd)
    }

    private func parseTime(_ time: String) -> DateComponents {
        let parts = time.split(separator: ":")
        var components = DateComponents()
        components.hour = Int(parts[0])
        components.minute = Int(parts[1])
        return components
    }
}
