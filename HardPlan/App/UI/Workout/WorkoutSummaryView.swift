import SwiftUI

struct WorkoutSummaryView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    let session: ScheduledSession
    let completedExercises: [CompletedExercise]
    let startedAt: Date
    let mode: WorkoutMode
    var dismissAction: (() -> Void)?

    @State private var notes: String = ""
    @State private var sessionRPE: Double = 7.5
    @State private var wellnessScore: Int = 4

    private let exerciseLookup: [String: Exercise]
    private let isoFormatter: ISO8601DateFormatter

    init(
        session: ScheduledSession,
        completedExercises: [CompletedExercise],
        startedAt: Date,
        mode: WorkoutMode,
        dismissAction: (() -> Void)? = nil,
        exerciseRepository: ExerciseRepositoryProtocol = DependencyContainer.shared.resolve()
    ) {
        self.session = session
        self.completedExercises = completedExercises
        self.startedAt = startedAt
        self.mode = mode
        self.dismissAction = dismissAction

        let exercises = exerciseRepository.getAllExercises()
        self.exerciseLookup = Dictionary(uniqueKeysWithValues: exercises.map { ($0.id, $0) })

        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        self.isoFormatter = formatter
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                summaryCard
                exerciseBreakdown
                feedbackSection

                if !recordMessages.isEmpty {
                    recordHighlights
                }
            }
            .padding()
        }
        .navigationTitle("Workout Summary")
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                Button(action: saveWorkout) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Save and Update Plan")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                .padding(.bottom, 4)
            }
            .background(.ultraThinMaterial)
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(session.name)
                    .font(.title3.weight(.semibold))
                Spacer()
                Label(mode == .shortOnTime ? "APS" : "Standard", systemImage: mode == .shortOnTime ? "bolt.fill" : "figure.strengthtraining.traditional")
                    .padding(8)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            HStack(spacing: 18) {
                statChip(title: "Duration", value: "\(durationMinutes()) min")
                statChip(title: "Sets", value: "\(totalSets)")
                statChip(title: "Tonnage", value: "\(Int(totalTonnage)) lbs")
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var exerciseBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Logged Exercises")
                .font(.headline)

            ForEach(completedExercises) { exercise in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(exerciseLookup[exercise.exerciseId]?.name ?? "Exercise")
                            .font(.subheadline.weight(.semibold))
                        if exercise.wasSwapped, let original = exercise.originalExerciseId {
                            Text("(swapped from \(exerciseLookup[original]?.name ?? ""))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    ForEach(exercise.sets) { set in
                        HStack {
                            Text("Set \(set.setNumber)")
                            Spacer()
                            Text("\(Int(set.load)) x \(set.reps) @ RPE \(String(format: "%.1f", set.rpe))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var feedbackSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How did it feel?")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("Session RPE: \(String(format: "%.1f", sessionRPE))")
                Slider(value: $sessionRPE, in: 5...10, step: 0.5)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Wellness: \(wellnessScore) / 5")
                Stepper(value: $wellnessScore, in: 1...5) {
                    Text("Higher is better")
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Notes")
                TextField("Optional notes", text: $notes, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private var recordHighlights: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Records Broken")
                .font(.headline)
            ForEach(recordMessages, id: \.self) { message in
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.orange)
                    Text(message)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func statChip(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func durationMinutes(at referenceDate: Date = Date()) -> Int {
        let minutes = Int(referenceDate.timeIntervalSince(startedAt) / 60)
        return max(1, minutes)
    }

    private var totalSets: Int {
        completedExercises.reduce(0) { $0 + $1.sets.count }
    }

    private var totalTonnage: Double {
        completedExercises.reduce(0) { partial, exercise in
            partial + exercise.sets.reduce(0) { $0 + ($1.load * Double($1.reps)) }
        }
    }

    private var recordMessages: [String] {
        guard !appState.workoutLogs.isEmpty else { return [] }

        var previousBest: [String: Double] = [:]
        for log in appState.workoutLogs {
            for exercise in log.exercises {
                let bestLoad = exercise.sets.map(\.load).max() ?? 0
                previousBest[exercise.exerciseId] = max(previousBest[exercise.exerciseId] ?? 0, bestLoad)
            }
        }

        return completedExercises.compactMap { exercise in
            let bestLoad = exercise.sets.map(\.load).max() ?? 0
            let prior = previousBest[exercise.exerciseId] ?? 0
            guard bestLoad > prior else { return nil }

            let name = exerciseLookup[exercise.exerciseId]?.name ?? "Exercise"
            return "New best on \(name): \(Int(bestLoad)) lbs"
        }
    }

    private func saveWorkout() {
        let completedAt = Date()
        let duration = durationMinutes(at: completedAt)
        let log = WorkoutLog(
            programId: appState.activeProgram?.id ?? "unknown",
            dateScheduled: isoFormatter.string(from: startedAt),
            dateCompleted: isoFormatter.string(from: completedAt),
            durationMinutes: duration,
            status: .completed,
            mode: mode,
            notes: notes,
            exercises: completedExercises,
            sessionRPE: sessionRPE,
            wellnessScore: wellnessScore
        )

        appState.completeWorkout(log)
        dismiss()
        dismissAction?()
    }
}

#Preview {
    let squat = CompletedSet(setNumber: 1, targetLoad: 225, targetReps: 5, load: 235, reps: 5, rpe: 8.5)
    let exercise = CompletedExercise(exerciseId: "squat", sets: [squat])
    return NavigationStack {
        WorkoutSummaryView(
            session: ScheduledSession(dayOfWeek: 2, name: "Lower Power"),
            completedExercises: [exercise],
            startedAt: Date().addingTimeInterval(-3600),
            mode: .normal
        )
        .environmentObject(AppState())
    }
}
