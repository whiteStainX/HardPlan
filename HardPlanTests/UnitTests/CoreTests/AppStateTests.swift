//
//  AppStateTests.swift
//  HardPlanTests
//
//  Verifies the business logic within the main AppState object.

import XCTest
@testable import HardPlan

// MARK: - Mocks

private final class MockUserRepository_AppState: UserRepositoryProtocol {
    func saveProfile(_ profile: UserProfile) {}
    func getProfile() -> UserProfile? { nil }
    func deleteProfile() {}
}

private final class MockWorkoutRepository_AppState: WorkoutRepositoryProtocol {
    func saveLog(_ log: WorkoutLog) {}
    func getHistory() -> [WorkoutLog] { [] }
    func overwriteHistory(_ logs: [WorkoutLog]) {}
    func deleteAll() {}
}

private final class MockExerciseRepository_AppState: ExerciseRepositoryProtocol {
    var exercisesToReturn: [Exercise] = []
    func getAllExercises() -> [Exercise] { exercisesToReturn }
    func saveUserExercise(_ exercise: Exercise) {}
}

private final class MockAnalyticsService_AppState: AnalyticsServiceProtocol {
    func calculateE1RM(load: Double, reps: Int) -> Double { 0 }
    func generateHistory(logs: [WorkoutLog], exerciseId: String) -> [E1RMPoint] { [] }
    func analyzeTempo(logs: [WorkoutLog]) -> TempoWarning? { nil }
    func updateSnapshots(program: ActiveProgram, logs: [WorkoutLog], goal: GoalSetting?, calendar: Calendar) -> [AnalyticsSnapshot] { [] }
}

private final class MockProgressionService_AppState: ProgressionServiceProtocol {
    func calculateNextState(current: ProgressionState, log: WorkoutLog, exercise: Exercise, user: UserProfile, program: ActiveProgram, repRange: ClosedRange<Int>?) -> ProgressionState { current }
    func shouldTriggerPostBlockAssessment(program: ActiveProgram, logs: [WorkoutLog], calendar: Calendar) -> Bool { false }
}

private final class MockProgramGenerator_AppState: ProgramGeneratorProtocol {
    func generateProgram(for user: UserProfile) -> ActiveProgram { ActiveProgram(startDate: "", currentBlockPhase: .introductory) }
}

private final class MockPersistenceController_AppState: JSONPersistenceController {
    override func save<T: Codable>(_ object: T, to filename: String) {}
}

// MARK: - Tests

@MainActor
final class AppStateTests: XCTestCase {
    private var sut: AppState!

    override func setUp() {
        super.setUp()
        // Use mocks for all dependencies to isolate AppState
        sut = AppState(
            userRepository: MockUserRepository_AppState(),
            workoutRepository: MockWorkoutRepository_AppState(),
            exerciseRepository: MockExerciseRepository_AppState(),
            analyticsService: MockAnalyticsService_AppState(),
            progressionService: MockProgressionService_AppState(),
            programGenerator: MockProgramGenerator_AppState(),
            persistenceController: MockPersistenceController_AppState()
        )
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testCompletePostBlockAssessment_withDeloadDecision_appliesDeload() {
        // GIVEN
        let initialSets = 4
        let scheduledExercise = ScheduledExercise(exerciseId: "squat", order: 1, targetSets: initialSets, targetReps: 5, targetLoad: 100, targetRPE: 8)
        let session = ScheduledSession(dayOfWeek: 1, name: "Test Day", exercises: [scheduledExercise])
        sut.activeProgram = ActiveProgram(startDate: "", currentBlockPhase: .accumulation, weeklySchedule: [session])
        
        let responses = PostBlockResponses(sleepQuality: 3, stressLevel: 8, acheLevel: 7) // High risk

        // WHEN
        sut.completePostBlockAssessment(decision: .deload, responses: responses)
        
        // THEN
        guard let program = sut.activeProgram else {
            XCTFail("Active program should not be nil")
            return
        }
        
        XCTAssertEqual(program.currentBlockPhase, .deload)
        XCTAssertEqual(program.consecutiveBlocksWithoutDeload, 0)
        XCTAssertEqual(program.currentWeek, 1)
        
        let updatedSets = program.weeklySchedule.first?.exercises.first?.targetSets
        XCTAssertEqual(updatedSets, 2, "Sets should be reduced by half for a deload")
    }

    func testCompletePostBlockAssessment_withNextBlockDecision_advancesProgram() {
        // GIVEN
        let session = ScheduledSession(dayOfWeek: 1, name: "Test Day", exercises: [])
        sut.activeProgram = ActiveProgram(startDate: "", currentBlockPhase: .accumulation, weeklySchedule: [session])
        
        let responses = PostBlockResponses(sleepQuality: 8, stressLevel: 4, acheLevel: 2) // Low risk

        // WHEN
        sut.completePostBlockAssessment(decision: .nextBlock, responses: responses)
        
        // THEN
        guard let program = sut.activeProgram else {
            XCTFail("Active program should not be nil")
            return
        }
        
        XCTAssertEqual(program.currentBlockPhase, .intensification, "Phase should advance from Accumulation to Intensification")
        XCTAssertEqual(program.currentWeek, 1)
        XCTAssertEqual(program.consecutiveBlocksWithoutDeload, 1)
    }
}