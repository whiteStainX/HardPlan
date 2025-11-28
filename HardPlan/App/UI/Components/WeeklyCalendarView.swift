import SwiftUI
import UniformTypeIdentifiers

struct WeeklyCalendarView: View {
    let sessions: [ProgramSessionDisplay]
    var workoutLogs: [WorkoutLog] = []
    var startWeekday: Int = 1
    var calendar: Calendar = .current
    var onSessionTap: (ProgramSessionDisplay) -> Void = { _ in }
    var droppable: Bool = false
    var onDropItem: (String, Int) -> Void = { _, _ in }
    var onClearDay: (Int) -> Void = { _ in }

    private enum DayStatus {
        case completed
        case skipped
        case missed
    }

    private var normalizedStartWeekday: Int {
        (1...7).contains(startWeekday) ? startWeekday : 1
    }

    private var orderedWeekdays: [Int] {
        (0..<7).map { ((normalizedStartWeekday + $0 - 1) % 7) + 1 }
    }

    private var sessionsByDay: [Int: [ProgramSessionDisplay]] {
        Dictionary(grouping: sessions, by: { $0.dayOfWeek })
    }

    private var workingCalendar: Calendar {
        var adjusted = calendar
        adjusted.firstWeekday = normalizedStartWeekday
        return adjusted
    }

    private var statusByWeekday: [Int: DayStatus] {
        guard let weekStart = workingCalendar.date(from: workingCalendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) else {
            return [:]
        }

        let normalizedWeekStart = workingCalendar.startOfDay(for: weekStart)
        let weekEnd = workingCalendar.date(byAdding: .day, value: 7, to: normalizedWeekStart) ?? normalizedWeekStart

        var status: [Int: DayStatus] = [:]

        for log in workoutLogs {
            guard let date = parseDate(log.dateCompleted) else { continue }
            let day = workingCalendar.startOfDay(for: date)

            guard day >= normalizedWeekStart, day < weekEnd else { continue }

            let weekday = workingCalendar.component(.weekday, from: day)
            switch log.status {
            case .completed, .combined:
                status[weekday] = .completed
            case .skipped:
                status[weekday] = .skipped
            }
        }

        let today = workingCalendar.startOfDay(for: Date())
        for offset in 0..<7 {
            guard let day = workingCalendar.date(byAdding: .day, value: offset, to: normalizedWeekStart) else { continue }
            let weekday = workingCalendar.component(.weekday, from: day)
            if day < today, status[weekday] == nil {
                status[weekday] = .missed
            }
        }

        return status
    }

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

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 7), spacing: 12) {
            ForEach(orderedWeekdays, id: \.self) { weekday in
                dayCell(for: weekday)
            }
        }
    }

    private func dayCell(for weekday: Int) -> some View {
        let status = statusByWeekday[weekday]

        return VStack(alignment: .leading, spacing: 8) {
            Text(weekdayLabel(for: weekday))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let daySessions = sessionsByDay[weekday], !daySessions.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(daySessions) { session in
                        HStack(alignment: .center, spacing: 8) {
                            Button {
                                onSessionTap(session)
                            } label: {
                                HStack {
                                    Text(session.sessionName)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)

                            if droppable {
                                Button {
                                    onClearDay(weekday)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(Color(.tertiaryLabel))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            } else {
                Text("Rest")
                    .font(.headline)
                    .foregroundStyle(Color(.tertiaryLabel))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
        .background(backgroundColor(for: status))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(alignment: .topTrailing) {
            if let status {
                statusBadge(for: status)
            }
        }
        .onDrop(of: [.text], isTargeted: nil) { providers in
            guard droppable else { return false }
            guard let provider = providers.first else { return false }

            provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { data, _ in
                guard
                    let data = data as? Data,
                    let idString = String(data: data, encoding: .utf8)
                else { return }

                DispatchQueue.main.async {
                    onDropItem(idString, weekday)
                }
            }

            return true
        }
    }

    private func weekdayLabel(for weekday: Int) -> String {
        let symbols = calendar.weekdaySymbols
        if weekday >= 1 && weekday <= symbols.count {
            return symbols[weekday - 1]
        }

        return "Day \(weekday)"
    }

    private func backgroundColor(for status: DayStatus?) -> Color {
        switch status {
        case .completed:
            return Color.green.opacity(0.15)
        case .skipped:
            return Color.yellow.opacity(0.15)
        case .missed:
            return Color.red.opacity(0.12)
        case .none:
            return Color(.secondarySystemBackground)
        }
    }

    private func statusBadge(for status: DayStatus) -> some View {
        let icon: String
        let tint: Color

        switch status {
        case .completed:
            icon = "checkmark.circle.fill"
            tint = .green
        case .skipped:
            icon = "arrow.uturn.backward.circle.fill"
            tint = .yellow
        case .missed:
            icon = "xmark.circle.fill"
            tint = .red
        }

        return Image(systemName: icon)
            .font(.title3)
            .foregroundStyle(tint)
            .padding(8)
    }

    private func parseDate(_ string: String) -> Date? {
        if let date = isoFormatter.date(from: string) {
            return date
        }

        return dateOnlyFormatter.date(from: string)
    }
}
