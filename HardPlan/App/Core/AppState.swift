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
    @Published var userProfile: UserProfile? {
        didSet {
            persistUserProfile()
            refreshAnalytics()
            refreshPostBlockAssessmentStatus()
        }
    }
    @Published var activeProgram: ActiveProgram?
    @Published var workoutLogs: [WorkoutLog]
    @Published var analyticsSnapshots: [AnalyticsSnapshot]
    @Published var postBlockAssessmentDue: Bool

    private let userRepository: UserRepositoryProtocol
    private let workoutRepository: WorkoutRepositoryProtocol
    private let exerciseRepository: ExerciseRepositoryProtocol
    private let analyticsService: AnalyticsServiceProtocol
    private let progressionService: ProgressionServiceProtocol
    private let programGenerator: ProgramGeneratorProtocol
    private let persistenceController: JSONPersistenceController

    private let isoFormatter: ISO8601DateFormatter
    private let dateOnlyFormatter: ISO8601DateFormatter

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
        self.postBlockAssessmentDue = false

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        self.isoFormatter = isoFormatter

        let dateOnlyFormatter = ISO8601DateFormatter()
        dateOnlyFormatter.formatOptions = [.withFullDate]
        self.dateOnlyFormatter = dateOnlyFormatter
        print("✅ AppState: Initialized.")
    }

    func loadData() {
        userProfile = userRepository.getProfile()
        activeProgram = loadActiveProgram()
        workoutLogs = workoutRepository.getHistory()
        refreshAnalytics()
        refreshPostBlockAssessmentStatus()
    }

    func onboardUser(profile: UserProfile, assignedBlocks: [Int: WorkoutBlock]? = nil) {
        var storedProfile = profile
        storedProfile.onboardingCompleted = true

        userRepository.saveProfile(storedProfile)
        userProfile = storedProfile

        if activeProgram == nil {
            activeProgram = programGenerator.generateProgram(for: storedProfile, assignedBlocks: assignedBlocks)
            persistActiveProgram()
        }

        refreshPostBlockAssessmentStatus()
    }

    func resetApp() {
        userRepository.deleteProfile()
        workoutRepository.deleteAll()
        persistenceController.delete(filename: activeProgramFilename)

        userProfile = nil
        activeProgram = nil
        workoutLogs = []
        analyticsSnapshots = []
        postBlockAssessmentDue = false
    }

    func appendWorkoutLog(_ log: WorkoutLog) {
        workoutLogs.append(log)
        workoutRepository.saveLog(log)
        refreshAnalytics()
        refreshPostBlockAssessmentStatus()
    }

    func persistActiveProgram() {
        guard let activeProgram else { return }
        persistenceController.save(activeProgram, to: activeProgramFilename)
    }

    private func persistUserProfile() {
        guard let userProfile else { return }
        userRepository.saveProfile(userProfile)
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

        syncProgramWeek(using: workoutLogs, program: &program)

        activeProgram = program
        persistActiveProgram()
        refreshAnalytics()
        refreshPostBlockAssessmentStatus()
    }

    func completePostBlockAssessment(decision: PostBlockDecision, responses: PostBlockResponses) {
        guard var program = activeProgram else { return }

        switch decision {
        case .deload:
            program = applyDeloadAdjustments(to: program)
        case .nextBlock:
            program = advanceToNextBlock(from: program, responses: responses)
        }

        activeProgram = program
        persistActiveProgram()
        refreshAnalytics()
        refreshPostBlockAssessmentStatus()
    }

    private func refreshAnalytics() {
        guard let activeProgram else {
            analyticsSnapshots = []
            return
        }

        analyticsSnapshots = analyticsService.updateSnapshots(program: activeProgram, logs: workoutLogs, calendar: preferredCalendar)
    }

    private func refreshPostBlockAssessmentStatus() {
        guard let program = activeProgram else {
            postBlockAssessmentDue = false
            return
        }

        postBlockAssessmentDue = progressionService.shouldTriggerPostBlockAssessment(program: program, logs: workoutLogs, calendar: preferredCalendar)
    }

    private func syncProgramWeek(using logs: [WorkoutLog], program: inout ActiveProgram) {
        guard let startDate = parseDate(program.startDate) else { return }
        let latest = logs.compactMap { parseDate($0.dateCompleted) }.max() ?? startDate

        let weekDelta = preferredCalendar.dateComponents([.weekOfYear], from: startDate, to: latest).weekOfYear ?? 0
        program.currentWeek = max(1, weekDelta + 1)
    }

    private func applyDeloadAdjustments(to program: ActiveProgram) -> ActiveProgram {
        var updated = program
        updated.currentBlockPhase = .deload
        updated.consecutiveBlocksWithoutDeload = 0
        updated.currentWeek = 1
        updated.startDate = isoFormatter.string(from: Date())

        updated.weeklySchedule = program.weeklySchedule.map { session in
            var session = session
            session.exercises = session.exercises.map { exercise in
                var exercise = exercise
                exercise.targetSets = max(1, Int(round(Double(exercise.targetSets) * 0.5)))
                exercise.targetRPE = max(6.0, exercise.targetRPE - 1.0)
                return exercise
            }
            return session
        }

        return updated
    }

    private func advanceToNextBlock(from program: ActiveProgram, responses: PostBlockResponses) -> ActiveProgram {
        var updated = program
        updated.currentBlockPhase = nextPhase(after: program.currentBlockPhase)
        updated.consecutiveBlocksWithoutDeload += program.currentBlockPhase == .deload ? 0 : 1
        updated.currentWeek = 1
        updated.startDate = isoFormatter.string(from: Date())

        let fatiguePenalty = responses.recoveryRiskScore > 1 ? 0.9 : 1.0

        updated.weeklySchedule = program.weeklySchedule.map { session in
            var session = session
            session.exercises = session.exercises.map { exercise in
                var exercise = exercise
                exercise.targetSets = max(2, Int(round(Double(exercise.targetSets) * fatiguePenalty)))
                exercise.targetRPE = min(9.5, exercise.targetRPE + 0.25)
                return exercise
            }
            return session
        }

        return updated
    }

    private func nextPhase(after current: BlockPhase) -> BlockPhase {
        switch current {
        case .introductory:
            return .accumulation
        case .accumulation:
            return .intensification
        case .intensification:
            return .realization
        case .realization, .deload:
            return .accumulation
        }
    }

    private var preferredCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = userProfile?.firstDayOfWeek ?? calendar.firstWeekday
        return calendar
    }

    private func parseDate(_ string: String) -> Date? {
        if let date = isoFormatter.date(from: string) {
            return date
        }

        return dateOnlyFormatter.date(from: string)
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
