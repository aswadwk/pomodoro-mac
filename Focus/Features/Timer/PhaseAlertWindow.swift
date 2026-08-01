import AppKit
import SwiftUI

@MainActor
final class PhaseAlertWindow {
    private let timer: TimerService
    private var panel: NSPanel?

    init(timer: TimerService) {
        self.timer = timer
        timer.phaseAlertChanged = { [weak self] in
            self?.sync()
        }
    }

    private func sync() {
        guard let alert = timer.phaseAlert else {
            close()
            return
        }
        show(alert: alert)
    }

    private func show(alert: TimerService.PhaseAlert) {
        let hosting = NSHostingView(rootView: PhaseAlertOverlay(alert: alert, timer: timer))
        let panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = true
        panel.contentView = hosting
        panel.setContentSize(hosting.fittingSize)
        position(panel)
        self.panel = panel

        panel.alphaValue = 0
        panel.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            panel.animator().alphaValue = 1
        }
    }

    private func position(_ panel: NSPanel) {
        guard let screen = NSScreen.screens.first(where: {
            NSMouseInRect(NSEvent.mouseLocation, $0.frame, false)
        }) ?? NSScreen.main else { return }
        let frame = screen.visibleFrame
        panel.setFrameOrigin(NSPoint(
            x: frame.midX - panel.frame.width / 2,
            y: frame.midY - panel.frame.height / 2
        ))
    }

    private func close() {
        guard let panel else { return }
        panel.orderOut(nil)
        self.panel = nil
    }
}

struct PhaseAlertOverlay: View {
    let alert: TimerService.PhaseAlert
    let timer: TimerService

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(copy.accent.opacity(0.14))
                    .frame(width: 68, height: 68)
                Image(systemName: copy.icon)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(copy.accent)
            }

            VStack(spacing: 5) {
                Text(copy.title)
                    .font(.system(size: 20, weight: .bold))
                Text(copy.subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()
                .padding(.horizontal, 4)

            VStack(spacing: 8) {
                Button {
                    timer.startNextPhase()
                } label: {
                    Label(copy.startLabel, systemImage: copy.startIcon)
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(copy.accent)
                .controlSize(.large)

                Button {
                    timer.skipPhase()
                } label: {
                    Label(NotificationAction.skip.title, systemImage: "forward.fill")
                        .font(.system(size: 14))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
        .padding(24)
        .frame(width: 340)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.white.opacity(0.12))
        }
    }

    private var copy: (icon: String, accent: Color, title: String, subtitle: String, startLabel: String, startIcon: String) {
        switch alert {
        case .focusFinished:
            (
                "checkmark.circle.fill",
                Color(red: 0.92, green: 0.30, blue: 0.25),
                "Focus Complete",
                "Great work — time to recharge.",
                NotificationAction.startBreak.title,
                "cup.and.saucer.fill"
            )
        case .breakFinished:
            (
                "bell.fill",
                Color(red: 0.16, green: 0.64, blue: 0.45),
                "Break Over",
                "Ready for the next focus session?",
                "Start Focus",
                "brain.head.profile.fill"
            )
        }
    }
}
