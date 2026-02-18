import Foundation

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var dayIdentifier: String {
        formatted(.dateTime.year().month().day())
    }

    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    func timeString() -> String {
        formatted(date: .omitted, time: .shortened)
    }
}
