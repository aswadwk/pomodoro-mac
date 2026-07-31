import Foundation
import Observation
import ServiceManagement

@MainActor
@Observable
final class SettingsStore {
    var focusMinutes: Int {
        didSet { persistence.save(focusMinutes, for: .focusMinutes) }
    }

    var shortBreakMinutes: Int {
        didSet { persistence.save(shortBreakMinutes, for: .shortBreakMinutes) }
    }

    var longBreakMinutes: Int {
        didSet { persistence.save(longBreakMinutes, for: .longBreakMinutes) }
    }

    var sessionsBeforeLongBreak: Int {
        didSet { persistence.save(sessionsBeforeLongBreak, for: .sessionsBeforeLongBreak) }
    }

    var autoStartBreaks: Bool {
        didSet { persistence.save(autoStartBreaks, for: .autoStartBreaks) }
    }

    var autoStartFocus: Bool {
        didSet { persistence.save(autoStartFocus, for: .autoStartFocus) }
    }

    var playSound: Bool {
        didSet { persistence.save(playSound, for: .playSound) }
    }

    var sendNotifications: Bool {
        didSet { persistence.save(sendNotifications, for: .sendNotifications) }
    }

    var pauseWhenIdle: Bool {
        didSet { persistence.save(pauseWhenIdle, for: .pauseWhenIdle) }
    }

    var launchAtLogin: Bool {
        didSet {
            guard launchAtLogin != oldValue else { return }
            try? launchAtLogin ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister()
        }
    }

    private let persistence: PersistenceService

    init(persistence: PersistenceService) {
        self.persistence = persistence
        focusMinutes = persistence.load(.focusMinutes, default: 25)
        shortBreakMinutes = persistence.load(.shortBreakMinutes, default: 5)
        longBreakMinutes = persistence.load(.longBreakMinutes, default: 15)
        sessionsBeforeLongBreak = persistence.load(.sessionsBeforeLongBreak, default: 4)
        autoStartBreaks = persistence.load(.autoStartBreaks, default: false)
        autoStartFocus = persistence.load(.autoStartFocus, default: false)
        playSound = persistence.load(.playSound, default: true)
        sendNotifications = persistence.load(.sendNotifications, default: true)
        pauseWhenIdle = persistence.load(.pauseWhenIdle, default: false)
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    func resetToDefaults() {
        focusMinutes = 25
        shortBreakMinutes = 5
        longBreakMinutes = 15
        sessionsBeforeLongBreak = 4
        autoStartBreaks = false
        autoStartFocus = false
        playSound = true
        sendNotifications = true
        pauseWhenIdle = false
        launchAtLogin = false
    }

    var focusDuration: TimeInterval {
        TimeInterval(focusMinutes * 60)
    }

    var shortBreakDuration: TimeInterval {
        TimeInterval(shortBreakMinutes * 60)
    }

    var longBreakDuration: TimeInterval {
        TimeInterval(longBreakMinutes * 60)
    }
}
