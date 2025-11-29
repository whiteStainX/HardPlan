import SwiftUI

struct ProgramSessionEditor: View {
    @Binding var draft: ProgramSessionDraft
    let exerciseOptions: [Exercise]
    let calendar: Calendar
    var onSave: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Session") {
                    TextField("Name", text: $draft.name)
                    Picker("Day", selection: $draft.dayOfWeek) {
                        ForEach(1...7, id: \.self) { weekday in
                            Text(dayLabel(for: weekday)).tag(weekday)
                        }
                    }
                }

                Section("Exercises") {
                    if draft.exercises.isEmpty {
                        Text("Add exercises to this session.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach($draft.exercises) { $exercise in
                            ExerciseEditorRow(
                                exercise: $exercise,
                                exerciseOptions: exerciseOptions
                            )
                        }
                        .onMove { indices, newOffset in
                            draft.reorder(from: indices, to: newOffset)
                        }
                        .onDelete { indices in
                            draft.exercises.remove(atOffsets: indices)
                        }
                    }

                    Button {
                        addExercise()
                    } label: {
                        Label("Add exercise", systemImage: "plus.circle.fill")
                    }
                }
            }
            .navigationTitle("Edit Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save", action: onSave)
                        .disabled(draft.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func dayLabel(for weekday: Int) -> String {
        let symbols = calendar.weekdaySymbols
        guard weekday >= 1, weekday <= symbols.count else { return "Day \(weekday)" }
        return symbols[weekday - 1]
    }

    private func addExercise() {
        guard let first = exerciseOptions.first else { return }
        let order = draft.exercises.count
        let newDraft = ProgramExerciseDraft(exercise: first, order: order)
        draft.exercises.append(newDraft)
    }
}

private struct ExerciseEditorRow: View {
    @Binding var exercise: ProgramExerciseDraft
    let exerciseOptions: [Exercise]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("Exercise", selection: $exercise.exerciseId) {
                ForEach(exerciseOptions) { option in
                    Text(option.name).tag(option.id)
                }
            }
            .onChange(of: exercise.exerciseId) { newValue in
                if let match = exerciseOptions.first(where: { $0.id == newValue }) {
                    exercise.name = match.name
                }
            }

            HStack {
                Stepper(value: $exercise.targetSets, in: 1...10) {
                    Text("Sets: \(exercise.targetSets)")
                }
                Stepper(value: $exercise.targetReps, in: 1...20) {
                    Text("Reps: \(exercise.targetReps)")
                }
            }

            HStack {
                TextField("Load", value: $exercise.targetLoad, format: .number)
                    .keyboardType(.decimalPad)
                TextField("RPE", value: $exercise.targetRPE, format: .number)
                    .keyboardType(.decimalPad)
            }
            .textFieldStyle(.roundedBorder)

            TextField("Notes", text: $exercise.note, axis: .vertical)
        }
    }
}
