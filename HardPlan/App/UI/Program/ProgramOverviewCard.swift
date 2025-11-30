import SwiftUI
import Charts

struct ProgramOverviewCard: View {
    let overview: ProgramOverview

    private var baselineProjection: (weekIndex: Int, value: Double)? {
        guard let week = overview.weeks.first(where: { $0.projectedMetric != nil }), let value = week.projectedMetric else {
            return nil
        }
        return (weekIndex: week.weekIndex, value: value)
    }

    private func normalizedProjectedValue(for week: ProgramWeekProjection) -> Double? {
        guard let projected = week.projectedMetric, let baseline = baselineProjection?.value, baseline != 0 else {
            return nil
        }
        return projected / baseline
    }

    private func intensity(for phase: BlockPhase) -> Double {
        switch phase {
        case .introductory: return 0.5
        case .accumulation: return 0.7
        case .intensification: return 0.85
        case .realization: return 1.0
        case .deload: return 0.4
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Periodization preview")
                .font(.headline)
            if let metricLabel = overview.metricLabel {
                Text(metricLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Chart {
                ForEach(overview.weeks) { week in
                    BarMark(
                        x: .value("Week", "W\(week.weekIndex)"),
                        y: .value("Phase", intensity(for: week.phase))
                    )
                    .foregroundStyle(by: .value("Phase", week.phase.rawValue))

                    if let normalized = normalizedProjectedValue(for: week) {
                        LineMark(
                            x: .value("Week", "W\(week.weekIndex)"),
                            y: .value("Projected", normalized)
                        )
                        .interpolationMethod(.monotone)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        .foregroundStyle(.green)
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: Decimal.FormatStyle.number)
                }
            }
            .chartXAxis {
                AxisMarks(values: overview.weeks.map { "W\($0.weekIndex)" }) { _ in
                    AxisValueLabel()
                }
            }
            .frame(minHeight: 220)

            if let firstDate = overview.weeks.first?.startDate {
                Text("Starting \(dateFormatter.string(from: firstDate)) • Tracks upcoming 8 weeks")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let baseline = baselineProjection {
                Text("Projected e1RM shown relative to W\(baseline.weekIndex) baseline")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
