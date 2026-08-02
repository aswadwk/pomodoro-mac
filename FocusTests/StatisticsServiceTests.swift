import Foundation
import XCTest
@testable import Focus

@MainActor
final class StatisticsServiceTests: XCTestCase {
    private var calendar: Calendar!
    private var now: Date!
    private var persistence: PersistenceService!
    private var statistics: StatisticsService!

    override func setUp() async throws {
        calendar = TestSupport.makeUTCCalendar()
        now = TestSupport.date(2026, 8, 2, 12, 0, calendar: calendar)
        persistence = PersistenceService(defaults: TestSupport.makeIsolatedDefaults())
        statistics = makeStatistics()
    }

    override func tearDown() async throws {
        statistics = nil
        persistence = nil
        now = nil
        calendar = nil
    }

    private func makeStatistics() -> StatisticsService {
        StatisticsService(persistence: persistence, calendar: calendar, now: { self.now })
    }

    private func session(_ kind: PomodoroSession.Kind, _ day: Int, _ month: Int, _ hour: Int, duration: TimeInterval) -> PomodoroSession {
        PomodoroSession(kind: kind, date: TestSupport.date(2026, month, day, hour, 0, calendar: calendar), duration: duration)
    }

    private func save(_ sessions: [PomodoroSession]) {
        persistence.saveSessions(sessions)
        statistics.refresh()
    }

    /// Fixed fixture (2026-08-02 is a Sunday, week starts Monday 2026-07-27):
    /// focus sessions on Jul 27 (Mon), Jul 29 (Wed), Jul 31 (Fri), Aug 1 (Sat),
    /// Aug 2 (today) and Aug 3 (next week); a short break today; a long break
    /// on Jul 26 (previous week).
    private var fixture: [PomodoroSession] {
        [
            session(.focus, 27, 7, 8, duration: 1_500),
            session(.focus, 29, 7, 9, duration: 1_500),
            session(.focus, 31, 7, 10, duration: 1_500),
            session(.focus, 1, 8, 11, duration: 1_500),
            session(.focus, 2, 8, 10, duration: 1_500),
            session(.shortBreak, 2, 8, 10, duration: 900),
            session(.longBreak, 26, 7, 23, duration: 900),
            session(.focus, 3, 8, 8, duration: 1_500),
        ]
    }

    // MARK: - Today

    func testTodayAggregations() {
        save(fixture)

        XCTAssertEqual(statistics.focusSessionsToday.count, 1)
        XCTAssertEqual(statistics.breakSessionsToday.count, 1)
        XCTAssertEqual(statistics.focusTimeToday, 1_500)
        XCTAssertEqual(statistics.breakTimeToday, 900)
        XCTAssertEqual(statistics.productivityToday, 1_500.0 / 2_400.0, accuracy: 0.000_001)
    }

    func testProductivityIsZeroWithoutSessions() {
        XCTAssertEqual(statistics.productivityToday, 0)
    }

    // MARK: - This week

    func testWeekAggregations() {
        save(fixture)

        XCTAssertEqual(statistics.focusSessionsThisWeek.count, 5)
        XCTAssertEqual(statistics.focusTimeThisWeek, 7_500)
        XCTAssertEqual(statistics.breakTimeThisWeek, 900)
        XCTAssertEqual(statistics.averageFocusPerDayThisWeek, 7_500.0 / 6.0, accuracy: 0.000_001)
    }

    func testWeekChartHasSevenDaysStartingMonday() {
        save(fixture)

        XCTAssertEqual(statistics.thisWeek.count, 7)
        XCTAssertEqual(statistics.thisWeek[0].date, TestSupport.date(2026, 7, 27, 0, 0, calendar: calendar))
        XCTAssertEqual(statistics.thisWeek[0].focusMinutes, 25)
        XCTAssertEqual(statistics.thisWeek[0].breakMinutes, 0)
        XCTAssertEqual(statistics.thisWeek[6].date, TestSupport.date(2026, 8, 2, 0, 0, calendar: calendar))
        XCTAssertEqual(statistics.thisWeek[6].focusMinutes, 25)
        XCTAssertEqual(statistics.thisWeek[6].breakMinutes, 15)
    }

    // MARK: - All time

    func testAllTimeAggregations() {
        save(fixture)

        XCTAssertEqual(statistics.totalFocusTime, 9_000)
        XCTAssertEqual(statistics.totalFocusSessions, 6)
    }

    // MARK: - Streak

    func testStreakCountsConsecutiveFocusDaysEndingToday() {
        save(fixture)

        XCTAssertEqual(statistics.currentStreak, 3)
    }

    func testStreakCountsFromYesterdayWhenTodayHasNoSession() {
        save([
            session(.focus, 1, 8, 9, duration: 1_500),
            session(.focus, 31, 7, 9, duration: 1_500),
        ])

        XCTAssertEqual(statistics.currentStreak, 2)
    }

    func testStreakIsZeroWithoutFocusOnTodayOrYesterday() {
        save([session(.focus, 29, 7, 9, duration: 1_500)])

        XCTAssertEqual(statistics.currentStreak, 0)
    }

    func testStreakIsZeroWhenSessionsAreEmpty() {
        XCTAssertEqual(statistics.currentStreak, 0)
    }

    // MARK: - Formatting

    func testFormattedTime() {
        XCTAssertEqual(statistics.formattedTime(0), "0m")
        XCTAssertEqual(statistics.formattedTime(2_700), "45m")
        XCTAssertEqual(statistics.formattedTime(3_600), "1h 0m")
        XCTAssertEqual(statistics.formattedTime(5_400), "1h 30m")
    }

    // MARK: - Refresh

    func testRefreshReloadsSessionsFromPersistence() {
        XCTAssertEqual(statistics.totalFocusSessions, 0)

        save([session(.focus, 2, 8, 10, duration: 1_500)])

        XCTAssertEqual(statistics.totalFocusSessions, 1)
        XCTAssertEqual(statistics.totalFocusTime, 1_500)
    }
}
