import SwiftUI
import Charts
import Combine

struct RPEHeatmap: View {
    let bins: [RPERangeBin]

    private var displays: [RPEBinDisplay] {
        bins.map { bin in
            let weeks = max(bin.periodWeeks, 1)
            let average = Double(bin.count) / Double(weeks)
            return RPEBinDisplay(label: bin.rangeLabel, total: bin.count, averagePerWeek: average)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if displays.isEmpty {
                placeholder
            } else {
                Chart(displays) { item in
                    BarMark(
                        x: .value("Sets", item.averagePerWeek),
                        y: .value("RPE", item.label)
                    )
                    .foregroundStyle(color(for: item.label))
                    .cornerRadius(6)
                    .annotation(position: .trailing, alignment: .leading) {
                        Text("\(item.total) sets")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .chartXAxisLabel("Avg sets per week")
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .frame(minHeight: 220)

                HStack(spacing: 12) {
                    legendDot(color: color(for: "6-7"))
                    Text("Under RPE 7")
                        .foregroundStyle(.secondary)
                    legendDot(color: color(for: "7-8"))
                    Text("RPE 7-8")
                        .foregroundStyle(.secondary)
                    legendDot(color: color(for: "8-9"))
                    Text("RPE 8-9")
                        .foregroundStyle(.secondary)
                    legendDot(color: color(for: "9-10"))
                    Text("Overshooting")
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
                .lineLimit(1)
            }
        }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.secondarySystemBackground))
            .frame(maxWidth: .infinity, minHeight: 200)
            .overlay(
                VStack(spacing: 6) {
                    Text("No RPE data yet")
                        .font(.headline)
                    Text("Log RPEs on your sets to see distribution across weeks.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            )
    }

    private func color(for label: String) -> Color {
        switch label {
        case "6-7":
            return Color.green.opacity(0.8)
        case "7-8":
            return Color.teal
        case "8-9":
            return Color.orange
        default:
            return Color.red
        }
    }

    private func legendDot(color: Color) -> some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
    }
}

private struct RPEBinDisplay: Identifiable {
    let id = UUID()
    let label: String
    let total: Int
    let averagePerWeek: Double
}
