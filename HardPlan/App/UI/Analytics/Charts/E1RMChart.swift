import SwiftUI
import Charts
import Combine

struct E1RMChart: View {
    let history: [E1RMPoint]
    let projected: [E1RMPoint]
    let blockPhases: [BlockPhaseSegment]

    private let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private let dateOnlyFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter
    }()

    private var chartPoints: [ChartPoint] {
        history.compactMap { point in
            guard let date = parseDate(point.date) else { return nil }
            return ChartPoint(date: date, value: point.e1rm)
        }
        .sorted { $0.date < $1.date }
    }

    private var projectedPoints: [ChartPoint] {
        projected.compactMap { point in
            guard let date = parseDate(point.date) else { return nil }
            return ChartPoint(date: date, value: point.e1rm)
        }
        .sorted { $0.date < $1.date }
    }

    private var phaseMarkers: [PhaseMarker] {
        blockPhases.compactMap { segment in
            guard let date = parseDate(segment.startDate) else { return nil }
            return PhaseMarker(date: date, label: segment.phase)
        }
        .sorted { $0.date < $1.date }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if chartPoints.isEmpty {
                placeholder
            } else {
                Chart {
                    ForEach(chartPoints) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Load", point.value)
                        )
                        .interpolationMethod(.monotone)
                        .foregroundStyle(.blue)

                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Load", point.value)
                        )
                        .foregroundStyle(.blue)
                        .symbolSize(40)
                    }

                    if !projectedPoints.isEmpty {
                        ForEach(projectedPoints) { point in
                            LineMark(
                                x: .value("Projected Date", point.date),
                                y: .value("Projected Load", point.value)
                            )
                            .interpolationMethod(.monotone)
                            .foregroundStyle(.green)
                            .lineStyle(.init(lineWidth: 2, dash: [6, 3]))
                        }
                    }

                    ForEach(phaseMarkers) { marker in
                        RuleMark(
                            x: .value("Block Phase", marker.date)
                        )
                        .foregroundStyle(Color(.systemGray3))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .annotation(position: .top, alignment: .leading) {
                            Text(marker.label)
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color(.secondarySystemBackground))
                                )
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 6)) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartYAxisLabel("Estimated 1RM", position: .leading)
                .frame(minHeight: 260)
            }
        }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.secondarySystemBackground))
            .frame(maxWidth: .infinity, minHeight: 240)
            .overlay(
                VStack(spacing: 6) {
                    Text("Not enough data")
                        .font(.headline)
                    Text("Log workouts with Tier 1 lifts to see e1RM trends.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            )
    }

    private func parseDate(_ string: String) -> Date? {
        if let date = isoFormatter.date(from: string) {
            return date
        }

        return dateOnlyFormatter.date(from: string)
    }
}

private struct ChartPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

private struct PhaseMarker: Identifiable {
    let id = UUID()
    let date: Date
    let label: String
}
