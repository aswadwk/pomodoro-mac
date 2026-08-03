import XCTest
@testable import Focus

@MainActor
final class SettingsStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private var persistence: PersistenceService!

    override func setUp() async throws {
        defaults = TestSupport.makeIsolatedDefaults()
        persistence = PersistenceService(defaults: defaults)
    }

    override func tearDown() async throws {
        persistence = nil
        defaults = nil
    }

    private func makeStore() -> SettingsStore {
        SettingsStore(persistence: persistence)
    }

    func testDefaultsWhenNothingIsStored() {
        let store = makeStore()

        XCTAssertEqual(store.focusMinutes, 25)
        XCTAssertEqual(store.shortBreakMinutes, 5)
        XCTAssertEqual(store.longBreakMinutes, 15)
        XCTAssertEqual(store.sessionsBeforeLongBreak, 4)
        XCTAssertFalse(store.autoStartBreaks)
        XCTAssertFalse(store.autoStartFocus)
        XCTAssertTrue(store.playSound)
        XCTAssertEqual(store.soundName, SettingsStore.defaultSoundName)
        XCTAssertTrue(store.sendNotifications)
        XCTAssertTrue(store.pauseWhenIdle)
    }

    func testChangedValuesPersistAcrossInstances() {
        let store = makeStore()
        store.focusMinutes = 50
        store.shortBreakMinutes = 10
        store.longBreakMinutes = 20
        store.sessionsBeforeLongBreak = 3
        store.autoStartBreaks = true
        store.autoStartFocus = true
        store.playSound = false
        store.soundName = "Submarine"
        store.sendNotifications = false
        store.pauseWhenIdle = true

        let reloaded = makeStore()

        XCTAssertEqual(reloaded.focusMinutes, 50)
        XCTAssertEqual(reloaded.shortBreakMinutes, 10)
        XCTAssertEqual(reloaded.longBreakMinutes, 20)
        XCTAssertEqual(reloaded.sessionsBeforeLongBreak, 3)
        XCTAssertTrue(reloaded.autoStartBreaks)
        XCTAssertTrue(reloaded.autoStartFocus)
        XCTAssertFalse(reloaded.playSound)
        XCTAssertEqual(reloaded.soundName, "Submarine")
        XCTAssertFalse(reloaded.sendNotifications)
        XCTAssertTrue(reloaded.pauseWhenIdle)
    }

    func testDurationsAreMinutesConvertedToSeconds() {
        let store = makeStore()
        store.focusMinutes = 30
        store.shortBreakMinutes = 7
        store.longBreakMinutes = 15

        XCTAssertEqual(store.focusDuration, 1_800)
        XCTAssertEqual(store.shortBreakDuration, 420)
        XCTAssertEqual(store.longBreakDuration, 900)
    }

    func testZeroDurationsProduceZeroSeconds() {
        let store = makeStore()
        store.focusMinutes = 0

        XCTAssertEqual(store.focusDuration, 0)
    }

    func testResetToDefaultsRestoresAllValues() {
        let store = makeStore()
        store.focusMinutes = 90
        store.shortBreakMinutes = 30
        store.longBreakMinutes = 45
        store.sessionsBeforeLongBreak = 8
        store.autoStartBreaks = true
        store.autoStartFocus = true
        store.playSound = false
        store.soundName = "Boop"
        store.sendNotifications = false
        store.pauseWhenIdle = true

        store.resetToDefaults()

        XCTAssertEqual(store.focusMinutes, 25)
        XCTAssertEqual(store.shortBreakMinutes, 5)
        XCTAssertEqual(store.longBreakMinutes, 15)
        XCTAssertEqual(store.sessionsBeforeLongBreak, 4)
        XCTAssertFalse(store.autoStartBreaks)
        XCTAssertFalse(store.autoStartFocus)
        XCTAssertTrue(store.playSound)
        XCTAssertEqual(store.soundName, SettingsStore.defaultSoundName)
        XCTAssertTrue(store.sendNotifications)
        XCTAssertTrue(store.pauseWhenIdle)
    }

    func testResetToDefaultsIsPersisted() {
        let store = makeStore()
        store.focusMinutes = 90
        store.resetToDefaults()

        XCTAssertEqual(makeStore().focusMinutes, 25)
    }
}
