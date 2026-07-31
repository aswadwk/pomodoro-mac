import SwiftUI

@main
struct FocusApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var settings: SettingsStore
    @State private var timer: TimerService
    @State private var statistics: StatisticsService

    init() {
        let persistence = PersistenceService()
        let settings = SettingsStore(persistence: persistence)
        let timer = TimerService(settings: settings, persistence: persistence)
        let statistics = StatisticsService(persistence: persistence)
        _settings = State(initialValue: settings)
        _timer = State(initialValue: timer)
        _statistics = State(initialValue: statistics)
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(timer: timer, settings: settings)
        } label: {
            MenuBarLabel(timer: timer)
        }
        .menuBarExtraStyle(.window)
        .environment(timer)
        .environment(settings)

        Window("Statistics", id: "statistics") {
            StatisticsView()
                .environment(timer)
                .environment(statistics)
        }
        .windowResizability(.contentSize)

        Window("Settings", id: "settings") {
            SettingsView()
                .environment(settings)
        }
        .windowResizability(.contentSize)
    }
}
