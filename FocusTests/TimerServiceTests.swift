import Foundation
import XCTest
@testable import Focus

@MainActor
final class TimerServiceTests: XCTestCase {
    private var defaults: UserDefaults!
    private var persistence: PersistenceService!
    private var settings: SettingsStore!
    private var timer: TimerService!
    private var now: Date!
    private var completionNotified = false

    override func setUp() {
        super.setUp()
        defaults = TestSupport.makeIsolatedDefaults()
        persistence = PersistenceService(defaults: defaults)
        settings = SettingsStore(persistence: persistence)
        settings.playSound = false
        settings.sendNotifications = false
        settings.pauseWhenIdle = false
        now = TestSupport.date(2026, 8, 2, 12, 0, calendar: TestSupport.makeUTCCalendar())
        timer = makeTimer()
    }

    override func tearDown() {
        NotificationCenter.default.removeObserver(self)
        completionNotified = false
        timer = nil
        settings = nil
        persistence = nil
        defaults = nil
        now = nil
        super.tearDown()
    }

    private func makeTimer(idleTime: @escaping () -> TimeInterval = { 0 }) -> TimerService {
        TimerService(
            settings: settings,
            persistence: persistence,
            startsTicking: false,
            idleTime: idleTime,
            now: { self.now }
        )
    }

