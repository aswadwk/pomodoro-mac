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

            Text("This Week")
                .font(.headline)

            HStack(spacing: 24) {
                statCard(
                    title: "Focus",
                    value: statistics.formattedTime(statistics.focusTimeThisWeek),
                    icon: "flame"
                )
                statCard(
                    title: "Avg / day",
                    value: statistics.formattedTime(statistics.averageFocusPerDayThisWeek),
                    icon: "calendar"
                )
                statCard(
                    title: "Streak",
                    value: "\(statistics.currentStreak) day\(statistics.currentStreak == 1 ? "" : "s")",
                    icon: "flame.fill"
                )
                statCard(
                    title: "Sessions",
                    value: "\(statistics.focusSessionsThisWeek.count)",
                    icon: "timer"
                )
            }

            Chart(statistics.thisWeek) { day in
                BarMark(
                    x: .value("Day", day.date, unit: .day),
                    y: .value("Minutes", day.focusMinutes)
                )
                .foregroundStyle(Color.accentColor)
                .cornerRadius(3)

                BarMark(
                    x: .value("Day", day.date, unit: .day),
                    y: .value("Minutes", day.breakMinutes)
                )
                .foregroundStyle(Color.secondary.opacity(0.45))
                .cornerRadius(3)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                }
            }
            .chartLegend(position: .bottom) {
                HStack(spacing: 12) {
                    legendDot("Focus", color: Color.accentColor)
                    legendDot("Break", color: Color.secondary.opacity(0.45))
                }
            }
            .frame(height: 180)

            Text("All time: \(statistics.formattedTime(statistics.totalFocusTime)) focused across \(statistics.totalFocusSessions) sessions")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(width: 460)
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

    private func legendDot(_ label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption)
        }
    }
}
