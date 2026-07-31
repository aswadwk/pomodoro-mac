import Charts
import SwiftUI

struct StatisticsView: View {
    @Environment(StatisticsService.self) private var statistics

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Today")
                .font(.headline)

            HStack(spacing: 24) {
                statCard(
                    title: "Sessions",
                    value: "\(statistics.focusSessionsToday.count)",
                    icon: "timer"
                )
                statCard(
                    title: "Focus",
                    value: statistics.formattedTime(statistics.focusTimeToday),
                    icon: "flame"
                )
                statCard(
                    title: "Break",
                    value: statistics.formattedTime(statistics.breakTimeToday),
                    icon: "cup.and.saucer"
                )
                statCard(
                    title: "Productivity",
                    value: "\(Int(statistics.productivityToday * 100))%",
                    icon: "percent"
                )
            }

            Text("Last 7 days")
                .font(.headline)

            Chart(statistics.lastSevenDays) { day in
                BarMark(
                    x: .value("Day", day.date, unit: .day),
                    y: .value("Focus minutes", day.focusMinutes)
                )
                .foregroundStyle(Color.accentColor)
                .cornerRadius(3)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                }
            }
            .frame(height: 180)
        }
        .padding(20)
        .frame(width: 420)
        .onAppear(perform: statistics.refresh)
        .onReceive(NotificationCenter.default.publisher(for: .focusSessionCompleted)) { _ in
            statistics.refresh()
        }
    }

    private func statCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.semibold))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
