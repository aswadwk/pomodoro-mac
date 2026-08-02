import Foundation
import Observation

@MainActor
@Observable
final class StatisticsService {
    struct DayStat: Identifiable {
        let id = UUID()
        let date: Date
        let focusMinutes: Int
        let breakMinutes: Int
    }

    private(set) var sessions: [PomodoroSession]
    private let persistence: PersistenceService
    private let calendar: Calendar
    private let now: () -> Date

    init(
        persistence: PersistenceService,
        calendar: Calendar = .current,
        now: @escaping () -> Date = { Date() }
    ) {
        self.persistence = persistence
        self.calendar = calendar
        self.now = now
        sessions = persistence.loadSessions()
    }

    func refresh() {
        sessions = persistence.loadSessions()
    }

    // MARK: - Today

    var focusSessionsToday: [PomodoroSession] {
        sessions.filter { $0.kind == .focus && calendar.isDate($0.date, inSameDayAs: now()) }
    }

    var breakSessionsToday: [PomodoroSession] {
        sessions.filter { $0.kind != .focus && calendar.isDate($0.date, inSameDayAs: now()) }
    }

    var focusTimeToday: TimeInterval {
        focusSessionsToday.reduce(0) { $0 + $1.duration }
    }

    var breakTimeToday: TimeInterval {
        breakSessionsToday.reduce(0) { $0 + $1.duration }
    }

    var productivityToday: Double {
        let total = focusTimeToday + breakTimeToday
        guard total > 0 else { return 0 }
        return focusTimeToday / total
    }

    // MARK: - This week

    private var weekStart: Date {
        let today = calendar.startOfDay(for: now())
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday - 2 + 7) % 7
        return calendar.date(byAdding: .day, value: -daysFromMonday, to: today) ?? today
    }

    private var weekEnd: Date {
        calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
    }

    private var sessionsThisWeek: [PomodoroSession] {
        sessions.filter { $0.date >= weekStart && $0.date <= weekEnd }
    }

    var focusSessionsThisWeek: [PomodoroSession] {
        sessionsThisWeek.filter { $0.kind == .focus }
    }

    var focusTimeThisWeek: TimeInterval {
        focusSessionsThisWeek.reduce(0) { $0 + $1.duration }
    }

    var breakTimeThisWeek: TimeInterval {
        sessionsThisWeek.filter { $0.kind != .focus }.reduce(0) { $0 + $1.duration }
    }

    var averageFocusPerDayThisWeek: TimeInterval {
        let daysElapsed = max(1, calendar.dateComponents([.day], from: weekStart, to: now()).day ?? 1)
        return focusTimeThisWeek / TimeInterval(daysElapsed)
    }

    var currentStreak: Int {
        let focusDays = Set(sessions.filter { $0.kind == .focus }.map { calendar.startOfDay(for: $0.date) })
        var day = calendar.startOfDay(for: now())
        if !focusDays.contains(day) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day) else { return 0 }
            guard focusDays.contains(yesterday) else { return 0 }
            day = yesterday
        }
        var streak = 0
        while focusDays.contains(day) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return streak
    }

    var thisWeek: [DayStat] {
        let grouped = Dictionary(grouping: sessionsThisWeek) { calendar.startOfDay(for: $0.date) }
        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: weekStart) else { return nil }
            let daySessions = grouped[date] ?? []
            return DayStat(
                date: date,
                focusMinutes: daySessions.filter { $0.kind == .focus }.reduce(0) { $0 + Int($1.duration) / 60 },
                breakMinutes: daySessions.filter { $0.kind != .focus }.reduce(0) { $0 + Int($1.duration) / 60 }
            )
        }
    }

    // MARK: - All time

    var totalFocusTime: TimeInterval {
        sessions.filter { $0.kind == .focus }.reduce(0) { $0 + $1.duration }
    }

    var totalFocusSessions: Int {
        sessions.filter { $0.kind == .focus }.count
    }

    // MARK: - Formatting

    func formattedTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let hours = minutes / 60
        return hours > 0 ? "\(hours)h \(minutes % 60)m" : "\(minutes)m"
    }
}
