import SwiftUI
import UniformTypeIdentifiers

struct WeeklyCalendarView: View {
    let sessions: [ProgramSessionDisplay]
    var startWeekday: Int = 1
    var calendar: Calendar = .current
    var onSessionTap: (ProgramSessionDisplay) -> Void = { _ in }
    var droppable: Bool = false
    var onDropItem: (String, Int) -> Void = { _, _ in }
    var onClearDay: (Int) -> Void = { _ in }

    private var orderedWeekdays: [Int] {
        let normalizedStart = (1...7).contains(startWeekday) ? startWeekday : 1
        return (0..<7).map { ((normalizedStart + $0 - 1) % 7) + 1 }
    }

    private var sessionsByDay: [Int: [ProgramSessionDisplay]] {
        Dictionary(grouping: sessions, by: { $0.dayOfWeek })
    }

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 7), spacing: 12) {
            ForEach(orderedWeekdays, id: \._self) { weekday in
                dayCell(for: weekday)
            }
        }
    }

    private func dayCell(for weekday: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
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
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
}
