import SwiftUI

struct TimerStatusView: View {
    let timer: TimerService

    var body: some View {
        VStack(spacing: 8) {
            Text(timer.phase.label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.1), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: timer.elapsedFraction)
                    .stroke(
                        Color.accentColor,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                Text(timer.remainingLabel)
                    .font(.system(size: 40, weight: .semibold, design: .rounded))
                    .monospacedDigit()
            }
            .frame(width: 180, height: 180)
            .padding(.vertical, 8)

            Text(phaseStateLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var phaseStateLabel: String {
        switch timer.state {
        case .idle:
            timer.isBreakPhase ? "Ready to focus" : "Ready when you are"
        case .running:
            "Session running"
        case .paused:
            "Paused"
        }
    }
}
