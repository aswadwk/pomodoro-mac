import Foundation
import XCTest
@testable import Focus

/// Feature tests: end-to-end user flows driven through the real services
/// (TimerService + PersistenceService + StatisticsService) with deterministic
/// injected time and isolated UserDefaults. The 1-second tick task is disabled;
/// ticks are driven manually so flows run in microseconds, not real minutes.
@MainActor
final class FocusFlowTests: XCTestCase {
    private var defaults: UserDefaults!
    private var persistence: PersistenceService!
    private var settings: SettingsStore!
    private var timer: TimerService!
    private var statistics: StatisticsService!
    private var now: Date!
    private var calendar: Calendar!

    override func setUp() async throws {
        calendar = TestSupport.makeUTCCalendar()
        now = TestSupport.date(2026, 8, 2, 12, 0, calendar: calendar)
        defaults = TestSupport.makeIsolatedDefaults()
        persistence = PersistenceService(defaults: defaults)
        settings = SettingsStore(persistence: persistence)
        settings.playSound = false
        settings.sendNotifications = false
        settings.pauseWhenIdle = false
        settings.focusMinutes = 1
        settings.shortBreakMinutes = 1
        timer = makeTimer()
        statistics = StatisticsService(persistence: persistence, calendar: calendar, now: { self.now })
    }

    override func tearDown() async throws {
        timer = nil
        statistics = nil
        settings = nil
        persistence = nil
        defaults = nil
        now = nil
        calendar = nil
    }

    private func makeTimer() -> TimerService {
        TimerService(
            settings: settings,
            persistence: persistence,
            startsTicking: false,
            idleTime: { 0 },
            now: { self.now }
        )
    }

    @discardableResult
    private func tick(_ count: Int) -> TimerService.Phase {
        for _ in 0..<count {
            timer.tick()
        }
        return timer.phase
    }

    // MARK: - User flows

    func testFocusToBreakToFocusFullFlow() {
        settings.autoStartBreaks = true
        settings.autoStartFocus = false

        // User starts the first focus session.
        timer.start()
        XCTAssertEqual(timer.state, .running)

        // A full 1-minute focus session ticks down and completes.
        tick(60)
        XCTAssertEqual(timer.phase, .shortBreak)
        XCTAssertEqual(timer.state, .running)
        XCTAssertEqual(timer.completedFocusSessions, 1)
        XCTAssertEqual(persistence.loadSessions().count, 1)

        // The completed session is visible in statistics (today + all time).
        statistics.refresh()
        XCTAssertEqual(statistics.focusSessionsToday.count, 1)
        XCTAssertEqual(statistics.focusTimeToday, 60)
        XCTAssertEqual(statistics.totalFocusSessions, 1)
        XCTAssertEqual(statistics.totalFocusTime, 60)
        XCTAssertEqual(statistics.productivityToday, 1.0, accuracy: 0.000_001)

        // The break runs down; with autoStartFocus off it ends idle with an
        // alert. The phase stays on the completed break until the user starts
        // the next focus session.
        tick(60)
        XCTAssertEqual(timer.phase, .shortBreak)
        XCTAssertEqual(timer.state, .idle)
        guard case .breakFinished = timer.phaseAlert else {
            return XCTFail("Expected .breakFinished alert, got \(String(describing: timer.phaseAlert))")
        }

        // Both sessions persisted; statistics now show the break.
        XCTAssertEqual(persistence.loadSessions().count, 2)
        statistics.refresh()
        XCTAssertEqual(statistics.breakTimeToday, 60)
        XCTAssertEqual(statistics.productivityToday, 0.5, accuracy: 0.000_001)
        XCTAssertEqual(statistics.formattedTime(statistics.focusTimeToday), "1m")
    }

    func testUserStartsNextPhaseAfterAlert() {
        settings.autoStartBreaks = false
        timer.start()
        tick(60)
        XCTAssertEqual(timer.state, .idle)

        timer.start()

        XCTAssertEqual(timer.phase, .shortBreak)
        XCTAssertEqual(timer.state, .running)
        XCTAssertNil(timer.phaseAlert)
    }

    func testSkipFlowSkipsBreakWithoutRecordingIt() {
        settings.autoStartBreaks = false
        timer.start()
        tick(60)
        XCTAssertEqual(timer.state, .idle)

        timer.skipPhase()

        XCTAssertEqual(timer.phase, .shortBreak)
        XCTAssertEqual(timer.state, .idle)
        XCTAssertEqual(persistence.loadSessions().count, 1)
        XCTAssertEqual(persistence.loadSessions()[0].kind, .focus)
    }

    func testManualPauseKeepsCountdownStable() {
        timer.start()
        timer.togglePause()
        XCTAssertEqual(timer.state, .paused)

        tick(10)
        XCTAssertEqual(timer.secondsRemaining, 60)

        timer.togglePause()
        tick(3)
        XCTAssertEqual(timer.secondsRemaining, 57)
    }

    func testLongBreakCycleEveryTwoSessions() {
        settings.longBreakMinutes = 1
        settings.sessionsBeforeLongBreak = 2
        settings.autoStartBreaks = true
        settings.autoStartFocus = true

        timer.start()
        tick(60)
        XCTAssertEqual(timer.phase, .shortBreak)

        tick(60)
        XCTAssertEqual(timer.phase, .focus)

        tick(60)
        XCTAssertEqual(timer.phase, .longBreak)

        statistics.refresh()
        XCTAssertEqual(statistics.totalFocusSessions, 2)
        XCTAssertEqual(statistics.totalFocusTime, 120)
        XCTAssertEqual(persistence.loadSessions().count, 3)
    }

    func testSessionsSurviveAppRelaunch() {
        settings.autoStartBreaks = false
        timer.start()
        tick(60)
        XCTAssertEqual(persistence.loadSessions().count, 1)

        // Simulate relaunch: brand-new service instances over the same defaults.
        let relaunchedSettings = SettingsStore(persistence: persistence)
        let relaunchedTimer = makeTimer()
        let relaunchedStats = StatisticsService(persistence: persistence, calendar: calendar, now: { self.now })

        XCTAssertEqual(relaunchedTimer.secondsRemaining, relaunchedSettings.focusDuration)
        XCTAssertEqual(relaunchedTimer.phase, .focus)
        XCTAssertEqual(relaunchedTimer.state, .idle)
        XCTAssertEqual(relaunchedStats.totalFocusSessions, 1)
        XCTAssertEqual(relaunchedStats.totalFocusTime, 60)
        XCTAssertEqual(relaunchedStats.focusSessionsToday.count, 1)
    }
}
