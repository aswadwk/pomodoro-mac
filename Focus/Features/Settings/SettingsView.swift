import SwiftUI

struct SettingsView: View {
    @Environment(SettingsStore.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        Form {
            Section("Timing") {
                Stepper("Focus: \(settings.focusMinutes) min", value: $settings.focusMinutes, in: 1...180)
                Stepper("Short break: \(settings.shortBreakMinutes) min", value: $settings.shortBreakMinutes, in: 1...60)
                Stepper("Long break: \(settings.longBreakMinutes) min", value: $settings.longBreakMinutes, in: 1...90)
                Stepper("Long break every \(settings.sessionsBeforeLongBreak) sessions", value: $settings.sessionsBeforeLongBreak, in: 1...12)
            }

            Section("Behavior") {
                Toggle("Auto-start breaks", isOn: $settings.autoStartBreaks)
                Toggle("Auto-start focus", isOn: $settings.autoStartFocus)
                Toggle("Pause when idle for 60s", isOn: $settings.pauseWhenIdle)
                Toggle("Launch at login", isOn: $settings.launchAtLogin)
            }

            Section("Feedback") {
                Toggle("Play sound", isOn: $settings.playSound)
                Toggle("Send notifications", isOn: $settings.sendNotifications)
            }
        }
        .formStyle(.grouped)
        .frame(width: 360)
    }
}
