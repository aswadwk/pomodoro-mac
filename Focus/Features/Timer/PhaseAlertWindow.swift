import AppKit
import Observation
import SwiftUI

@MainActor
final class PhaseAlertWindow {
    private let timer: TimerService
    private var panel: NSPanel?

    init(timer: TimerService) {
        self.timer = timer
        observe()
    }

    private func observe() {
        withObservationTracking {
            _ = timer.phaseAlert
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                sync()
                observe()
            }
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
            y: frame.maxY - panel.frame.height - 24
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
        VStack(spacing: 16) {
            Image(systemName: copy.icon)
                .font(.system(size: 36))
                .foregroundStyle(.yellow)

            Text(copy.title)
                .font(.headline)

            Text(copy.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 8) {
                Button {
                    timer.startNextPhase()
                } label: {
                    Label(copy.startLabel, systemImage: copy.startIcon)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button {
                    timer.skipPhase()
                } label: {
                    Label(NotificationAction.skip.title, systemImage: "forward.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
            }
        }
        .padding(24)
        .frame(width: 320)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.white.opacity(0.12))
        }
    }

    private var copy: (icon: String, title: String, subtitle: String, startLabel: String, startIcon: String) {
        switch alert {
        case .focusFinished:
            ("checkmark.circle.fill", "Focus Complete!", "Great work. Time to recharge.", NotificationAction.startBreak.title, "cup.and.saucer.fill")
        case .breakFinished:
            ("bell.fill", "Break Over!", "Ready to get back to it?", "Start Focus", "brain.head.profile.fill")
        }
    }
}
