import SwiftUI

struct HealthTip: Identifiable {
    let id: String
    let icon: String
    let title: String
    let subtitle: String
}

struct BreakView: View {
    let timer: TimerService

    private static let tips: [HealthTip] = [
        HealthTip(id: "water", icon: "drop.fill", title: "Drink water", subtitle: "Sip a glass of water"),
        HealthTip(id: "eyes", icon: "eye.fill", title: "Look away", subtitle: "Stare at something 6m away for 20 seconds"),
        HealthTip(id: "stand", icon: "figure.stand", title: "Stand up", subtitle: "Get out of your chair"),
        HealthTip(id: "stretch", icon: "figure.stretch", title: "Stretch", subtitle: "Neck and shoulder rolls"),
    ]

    var body: some View {
        VStack(spacing: 10) {
            Text("\(timer.phase.label)")
                .font(.headline)

            Text(timer.remainingLabel)
                .font(.system(size: 40, weight: .semibold, design: .rounded))
                .monospacedDigit()

            ForEach(Self.tips) { tip in
                Label {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(tip.title)
                            .font(.subheadline.weight(.medium))
                        Text(tip.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: tip.icon)
                        .foregroundStyle(Color.accentColor)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(10)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
        }
        .padding(.vertical, 4)
    }
}
