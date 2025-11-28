import Foundation
import Combine

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
    var scheduled: ScheduledExercise
    var exerciseName: String
    var sets: [EditableSet]
    var originalExerciseId: String
}

@MainActor
final class WorkoutSessionViewModel: ObservableObject {
    @Published var session: ScheduledSession
    @Published var exerciseEntries: [ExerciseEntry]
    @Published var isShortOnTime: Bool = false
    @Published var toastMessage: String?

    let startedAt: Date

    private var originalSession: ScheduledSession
    private let exerciseRepository: ExerciseRepositoryProtocol
    private let adherenceService: AdherenceServiceProtocol
    private let substitutionService: SubstitutionServiceProtocol
    private let exerciseLookup: [String: Exercise]
    private let allExercises: [Exercise]
    private var userProfile: UserProfile?

    init(
        session: ScheduledSession,
        exerciseRepository: ExerciseRepositoryProtocol = DependencyContainer.shared.resolve(),
        adherenceService: AdherenceServiceProtocol = DependencyContainer.shared.resolve(),
        substitutionService: SubstitutionServiceProtocol = DependencyContainer.shared.resolve()
    ) {
        self.session = session
        self.originalSession = session
        self.exerciseRepository = exerciseRepository
        self.adherenceService = adherenceService
        let exercises = exerciseRepository.getAllExercises()
        self.exerciseLookup = Dictionary(uniqueKeysWithValues: exercises.map { ($0.id, $0) })
        self.allExercises = exercises
        self.substitutionService = substitutionService
        self.exerciseEntries = []
        self.startedAt = Date()

        rebuildEntries(from: session, preserving: [])
    }

    func updateUserProfile(_ profile: UserProfile?) {
        userProfile = profile
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

        if exerciseEntries[exerciseIndex].sets[setIndex].isComplete {
            handleAutoRegulation(for: exerciseIndex, completedSetIndex: setIndex)
        }

        return exerciseEntries[exerciseIndex].sets[setIndex].isComplete
    }

    func resetCompletionForExercise(_ exerciseId: UUID) {
        guard let index = exerciseEntries.firstIndex(where: { $0.id == exerciseId }) else { return }
        for setIndex in exerciseEntries[index].sets.indices {
            exerciseEntries[index].sets[setIndex].isComplete = false
        }
    }

    func substitutionOptions(for entry: ExerciseEntry) -> [SubstitutionOption]? {
        guard let userProfile else { return nil }
        guard let original = exerciseLookup[entry.scheduled.exerciseId] else { return [] }

        return substitutionService.getOptions(for: original, allExercises: allExercises, user: userProfile)
    }

    func applySubstitution(option: SubstitutionOption, to exerciseId: UUID) {
        guard let replacement = exerciseLookup[option.id],
              let exerciseIndex = exerciseEntries.firstIndex(where: { $0.id == exerciseId }),
              let sessionIndex = session.exercises.firstIndex(where: { $0.id == exerciseId }) else {
            return
        }

        exerciseEntries[exerciseIndex].scheduled.exerciseId = replacement.id
        exerciseEntries[exerciseIndex].exerciseName = replacement.name

        session.exercises[sessionIndex].exerciseId = replacement.id
        originalSession.exercises[sessionIndex].exerciseId = replacement.id
    }

    func clearToastMessage() {
        toastMessage = nil
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
                    sets: sets,
                    originalExerciseId: existing?.originalExerciseId ?? scheduled.exerciseId
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

    private func handleAutoRegulation(for exerciseIndex: Int, completedSetIndex: Int) {
        guard exerciseEntries.indices.contains(exerciseIndex) else { return }
        let entry = exerciseEntries[exerciseIndex]

        guard let nextIndex = entry.sets.indices.first(where: { $0 > completedSetIndex && !entry.sets[$0].isComplete }) else {
            return
        }

        let completedSet = entry.sets[completedSetIndex]
        let targetRPE = entry.scheduled.targetRPE
        let difference = completedSet.rpe - targetRPE

        guard difference > 1.0 else { return }

        guard let currentLoad = Double(completedSet.load) else { return }
        let reductionFactor = 0.95
        let minIncrement = userProfile?.minPlateIncrement ?? 2.5
        let adjustedLoad = roundToIncrement(currentLoad * reductionFactor, increment: minIncrement)

        exerciseEntries[exerciseIndex].sets[nextIndex].load = String(format: "%.0f", adjustedLoad)
        toastMessage = "Load reduced for next set"
    }

    private func roundToIncrement(_ value: Double, increment: Double) -> Double {
        guard increment > 0 else { return value }
        return (value / increment).rounded() * increment
    }

    func hasCompletedSets() -> Bool {
        exerciseEntries.contains { entry in
            entry.sets.contains { $0.isComplete && $0.isValid }
        }
    }

    func buildCompletedExercises() -> [CompletedExercise] {
        exerciseEntries.compactMap { entry in
            let sets = entry.sets.compactMap { set -> CompletedSet? in
                guard set.isComplete,
                      let load = Double(set.load),
                      let reps = Int(set.reps) else {
                    return nil
                }

                var tags: [SetTag] = []
                if isShortOnTime { tags.append(.aps) }

                return CompletedSet(
                    setNumber: set.setNumber,
                    targetLoad: set.targetLoad,
                    targetReps: set.targetReps,
                    load: load,
                    reps: reps,
                    rpe: set.rpe,
                    tags: tags
                )
            }

            guard !sets.isEmpty else { return nil }

            let wasSwapped = entry.scheduled.exerciseId != entry.originalExerciseId
            return CompletedExercise(
                exerciseId: entry.scheduled.exerciseId,
                sets: sets,
                wasSwapped: wasSwapped,
                originalExerciseId: wasSwapped ? entry.originalExerciseId : nil
            )
        }
    }
}

extension ExerciseEntry {
    var completionProgress: Double {
        guard !sets.isEmpty else { return 0 }
        let completed = sets.filter { $0.isComplete }.count
        return Double(completed) / Double(sets.count)
    }
}
