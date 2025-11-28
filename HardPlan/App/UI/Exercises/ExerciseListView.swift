//
//  ExerciseListView.swift
//  HardPlan
//
//  Provides a simple surface for browsing and adding user-created
//  exercises. Introduced in Phase 5.6.

import SwiftUI

struct ExerciseListView: View {
    @State private var exercises: [Exercise] = []
    @State private var isPresentingAddSheet = false
    @State private var newExercise = NewExerciseForm()

    private let exerciseRepository: ExerciseRepositoryProtocol

    init(exerciseRepository: ExerciseRepositoryProtocol = DependencyContainer.shared.resolve()) {
        self.exerciseRepository = exerciseRepository
    }

    var body: some View {
        NavigationStack {
            List {
                if !userExercises.isEmpty {
                    Section("Your Exercises") {
                        ForEach(userExercises) { exercise in
                            exerciseRow(exercise)
                        }
                    }
                }

                Section("Library") {
                    if libraryExercises.isEmpty {
                        Text("No exercises found.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(libraryExercises) { exercise in
                            exerciseRow(exercise)
                        }
                    }
                }
            }
            .navigationTitle("Exercises")
            .toolbar {
                Button {
                    resetForm()
                    isPresentingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Exercise")
            }
            .sheet(isPresented: $isPresentingAddSheet) {
                NavigationStack {
                    Form {
                        Section("Details") {
                            TextField("Name", text: $newExercise.name)
                                .textInputAutocapitalization(.words)

                            Picker("Muscle Group", selection: $newExercise.muscleGroup) {
                                ForEach(MuscleGroup.allCases, id: \.self) { group in
                                    Text(displayName(for: group)).tag(group)
                                }
                            }

                            Picker("Type", selection: $newExercise.type) {
                                ForEach(ExerciseType.allCases, id: \.self) { type in
                                    Text(type.rawValue).tag(type)
                                }
                            }

                            Picker("Equipment", selection: $newExercise.equipment) {
                                ForEach(EquipmentType.allCases, id: \.self) { equipment in
                                    Text(equipment.rawValue).tag(equipment)
                                }
                            }
                        }
                    }
                    .navigationTitle("New Exercise")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                isPresentingAddSheet = false
                            }
                        }

                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                saveExercise()
                            }
                            .disabled(!newExercise.isValid)
                        }
                    }
                }
            }
            .onAppear(perform: refreshExercises)
        }
    }

    private var userExercises: [Exercise] {
        exercises
            .filter { $0.isUserCreated }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private var libraryExercises: [Exercise] {
        exercises
            .filter { !$0.isUserCreated }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func refreshExercises() {
        exercises = exerciseRepository.getAllExercises()
    }

    private func saveExercise() {
        guard let exercise = newExercise.asExercise() else { return }
        exerciseRepository.saveUserExercise(exercise)
        refreshExercises()
        isPresentingAddSheet = false
    }

    private func resetForm() {
        newExercise = NewExerciseForm()
    }

    private func exerciseRow(_ exercise: Exercise) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(exercise.name)
                .font(.headline)
            Text("\(displayName(for: exercise.primaryMuscle)) • \(exercise.type.rawValue) • \(exercise.equipment.rawValue)")
                .font(.footnote)
                .foregroundStyle(.secondary)

            if exercise.isUserCreated {
                Text("User-created")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.12))
                    .foregroundStyle(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.vertical, 6)
    }

    private func displayName(for muscle: MuscleGroup) -> String {
        muscle.rawValue.replacingOccurrences(of: "_", with: " ")
    }
}

private struct NewExerciseForm {
    var name: String = ""
    var muscleGroup: MuscleGroup = .chest
    var type: ExerciseType = .compound
    var equipment: EquipmentType = .barbell

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func asExercise() -> Exercise? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return nil }

        return Exercise(
            name: trimmedName,
            pattern: .isolation,
            type: type,
            equipment: equipment,
            primaryMuscle: muscleGroup,
            secondaryMuscles: [],
            defaultTempo: "",
            tier: .tier3,
            isCompetitionLift: false,
            isUserCreated: true
        )
    }
}

#Preview {
    ExerciseListView(exerciseRepository: ExerciseRepository())
}
