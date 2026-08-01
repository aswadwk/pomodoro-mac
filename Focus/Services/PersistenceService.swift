import Foundation

enum PersistenceKey: String {
    case sessions = "focus.sessions"
    case focusMinutes = "settings.focusMinutes"
    case shortBreakMinutes = "settings.shortBreakMinutes"
    case longBreakMinutes = "settings.longBreakMinutes"
    case sessionsBeforeLongBreak = "settings.sessionsBeforeLongBreak"
    case autoStartBreaks = "settings.autoStartBreaks"
    case autoStartFocus = "settings.autoStartFocus"
    case playSound = "settings.playSound"
    case soundName = "settings.soundName"
    case sendNotifications = "settings.sendNotifications"
    case pauseWhenIdle = "settings.pauseWhenIdle"
}

struct PersistenceService {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadSessions() -> [PomodoroSession] {
        load(.sessions, default: [])
    }

    func saveSessions(_ sessions: [PomodoroSession]) {
        save(sessions, for: .sessions)
    }

    func load<T: Codable>(_ key: PersistenceKey, default defaultValue: T) -> T {
        guard let data = defaults.data(forKey: key.rawValue) else { return defaultValue }
        return (try? JSONDecoder().decode(T.self, from: data)) ?? defaultValue
    }

    func save<T: Codable>(_ value: T, for key: PersistenceKey) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key.rawValue)
    }
}
