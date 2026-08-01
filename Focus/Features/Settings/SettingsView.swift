import SwiftUI

struct SettingsView: View {
    @Environment(SettingsStore.self) private var settings
    @State private var showResetConfirmation = false

    var body: some View {
        @Bindable var settings = settings
        VStack(spacing: 0) {
            header

            Form {
                Section("Timing") {
                    SettingValueRow(
                        title: "Focus",
                        caption: "1–180 minutes",
                        icon: "timer",
                        tint: .orange,
                        value: $settings.focusMinutes,
                        range: 1...180,
                        valueLabel: Self.durationLabel
                    )
                    SettingValueRow(
                        title: "Short break",
                        caption: "1–60 minutes",
                        icon: "cup.and.saucer.fill",
                        tint: .green,
                        value: $settings.shortBreakMinutes,
                        range: 1...60,
                        valueLabel: Self.durationLabel
                    )
                    SettingValueRow(
                        title: "Long break",
                        caption: "1–90 minutes",
                        icon: "moon.zzz.fill",
                        tint: .indigo,
                        value: $settings.longBreakMinutes,
                        range: 1...90,
                        valueLabel: Self.durationLabel
                    )
                    SettingValueRow(
                        title: "Long break every",
                        caption: "1–12 sessions",
                        icon: "repeat",
                        tint: .blue,
                        value: $settings.sessionsBeforeLongBreak,
                        range: 1...12,
                        valueLabel: { "\($0) sessions" }
                    )
                }

                Section("Behavior") {
                    SettingToggleRow(
                        title: "Auto-start breaks",
                        caption: "Start the break automatically when focus ends",
                        icon: "forward.fill",
                        tint: .teal,
                        isOn: $settings.autoStartBreaks
                    )
                    SettingToggleRow(
                        title: "Auto-start focus",
                        caption: "Start focus automatically when a break ends",
                        icon: "arrow.clockwise",
                        tint: .teal,
                        isOn: $settings.autoStartFocus
                    )
                    SettingToggleRow(
                        title: "Pause when idle",
                        caption: "Auto-pause after 60s away from the Mac",
                        icon: "sleep",
                        tint: .teal,
                        isOn: $settings.pauseWhenIdle
                    )
                    SettingToggleRow(
                        title: "Launch at login",
                        caption: "Run Focus when you sign in",
                        icon: "power",
                        tint: .teal,
                        isOn: $settings.launchAtLogin
                    )
                }

                Section("Feedback") {
                    SettingToggleRow(
                        title: "Play sound",
                        caption: "Chime when a session ends",
                        icon: "speaker.wave.2.fill",
                        tint: .pink,
                        isOn: $settings.playSound
                    )
                    SettingSoundRow(
                        title: "Sound",
                        caption: "Sound used for the chime",
                        icon: "music.note",
                        tint: .pink,
                        selection: $settings.soundName,
                        sounds: SoundService.availableSounds
                    )
                    SettingToggleRow(
                        title: "Send notifications",
                        caption: "Alerts from the notification center",
                        icon: "bell.fill",
                        tint: .pink,
                        isOn: $settings.sendNotifications
                    )
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                Spacer()
                Button("Reset to defaults", role: .destructive) {
                    showResetConfirmation = true
                }
                .controlSize(.small)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .frame(width: 400)
        .alert("Reset all settings?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) { settings.resetToDefaults() }
        } message: {
            Text("All timing, behavior, and feedback settings will be restored to their defaults.")
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .shadow(radius: 2, y: 1)
            VStack(alignment: .leading, spacing: 1) {
                Text("Focus Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Version \(Self.appVersion)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 8)
    }

    private static func durationLabel(_ minutes: Int) -> String {
        minutes >= 60
            ? String(format: "%d:%02d:00", minutes / 60, minutes % 60)
            : String(format: "%d:00", minutes)
    }

    private static var appVersion: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "unknown"
    }
}

struct SettingValueRow: View {
    let title: String
    let caption: String
    let icon: String
    let tint: Color
    @Binding var value: Int
    let range: ClosedRange<Int>
    let valueLabel: (Int) -> String

    @State private var isEditing = false
    @State private var draft = ""
    @State private var isHovering = false
    @FocusState private var fieldFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            IconBadge(systemName: icon, tint: tint)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                draft = String(value)
                isEditing = true
            } label: {
                Text(valueLabel(value))
                    .monospacedDigit()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(isHovering ? Color.primary.opacity(0.12) : Color.primary.opacity(0.06))
                    )
            }
            .buttonStyle(.plain)
            .onHover { isHovering = $0 }
            .popover(isPresented: $isEditing, arrowEdge: .bottom) {
                TextField("Value", text: $draft)
                    .focused($fieldFocused)
                    .frame(width: 80)
                    .padding(10)
                    .onSubmit(commit)
                    .onExitCommand { isEditing = false }
                    .onAppear { fieldFocused = true }
            }

            Stepper("", value: $value, in: range)
                .labelsHidden()
        }
        .padding(.vertical, 2)
    }

    private func commit() {
        if let parsed = Int(draft.trimmingCharacters(in: .whitespaces)), range.contains(parsed) {
            value = parsed
        }
        isEditing = false
    }
}

struct SettingSoundRow: View {
    let title: String
    let caption: String
    let icon: String
    let tint: Color
    @Binding var selection: String
    let sounds: [String]

    var body: some View {
        HStack(spacing: 10) {
            IconBadge(systemName: icon, tint: tint)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                SoundService.play(selection)
            } label: {
                Image(systemName: "play.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .frame(width: 24, height: 22)
            }
            .buttonStyle(.borderless)
            .disabled(sounds.isEmpty)
            .help("Preview sound")

            Picker("", selection: $selection) {
                ForEach(sounds, id: \.self) { name in
                    Text(name).tag(name)
                }
            }
            .labelsHidden()
            .frame(width: 120)
        }
        .padding(.vertical, 2)
    }
}

struct SettingToggleRow: View {
    let title: String
    let caption: String
    let icon: String
    let tint: Color
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 10) {
            IconBadge(systemName: icon, tint: tint)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding(.vertical, 2)
    }
}

struct IconBadge: View {
    let systemName: String
    let tint: Color

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: 28, height: 28)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(tint.opacity(0.15))
            )
    }
}