    private func observeSessionCompletion() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(markSessionCompleted),
            name: .focusSessionCompleted,
            object: nil
        )
    }

    @objc private func markSessionCompleted() {
        completionNotified = true
    }

    private func completePhase(_ ticks: Int) {
        for _ in 0..<ticks {
            timer.tick()
        }
    }

    // MARK: - Initial state

    func testInitialState() {
        XCTAssertEqual(timer.phase, .focus)
        XCTAssertEqual(timer.state, .idle)
        XCTAssertEqual(timer.secondsRemaining, settings.focusDuration)
        XCTAssertFalse(timer.isRunning)
        XCTAssertFalse(timer.isBreakPhase)
        XCTAssertEqual(timer.completedFocusSessions, 0)
        XCTAssertNil(timer.phaseAlert)
    }

    // MARK: - Start / pause / resume

    func testStartBeginsRunningWithFullDuration() {
        timer.start()

        XCTAssertEqual(timer.state, .running)
        XCTAssertEqual(timer.secondsRemaining, settings.focusDuration)
    }

    func testStartIsIgnoredWhileRunning() {
        timer.start()
        let remaining = timer.secondsRemaining
        timer.start()

        XCTAssertEqual(timer.state, .running)
        XCTAssertEqual(timer.secondsRemaining, remaining)
    }

    func testTickCountsDownOnlyWhileRunning() {
        timer.tick()
        XCTAssertEqual(timer.secondsRemaining, settings.focusDuration)

        timer.start()
        timer.tick()
        timer.tick()
        XCTAssertEqual(timer.secondsRemaining, settings.focusDuration - 2)
    }

    func testPauseAndResume() {
        timer.start()
        timer.togglePause()
        XCTAssertEqual(timer.state, .paused)

        let remaining = timer.secondsRemaining
        timer.tick()
        XCTAssertEqual(timer.secondsRemaining, remaining)

        timer.togglePause()
        XCTAssertEqual(timer.state, .running)
        timer.tick()
        XCTAssertEqual(timer.secondsRemaining, remaining - 1)
    }

    func testTogglePauseFromIdleIsNoOp() {
        timer.togglePause()
        XCTAssertEqual(timer.state, .idle)
    }

    // MARK: - Phase completion

    func testFocusPhaseCompletesRecordsSessionAndPostsNotification() {
        settings.focusMinutes = 1
        timer = makeTimer()
        observeSessionCompletion()
        timer.start()

        completePhase(60)

        XCTAssertEqual(timer.state, .idle)
        XCTAssertEqual(timer.phase, .focus)
        XCTAssertEqual(timer.completedFocusSessions, 1)
        guard case .focusFinished = timer.phaseAlert else {
            return XCTFail("Expected .focusFinished alert, got \(String(describing: timer.phaseAlert))")
        }
        XCTAssertTrue(completionNotified)

        let sessions = persistence.loadSessions()
        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(sessions[0].kind, .focus)
        XCTAssertEqual(sessions[0].duration, 60)
        XCTAssertEqual(sessions[0].date, now)
    }

    func testCompletingPhaseTwiceRecordsTwoSessions() {
        settings.focusMinutes = 1
        timer = makeTimer()
        timer.start()
        completePhase(60)
        timer.start()
        completePhase(60)

        XCTAssertEqual(persistence.loadSessions().count, 2)
    }

    func testNoAutoStartAfterFocusShowsAlert() {
        settings.focusMinutes = 1
        settings.autoStartBreaks = false
        timer = makeTimer()
        timer.start()
        completePhase(60)

        XCTAssertEqual(timer.state, .idle)
        XCTAssertEqual(timer.phase, .focus)
        guard case .focusFinished = timer.phaseAlert else {
            return XCTFail("Expected .focusFinished alert, got \(String(describing: timer.phaseAlert))")
        }
    }

    func testAutoStartBreakAfterFocus() {
        settings.focusMinutes = 1
        settings.autoStartBreaks = true
        timer = makeTimer()
        timer.start()
        completePhase(60)

        XCTAssertEqual(timer.phase, .shortBreak)
        XCTAssertEqual(timer.state, .running)
        XCTAssertEqual(timer.secondsRemaining, settings.shortBreakDuration)
        XCTAssertNil(timer.phaseAlert)
        XCTAssertTrue(timer.isBreakPhase)
        XCTAssertEqual(timer.completedFocusSessions, 1)
    }

    func testBreakCompletionReturnsToFocusWithoutCountingSession() {
        settings.focusMinutes = 1
        settings.shortBreakMinutes = 1
        settings.autoStartBreaks = true
        settings.autoStartFocus = true
        timer = makeTimer()
        timer.start()
        completePhase(60)
        completePhase(60)

        XCTAssertEqual(timer.phase, .focus)
        XCTAssertEqual(timer.state, .running)
        XCTAssertEqual(timer.completedFocusSessions, 1)
        XCTAssertEqual(persistence.loadSessions().count, 2)
    }

    func testLongBreakAfterConfiguredNumberOfFocusSessions() {
        settings.focusMinutes = 1
        settings.shortBreakMinutes = 1
        settings.longBreakMinutes = 2
        settings.sessionsBeforeLongBreak = 2
        settings.autoStartBreaks = true
        settings.autoStartFocus = true
        timer = makeTimer()

        timer.start()
        completePhase(60)
        XCTAssertEqual(timer.phase, .shortBreak)

        completePhase(60)
        XCTAssertEqual(timer.phase, .focus)

        completePhase(60)
        XCTAssertEqual(timer.phase, .longBreak)
        XCTAssertEqual(timer.secondsRemaining, settings.longBreakDuration)
        XCTAssertEqual(timer.completedFocusSessions, 2)

        completePhase(120)
        XCTAssertEqual(timer.phase, .focus)
        XCTAssertEqual(timer.completedFocusSessions, 2)
    }

    func testStartAfterCompletionBeginsNextPhase() {
        settings.focusMinutes = 1
        settings.autoStartBreaks = false
        timer = makeTimer()
        timer.start()
        completePhase(60)

        timer.start()

        XCTAssertEqual(timer.phase, .shortBreak)
        XCTAssertEqual(timer.state, .running)
        XCTAssertNil(timer.phaseAlert)
    }

    func testStartNextPhaseAdvancesWithoutCountingFocusSessionForBreaks() {
        timer.startNextPhase()

        XCTAssertEqual(timer.phase, .shortBreak)
        XCTAssertEqual(timer.state, .running)
        XCTAssertEqual(timer.completedFocusSessions, 1)

        timer.startNextPhase()

        XCTAssertEqual(timer.phase, .focus)
        XCTAssertEqual(timer.completedFocusSessions, 1)
    }

    func testSkipPhaseAdvancesAndDoesNotPersistSession() {
        timer.skipPhase()

        XCTAssertEqual(timer.phase, .shortBreak)
        XCTAssertEqual(timer.state, .idle)
        XCTAssertEqual(timer.completedFocusSessions, 1)
        XCTAssertEqual(persistence.loadSessions(), [])
    }

    func testSkipPhaseFromRunningBreakReturnsToFocusIdle() {
        timer.startNextPhase()
        timer.skipPhase()

        XCTAssertEqual(timer.phase, .focus)
        XCTAssertEqual(timer.state, .idle)
        XCTAssertEqual(timer.completedFocusSessions, 1)
    }

    // MARK: - Notification actions

    func testStartBreakNotificationActionAdvancesPhase() {
        NotificationCenter.default.post(name: .focusStartBreakAction, object: nil)

        XCTAssertEqual(timer.phase, .shortBreak)
        XCTAssertEqual(timer.state, .running)
    }

    func testSkipNotificationActionAdvancesPhase() {
        NotificationCenter.default.post(name: .focusSkipAction, object: nil)

        XCTAssertEqual(timer.phase, .shortBreak)
        XCTAssertEqual(timer.state, .idle)
    }

    // MARK: - Display helpers

    func testElapsedFraction() {
        settings.focusMinutes = 25
        timer = makeTimer()
        timer.start()
        timer.tick()
        timer.tick()
        timer.tick()
        timer.tick()
        timer.tick()

        XCTAssertEqual(timer.elapsedFraction, 5.0 / 1_500.0, accuracy: 0.000_001)
    }

    func testElapsedFractionIsZeroWhenIdle() {
        XCTAssertEqual(timer.elapsedFraction, 0)
    }

    func testRemainingLabelFormatsMinuteSecond() {
        timer.start()
        XCTAssertEqual(timer.remainingLabel, "25:00")
        timer.tick()
        XCTAssertEqual(timer.remainingLabel, "24:59")
    }

    func testRemainingLabelForShortDuration() {
        settings.focusMinutes = 1
        timer = makeTimer()
        timer.start()
        XCTAssertEqual(timer.remainingLabel, "01:00")
        timer.tick()
        XCTAssertEqual(timer.remainingLabel, "00:59")
    }

    // MARK: - Idle auto-pause

    func testIdleAutoPauseAndResume() {
        settings.pauseWhenIdle = true
        var idle: TimeInterval = 0
        timer = makeTimer(idleTime: { idle })

        timer.start()
        XCTAssertEqual(timer.state, .running)

        idle = 120
        timer.tick()
        XCTAssertEqual(timer.state, .paused)

        idle = 5
        timer.tick()
        XCTAssertEqual(timer.state, .running)

        idle = 120
        timer.tick()
        XCTAssertEqual(timer.state, .paused)
    }

    func testManualPauseIsNotAutoResumed() {
        settings.pauseWhenIdle = true
        var idle: TimeInterval = 0
        timer = makeTimer(idleTime: { idle })

        timer.start()
        timer.togglePause()
        XCTAssertEqual(timer.state, .paused)

        idle = 5
        timer.tick()
        XCTAssertEqual(timer.state, .paused)
    }

    func testIdleAutoPauseDoesNotApplyDuringBreak() {
        settings.pauseWhenIdle = true
        settings.autoStartBreaks = true
        var idle: TimeInterval = 120
        timer = makeTimer(idleTime: { idle })

        timer.startNextPhase()
        XCTAssertEqual(timer.phase, .shortBreak)
        XCTAssertEqual(timer.state, .running)

        timer.tick()
        XCTAssertEqual(timer.state, .running)
    }
}
