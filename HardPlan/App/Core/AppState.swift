//
//  AppState.swift
//  HardPlan
//
//  Central store holding live application data. Hydrates from repositories
//  and exposes actions for onboarding and debugging resets.

import Combine
import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published var userProfile: UserProfile?
    @Published var activeProgram: ActiveProgram?
    @Published var workoutLogs: [WorkoutLog]
    @Published var analyticsSnapshots: [AnalyticsSnapshot]

    private let userRepository: UserRepositoryProtocol
    private let workoutRepository: WorkoutRepositoryProtocol
    private let exerciseRepository: ExerciseRepositoryProtocol
    private let analyticsService: AnalyticsServiceProtocol
    private let progressionService: ProgressionServiceProtocol
    private let programGenerator: ProgramGeneratorProtocol
    private let persistenceController: JSONPersistenceController

    private let activeProgramFilename = "active_program.json"

    init(
        userRepository: UserRepositoryProtocol = DependencyContainer.shared.resolve(),
        workoutRepository: WorkoutRepositoryProtocol = DependencyContainer.shared.resolve(),
        exerciseRepository: ExerciseRepositoryProtocol = DependencyContainer.shared.resolve(),
        analyticsService: AnalyticsServiceProtocol = DependencyContainer.shared.resolve(),
        progressionService: ProgressionServiceProtocol = DependencyContainer.shared.resolve(),
        programGenerator: ProgramGeneratorProtocol = DependencyContainer.shared.resolve(),
        persistenceController: JSONPersistenceController = DependencyContainer.shared.resolve()
    ) {
        self.userRepository = userRepository
        self.workoutRepository = workoutRepository
        self.exerciseRepository = exerciseRepository
        self.analyticsService = analyticsService
        self.progressionService = progressionService
        self.programGenerator = programGenerator
        self.persistenceController = persistenceController
        self.workoutLogs = []
        self.analyticsSnapshots = []
        print("✅ AppState: Initialized.")
    }

    func loadData() {
        userProfile = userRepository.getProfile()
        activeProgram = loadActiveProgram()
        workoutLogs = workoutRepository.getHistory()
        refreshAnalytics()
    }

    func onboardUser(profile: UserProfile) {
        var storedProfile = profile
        storedProfile.onboardingCompleted = true

        userRepository.saveProfile(storedProfile)
        userProfile = storedProfile

        if activeProgram == nil {
            activeProgram = programGenerator.generateProgram(for: storedProfile)
            persistActiveProgram()
        }
    }

    func resetApp() {
        userRepository.deleteProfile()
        workoutRepository.deleteAll()
        persistenceController.delete(filename: activeProgramFilename)

        userProfile = nil
        activeProgram = nil
        workoutLogs = []
    }

    func appendWorkoutLog(_ log: WorkoutLog) {
        workoutLogs.append(log)
        workoutRepository.saveLog(log)
        refreshAnalytics()
    }

    func persistActiveProgram() {
        guard let activeProgram else { return }
        persistenceController.save(activeProgram, to: activeProgramFilename)
    }

    func completeWorkout(_ log: WorkoutLog) {
        appendWorkoutLog(log)
        guard var program = activeProgram, let userProfile else { return }

        let exerciseLookup = Dictionary(uniqueKeysWithValues: exerciseRepository
            .getAllExercises()
            .map { ($0.id, $0) })

        for exerciseLog in log.exercises {
            guard let exercise = exerciseLookup[exerciseLog.exerciseId] else { continue }
            let repRange = repRange(from: exerciseLog)
            let currentState = program.progressionData[exerciseLog.exerciseId] ?? seedState(from: exerciseLog)
            let nextState = progressionService.calculateNextState(
                current: currentState,
                log: log,
                exercise: exercise,
                user: userProfile,
                program: program,
                repRange: repRange
            )

            program.progressionData[exerciseLog.exerciseId] = nextState
        }

        program.weeklySchedule = program.weeklySchedule.map { session in
            var updatedSession = session
            for index in updatedSession.exercises.indices {
                let exerciseId = updatedSession.exercises[index].exerciseId
                if let state = program.progressionData[exerciseId] {
                    updatedSession.exercises[index].targetLoad = state.currentLoad
                    if state.currentRepTarget > 0 {
                        updatedSession.exercises[index].targetReps = state.currentRepTarget
                    }
                }
            }
            return updatedSession
        }

        activeProgram = program
        persistActiveProgram()
        refreshAnalytics()
    }

    private func refreshAnalytics() {
        guard let activeProgram else {
            analyticsSnapshots = []
            return
        }

        analyticsSnapshots = analyticsService.updateSnapshots(program: activeProgram, logs: workoutLogs)
    }

    private func repRange(from exerciseLog: CompletedExercise) -> ClosedRange<Int>? {
        let reps = exerciseLog.sets.map(\.targetReps)
        guard let min = reps.min(), let max = reps.max(), min > 0, max > 0 else {
            return nil
        }

        return min...max
    }

    private func seedState(from exerciseLog: CompletedExercise) -> ProgressionState {
        let targetReps = exerciseLog.sets.map(\.targetReps).max() ?? 0
        let lastLoad = exerciseLog.sets.last?.load ?? 0
        return ProgressionState(
            exerciseId: exerciseLog.exerciseId,
            currentLoad: lastLoad,
            consecutiveFails: 0,
            resetCount: 0,
            recentRPEs: [],
            baseLoad: lastLoad,
            currentRepTarget: targetReps
        )
    }

    private func loadActiveProgram() -> ActiveProgram? {
        persistenceController.load(from: activeProgramFilename)
    }
}
