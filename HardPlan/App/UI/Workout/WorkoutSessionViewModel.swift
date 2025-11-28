import Foundation

struct EditableSet: Identifiable, Equatable {
    let id: UUID
    let setNumber: Int
    let targetLoad: Double
    let targetReps: Int

    var load: String
    var reps: String
    var rpe: Double
    var isComplete: Bool

    init(
        id: UUID = UUID(),
        setNumber: Int,
        targetLoad: Double,
        targetReps: Int,
        load: Double,
        reps: Int,
        rpe: Double,
        isComplete: Bool = false
    ) {
        self.id = id
        self.setNumber = setNumber
        self.targetLoad = targetLoad
        self.targetReps = targetReps
        self.load = String(format: "%.0f", load)
        self.reps = "\(reps)"
        self.rpe = rpe
        self.isComplete = isComplete
    }

    var isValid: Bool {
        Double(load) != nil && Int(reps) != nil
    }
}

struct ExerciseEntry: Identifiable, Equatable {
    var id: UUID { scheduled.id }
    let scheduled: ScheduledExercise
    let exerciseName: String
    var sets: [EditableSet]
}

@MainActor
final class WorkoutSessionViewModel: ObservableObject {
    @Published var session: ScheduledSession
    @Published var exerciseEntries: [ExerciseEntry]
    @Published var isShortOnTime: Bool = false

    private let originalSession: ScheduledSession
    private let exerciseRepository: ExerciseRepositoryProtocol
    private let adherenceService: AdherenceServiceProtocol
    private let exerciseLookup: [String: Exercise]

    init(
        session: ScheduledSession,
        exerciseRepository: ExerciseRepositoryProtocol = DependencyContainer.shared.resolve(),
        adherenceService: AdherenceServiceProtocol = DependencyContainer.shared.resolve()
    ) {
        self.session = session
        self.originalSession = session
        self.exerciseRepository = exerciseRepository
        self.adherenceService = adherenceService
        self.exerciseLookup = Dictionary(uniqueKeysWithValues: exerciseRepository.getAllExercises().map { ($0.id, $0) })
        self.exerciseEntries = []

        rebuildEntries(from: session, preserving: [])
    }

    func toggleShortOnTime() {
        isShortOnTime.toggle()
        let targetSession = isShortOnTime ? adherenceService.trimSession(for: originalSession) : originalSession
        session = targetSession
        rebuildEntries(from: targetSession, preserving: exerciseEntries)
    }

    func exerciseSubtitle(for exercise: ScheduledExercise) -> String {
        guard let details = exerciseLookup[exercise.exerciseId] else {
            return ""
        }

        return details.type == .compound ? "Compound" : "Accessory"
    }

    func recommendedRest(for exerciseId: String) -> Int {
        guard let details = exerciseLookup[exerciseId] else { return 90 }
        return details.isCompetitionLift || details.type == .compound ? 180 : 90
    }

    func markSetComplete(exerciseId: UUID, setId: UUID) -> Bool {
        guard let exerciseIndex = exerciseEntries.firstIndex(where: { $0.id == exerciseId }),
              let setIndex = exerciseEntries[exerciseIndex].sets.firstIndex(where: { $0.id == setId }) else {
            return false
        }

        guard exerciseEntries[exerciseIndex].sets[setIndex].isValid else {
            return false
        }

        exerciseEntries[exerciseIndex].sets[setIndex].isComplete.toggle()
        return exerciseEntries[exerciseIndex].sets[setIndex].isComplete
    }

    func resetCompletionForExercise(_ exerciseId: UUID) {
        guard let index = exerciseEntries.firstIndex(where: { $0.id == exerciseId }) else { return }
        for setIndex in exerciseEntries[index].sets.indices {
            exerciseEntries[index].sets[setIndex].isComplete = false
        }
    }

    private func rebuildEntries(from session: ScheduledSession, preserving previous: [ExerciseEntry]) {
        let previousLookup = Dictionary(uniqueKeysWithValues: previous.map { ($0.id, $0) })

        exerciseEntries = session.exercises
            .sorted { $0.order < $1.order }
            .map { scheduled in
                let existing = previousLookup[scheduled.id]
                let sets = buildSets(for: scheduled, previous: existing?.sets)
                let name = exerciseLookup[scheduled.exerciseId]?.name ?? "Exercise"

                return ExerciseEntry(
                    scheduled: scheduled,
                    exerciseName: name,
                    sets: sets
                )
            }
    }

    private func buildSets(for scheduled: ScheduledExercise, previous: [EditableSet]?) -> [EditableSet] {
        var sets: [EditableSet] = []

        for index in 0 ..< scheduled.targetSets {
            let setNumber = index + 1
            if let preserved = previous?.first(where: { $0.setNumber == setNumber }) {
                sets.append(preserved)
                continue
            }

            sets.append(
                EditableSet(
                    setNumber: setNumber,
                    targetLoad: scheduled.targetLoad,
                    targetReps: scheduled.targetReps,
                    load: scheduled.targetLoad,
                    reps: scheduled.targetReps,
                    rpe: scheduled.targetRPE
                )
            )
        }

        return sets
    }
}

extension ExerciseEntry {
    var completionProgress: Double {
        guard !sets.isEmpty else { return 0 }
        let completed = sets.filter { $0.isComplete }.count
        return Double(completed) / Double(sets.count)
    }
}
