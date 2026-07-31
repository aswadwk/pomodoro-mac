import Foundation
import Observation

@MainActor
@Observable
final class StatisticsService {
    struct DayStat: Identifiable {
        let id = UUID()
        let date: Date
        let focusMinutes: Int
    }

    private(set) var sessions: [PomodoroSession]
    private let persistence: PersistenceService

    init(persistence: PersistenceService) {
        self.persistence = persistence
        sessions = persistence.loadSessions()
    }

    func refresh() {
        sessions = persistence.loadSessions()
    }

    var focusSessionsToday: [PomodoroSession] {
        sessions.filter { $0.kind == .focus && Calendar.current.isDateInToday($0.date) }
    }

    var breakSessionsToday: [PomodoroSession] {
        sessions.filter { $0.kind != .focus && Calendar.current.isDateInToday($0.date) }
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

    var lastSevenDays: [DayStat] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let grouped = Dictionary(grouping: sessions) { calendar.startOfDay(for: $0.date) }
        return (0..<7).reversed().compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let minutes = (grouped[day] ?? [])
                .filter { $0.kind == .focus }
                .reduce(0) { $0 + Int($1.duration) / 60 }
            return DayStat(date: day, focusMinutes: minutes)
        }
    }

    func formattedTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let hours = minutes / 60
        return hours > 0 ? "\(hours)h \(minutes % 60)m" : "\(minutes)m"
    }
}
