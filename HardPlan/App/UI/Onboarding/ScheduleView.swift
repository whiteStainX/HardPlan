import SwiftUI
import UniformTypeIdentifiers

struct ScheduleView: View {
    let trainingAge: TrainingAge
    let goal: Goal
    let weakPoints: [MuscleGroup]
    @Binding var availableDays: Int
    @Binding var assignments: [Int: WorkoutBlock]
    var blocks: [WorkoutBlock]
    let warningText: String?
    var onNext: () -> Void = {}
    var onBack: () -> Void = {}

    private var availableBlocks: [WorkoutBlock] {
        blocks.filter { block in
            !assignments.values.contains(where: { $0.id == block.id })
        }
    }

    private var sessionDisplays: [ProgramSessionDisplay] {
        assignments.map { day, block in
            ProgramSessionDisplay(
                id: block.id,
                dayOfWeek: day,
                dayLabel: weekdayLabel(for: day),
                sessionName: block.name,
                exercises: []
            )
        }
    }

    private var blockLookup: [UUID: WorkoutBlock] {
        Dictionary(uniqueKeysWithValues: blocks.map { ($0.id, $0) })
    }

    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Plan your training week")
                    .font(.title2)
                    .bold()
                Text("Drag workouts into the days you plan to train. We’ll build your split based on this schedule.")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                Stepper(value: Binding(
                    get: { Double(availableDays) },
                    set: { availableDays = clampDays(Int($0)) }
                ), in: 2...6, step: 1) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Sessions per week")
                                .bold()
                            Text("Training age: \(trainingAge.readable)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(availableDays) sessions")
                    }
                }
                .onChange(of: availableDays) { _ in
                    assignments = [:]
                }

                if let warningText {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.yellow)
                        Text(warningText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.yellow.opacity(0.1))
                    )
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Available blocks")
                    .font(.headline)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                    ForEach(availableBlocks) { block in
                        Text(block.name)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(.tertiaryLabel), lineWidth: 1)
                            )
                            .onDrag {
                                NSItemProvider(object: block.id.uuidString as NSString)
                            }
                    }

                    if availableBlocks.isEmpty {
                        Text("All blocks assigned. Drag to a new day to rearrange.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Tap or drop to schedule")
                    .font(.headline)

                WeeklyCalendarView(
                    sessions: sessionDisplays,
                    startWeekday: 1,
                    onSessionTap: { session in
                        assignments.removeValue(forKey: session.dayOfWeek)
                    },
                    droppable: true,
                    onDropItem: { idString, day in
                        guard let uuid = UUID(uuidString: idString), let block = blockLookup[uuid] else { return }
                        assignments[day] = block
                    },
                    onClearDay: { day in
                        assignments.removeValue(forKey: day)
                    }
                )
            }

            HStack {
                Button("Back", action: onBack)
                Spacer()
                Button("Continue", action: onNext)
                    .buttonStyle(.borderedProminent)
            }
        }
    }

    private func clampDays(_ days: Int) -> Int {
        max(2, min(6, days))
    }

    private func weekdayLabel(for weekday: Int) -> String {
        let symbols = Calendar.current.weekdaySymbols
        if weekday >= 1 && weekday <= symbols.count {
            return symbols[weekday - 1]
        }

        return "Day \(weekday)"
    }
}

#Preview {
    ScheduleView(
        trainingAge: .novice,
        goal: .hypertrophy,
        weakPoints: [],
        availableDays: .constant(4),
        assignments: .constant([:]),
        blocks: [
            WorkoutBlock(name: "Upper A", primaryMuscles: [.chest, .backLats], accessoryMuscles: []),
            WorkoutBlock(name: "Lower A", primaryMuscles: [.quads, .hamstrings], accessoryMuscles: [])
        ],
        warningText: "Sample warning"
    )
        .padding()
}
