import SwiftUI

struct MenuBarView: View {
    let timer: TimerService
    let settings: SettingsStore
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 0) {
            if timer.isBreakPhase {
                BreakView(timer: timer)
            } else {
                TimerStatusView(timer: timer)
            }

            Divider()
                .padding(.vertical, 8)

            HStack(spacing: 8) {
                Button {
                    if timer.state == .idle {
                        timer.start()
                    } else {
                        timer.togglePause()
                    }
                } label: {
                    Label(primaryButtonTitle, systemImage: primaryButtonIcon)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.space)

                Button {
                    timer.skip()
                } label: {
                    Label("Skip", systemImage: "forward.fill")
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }

            if settings.pauseWhenIdle, !timer.isBreakPhase {
                Text("Auto-pauses when you leave the Mac")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
            }

            Divider()
                .padding(.vertical, 8)

            MenuItemRow(title: "Statistics", icon: "chart.bar") {
                openWindow(id: "statistics")
            }

            MenuItemRow(title: "Settings", icon: "gearshape") {
                openWindow(id: "settings")
            }

            Divider()
                .padding(.vertical, 8)

            MenuItemRow(title: "Quit Focus", icon: "power") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(12)
        .frame(width: 280)
    }

    private var primaryButtonTitle: String {
        switch timer.state {
        case .idle: "Start"
        case .running: "Pause"
        case .paused: "Resume"
        }
    }

    private var primaryButtonIcon: String {
        timer.isRunning ? "pause.fill" : "play.fill"
    }
}

struct MenuBarLabel: View {
    let timer: TimerService

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "timer")
            Text(timer.remainingLabel)
                .monospacedDigit()
        }
    }
}

struct MenuItemRow: View {
    let title: String
    let icon: String
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .frame(width: 18)
                    .foregroundStyle(isHovering ? Color.accentColor : Color.secondary)
                Text(title)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(isHovering ? Color.primary.opacity(0.08) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}
