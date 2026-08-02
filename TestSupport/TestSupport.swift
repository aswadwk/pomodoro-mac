import Foundation

enum TestSupport {
    static func makeIsolatedDefaults() -> UserDefaults {
        let suiteName = "FocusTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            fatalError("Failed to create isolated test UserDefaults suite")
        }
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    static func makeUTCCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    static func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12, _ minute: Int = 0, calendar: Calendar) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components)!
    }
}
