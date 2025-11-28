import SwiftUI

struct ScheduleView: View {
    let trainingAge: TrainingAge
    let goal: Goal
    let weakPoints: [MuscleGroup]
    @Binding var availableDays: Int
    @Binding var assignments: [Int: WorkoutBlock]
    var blocks: [WorkoutBlock]
    var startWeekday: Int = Calendar.current.firstWeekday
    let warningText: String?
    var onNext: () -> Void = {}
    var onBack: () -> Void = {}

    private var orderedWeekdays: [Int] {
        (0..<7).map { ((startWeekday + $0 - 1) % 7) + 1 }
    }

    var body: some View {
        VStack(spacing: 20) {
            header
            sessionsControl
            daySelectionList

            HStack {
                Button("Back", action: onBack)
                Spacer()
                Button("Continue", action: onNext)
                    .buttonStyle(.borderedProminent)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Plan your training week")
                .font(.title2)
                .bold()
            Text("Pick which days you want to train and assign a block or choose Rest for each one.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var sessionsControl: some View {
        VStack(spacing: 12) {
            stepperControl
            warningDisplay
        }
    }
    
    private var stepperControl: some View {
        Stepper(value: Binding(
            get: { Double(availableDays) },
            set: { availableDays = clampDays(Int($0)) }
        ), in: 2...6, step: 1) {
            stepperLabel
        }
        .onChange(of: availableDays) { _ in
            assignments = [:]
        }
    }

    private var stepperLabel: some View {
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

    @ViewBuilder
    private var warningDisplay: some View {
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
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.yellow.opacity(0.1)))
        }
    }

    private var daySelectionList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Schedule your days")
                .font(.headline)

            VStack(spacing: 10) {
                ForEach(orderedWeekdays, id: \.self) { weekday in
                    dayPicker(for: weekday)
                }
            }
        }
    }

    private func dayPicker(for weekday: Int) -> some View {
        let currentSelection = assignments[weekday]

        return Menu {
            Button {
                assignments.removeValue(forKey: weekday)
            } label: {
                HStack {
                    Text("Rest")
                    if currentSelection == nil { Image(systemName: "checkmark") }
                }
            }

            Divider()

            ForEach(blocks) { block in
                Button {
                    assign(block, to: weekday)
                } label: {
                    HStack {
                        Text(block.name)
                        if block.id == currentSelection?.id { Image(systemName: "checkmark") }
                    }
                }
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(weekdayLabel(for: weekday))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(currentSelection?.name ?? "Rest")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.down")
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.tertiaryLabel).opacity(0.5)))
        }
    }

    private func assign(_ block: WorkoutBlock, to day: Int) {
        var updated = assignments

        for (existingDay, assigned) in updated where assigned.id == block.id {
            updated.removeValue(forKey: existingDay)
        }

        updated[day] = block
        assignments = updated
    }

    private func clampDays(_ days: Int) -> Int {
        max(2, min(6, days))
    }

    private func weekdayLabel(for weekday: Int) -> String {
        let symbols = Calendar.current.shortWeekdaySymbols
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
