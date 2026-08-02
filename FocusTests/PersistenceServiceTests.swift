import Foundation
import XCTest
@testable import Focus

final class PersistenceServiceTests: XCTestCase {
    private var defaults: UserDefaults!
    private var persistence: PersistenceService!

    override func setUp() {
        super.setUp()
        defaults = TestSupport.makeIsolatedDefaults()
        persistence = PersistenceService(defaults: defaults)
    }

    override func tearDown() {
        persistence = nil
        defaults = nil
        super.tearDown()
    }

    func testLoadReturnsDefaultWhenKeyIsMissing() {
        XCTAssertEqual(persistence.load(.focusMinutes, default: 25), 25)
        XCTAssertEqual(persistence.loadSessions(), [])
    }

    func testSaveAndLoadRoundTrip() {
        let sessions = [
            PomodoroSession(kind: .focus, date: Date(timeIntervalSince1970: 1_000), duration: 1500),
            PomodoroSession(kind: .shortBreak, date: Date(timeIntervalSince1970: 2_000), duration: 300),
        ]

        persistence.saveSessions(sessions)

        XCTAssertEqual(persistence.loadSessions(), sessions)
    }

    func testSaveAndLoadScalarValues() {
        persistence.save(30, for: .focusMinutes)
        persistence.save(false, for: .playSound)
        persistence.save("Ping", for: .soundName)

        XCTAssertEqual(persistence.load(.focusMinutes, default: 25), 30)
        XCTAssertEqual(persistence.load(.playSound, default: true), false)
        XCTAssertEqual(persistence.load(.soundName, default: "Ringtone"), "Ping")
    }

    func testCorruptDataFallsBackToDefault() {
        defaults.set(Data("not-json".utf8), forKey: PersistenceKey.focusMinutes.rawValue)
        defaults.set(Data("not-json".utf8), forKey: PersistenceKey.sessions.rawValue)

        XCTAssertEqual(persistence.load(.focusMinutes, default: 25), 25)
        XCTAssertEqual(persistence.loadSessions(), [])
    }

    func testSuitesAreIsolated() {
        let otherSuite = "FocusTests.isolation-\(UUID().uuidString)"
        let other = UserDefaults(suiteName: otherSuite)!
        let otherPersistence = PersistenceService(defaults: other)
        other.removePersistentDomain(forName: otherSuite)
        defer { other.removePersistentDomain(forName: otherSuite) }

        otherPersistence.saveSessions([PomodoroSession(kind: .focus, date: Date(), duration: 60)])

        XCTAssertEqual(persistence.loadSessions(), [])
        XCTAssertEqual(otherPersistence.loadSessions().count, 1)
    }
}
