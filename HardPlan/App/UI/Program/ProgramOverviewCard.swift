import SwiftUI
import Charts

struct ProgramOverviewCard: View {
    let overview: ProgramOverview

    private var baselineProjection: ProgramWeekProjection? {
        overview.weeks.first(where: { $0.projectedMetric != nil })
    }

    private func normalizedProjectedValue(for week: ProgramWeekProjection) -> Double? {
        guard let projected = week.projectedMetric else {
            return nil
        }
        if let target = overview.targetValue, target != 0 {
            return projected / target
        }

        guard let baseline = baselineProjection?.projectedMetric, baseline != 0 else {
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

            if let target = overview.targetValue, target > 0 {
                Text("Projected e1RM shown as % of \(Int(target)) lb target")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else if let baseline = baselineProjection, let value = baseline.projectedMetric {
                Text("Projected e1RM shown relative to W\(baseline.weekIndex) baseline (\(Int(value)) lb)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
