import Foundation
import Observation

@MainActor
@Observable
final class TimerService {
    enum Phase: String, CaseIterable {
        case focus
        case shortBreak
        case longBreak

        var label: String {
            switch self {
            case .focus: "Focus"
            case .shortBreak: "Short Break"
            case .longBreak: "Long Break"
            }
        }
    }

    enum State: Equatable {
        case idle
        case running
        case paused
    }

    enum PhaseAlert {
        case focusFinished
        case breakFinished
    }

    var phase: Phase = .focus
    var state: State = .idle
    private(set) var secondsRemaining: TimeInterval
    private(set) var completedFocusSessions = 0
    var phaseAlert: PhaseAlert? {
        didSet { phaseAlertChanged?() }
    }
    var phaseAlertChanged: (() -> Void)?

    private let settings: SettingsStore
    private let persistence: PersistenceService
    private let startsTicking: Bool
    private let idleTime: () -> TimeInterval
    private let now: () -> Date
    private var tickTask: Task<Void, Never>?
    private var autoPaused = false

    private static let idlePauseThreshold: TimeInterval = 60

    init(
        settings: SettingsStore,
        persistence: PersistenceService,
        startsTicking: Bool = true,
        idleTime: @escaping () -> TimeInterval = { IdleDetectionService.secondsSinceLastInput() },
        now: @escaping () -> Date = { Date() }
    ) {
        self.settings = settings
        self.persistence = persistence
        self.startsTicking = startsTicking
        self.idleTime = idleTime
        self.now = now
        secondsRemaining = settings.focusDuration
        observeNotificationActions()
        startTicking()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    var totalDuration: TimeInterval {
        switch phase {
        case .focus: settings.focusDuration
        case .shortBreak: settings.shortBreakDuration
        case .longBreak: settings.longBreakDuration
        }
    }

    var elapsedFraction: Double {
        guard totalDuration > 0 else { return 0 }
        return 1 - (secondsRemaining / totalDuration)
    }

    var remainingLabel: String {
        let seconds = max(0, Int(secondsRemaining.rounded(.up)))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    var isRunning: Bool { state == .running }

    var isBreakPhase: Bool { phase != .focus }

    func start() {
        guard state == .idle else { return }
        if phaseAlert != nil {
            startNextPhase()
        } else {
            beginPhase()
        }
    }

    func togglePause() {
        switch state {
        case .running: pause()
        case .paused: resume()
        case .idle: break
        }
    }

    private func beginPhase() {
        secondsRemaining = totalDuration
        state = .running
    }

    private func pause() {
        guard state == .running else { return }
        state = .paused
    }

    private func resume() {
        guard state == .paused else { return }
        state = .running
    }

    func tick() {
        if settings.pauseWhenIdle, phase == .focus, state != .idle {
            let idle = idleTime()
            if state == .running, idle > Self.idlePauseThreshold {
                autoPaused = true
                state = .paused
            } else if autoPaused, state == .paused, idle <= Self.idlePauseThreshold {
                autoPaused = false
                state = .running
            }
        }

        guard state == .running else { return }
        secondsRemaining -= 1
        if secondsRemaining <= 0 {
            completePhase()
        }
    }

    private func completePhase() {
        recordCurrentPhase()
        NotificationService.removePending()
        if settings.playSound {
            SoundService.play(settings.soundName)
        }
        if settings.sendNotifications {
            switch phase {
            case .focus:
                NotificationService.scheduleBreakReminder()
            case .shortBreak, .longBreak:
                NotificationService.scheduleFocusReminder()
            }
        }
        state = .idle
        if shouldAutoStartNextPhase() {
            startNextPhase()
        } else {
            phaseAlert = phase == .focus ? .focusFinished : .breakFinished
        }
    }

    private func shouldAutoStartNextPhase() -> Bool {
        phase == .focus ? settings.autoStartBreaks : settings.autoStartFocus
    }

    func startNextPhase() {
        SoundService.stop()
        phaseAlert = nil
        advancePhase(startAutomatically: true)
    }

    func skipPhase() {
        SoundService.stop()
        NotificationService.removePending()
        phaseAlert = nil
        advancePhase(startAutomatically: false)
    }

    private func advancePhase(startAutomatically: Bool) {
        switch phase {
        case .focus:
            completedFocusSessions += 1
            phase = completedFocusSessions.isMultiple(of: settings.sessionsBeforeLongBreak)
                ? .longBreak
                : .shortBreak
        case .shortBreak, .longBreak:
            phase = .focus
        }
        secondsRemaining = totalDuration
        state = startAutomatically ? .running : .idle
    }

    private func recordCurrentPhase() {
        let kind: PomodoroSession.Kind
        switch phase {
        case .focus: kind = .focus
        case .shortBreak: kind = .shortBreak
        case .longBreak: kind = .longBreak
        }
        let session = PomodoroSession(kind: kind, date: now(), duration: totalDuration)
        persistence.saveSessions(persistence.loadSessions() + [session])
        NotificationCenter.default.post(name: .focusSessionCompleted, object: nil)
    }

    private func startTicking() {
        guard startsTicking else { return }
        tickTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                self?.tick()
            }
        }
    }

    private func observeNotificationActions() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleStartBreakAction(_:)),
            name: .focusStartBreakAction,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSkipAction(_:)),
            name: .focusSkipAction,
            object: nil
        )
    }

    @objc private func handleStartBreakAction(_ note: Notification) {
        startNextPhase()
    }

    @objc private func handleSkipAction(_ note: Notification) {
        skipPhase()
    }
}
