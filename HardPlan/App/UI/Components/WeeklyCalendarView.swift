import SwiftUI

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
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 7), spacing: 10) {
            ForEach(orderedWeekdays, id: \.self) { weekday in
                dayCell(for: weekday)
            }
        }
    }

    private func dayCell(for weekday: Int) -> some View {
        let status = statusByWeekday[weekday]
        let daySessions = sessionsByDay[weekday] ?? []

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(shortWeekdayLabel(for: weekday))
                    .font(.subheadline.weight(.semibold))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(Capsule().fill(Color(.systemBackground)))
                    .overlay(Capsule().stroke(Color(.tertiaryLabel), lineWidth: 1))

                Spacer()

                if let status {
                    statusBadge(for: status)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                if daySessions.isEmpty {
                    Text("Rest")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color(.tertiaryLabel))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(RoundedRectangle(cornerRadius: 10).stroke(Color(.tertiaryLabel).opacity(0.4)))
                } else {
                    ForEach(daySessions) { session in
                        HStack(spacing: 8) {
                            Text(session.sessionName)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                                .lineLimit(1)

                            Spacer()

                            if droppable {
                                Button {
                                    onClearDay(weekday)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(Color(.tertiaryLabel))
                                        .font(.callout)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.tertiaryLabel).opacity(0.35)))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onSessionTap(session)
                        }
                        .draggable(session.id.uuidString)
                    }
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .dropDestination(for: String.self) { items, _ in
            guard droppable, let idString = items.first else { return false }
            onDropItem(idString, weekday)
            return true
        }
    }

    private func shortWeekdayLabel(for weekday: Int) -> String {
        let symbols = calendar.shortWeekdaySymbols
        if weekday >= 1 && weekday <= symbols.count {
            return String(symbols[weekday - 1].prefix(2)).uppercased()
        }

        return "D\(weekday)"
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
            .font(.footnote)
            .foregroundStyle(tint)
            .padding(6)
            .background(RoundedRectangle(cornerRadius: 8).fill(tint.opacity(0.15)))
    }

    private func parseDate(_ string: String) -> Date? {
        if let date = isoFormatter.date(from: string) {
            return date
        }

        return dateOnlyFormatter.date(from: string)
    }
}
