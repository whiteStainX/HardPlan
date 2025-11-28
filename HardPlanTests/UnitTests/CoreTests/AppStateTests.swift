//
//  AppStateTests.swift
//  HardPlanTests
//
//  Verifies the business logic within the main AppState object,
//  particularly the workout completion and program progression flow.

import XCTest
@testable import HardPlan

// MARK: - Mocks

private final class MockUserRepository_AppState: UserRepositoryProtocol {
    var savedProfile: UserProfile?
    var getProfileToReturn: UserProfile?
    var deleteCalled = false
    func saveProfile(_ profile: UserProfile) { savedProfile = profile }
    func getProfile() -> UserProfile? { getProfileToReturn }
    func deleteProfile() { deleteCalled = true }
}

private final class MockWorkoutRepository_AppState: WorkoutRepositoryProtocol {
    var savedLog: WorkoutLog?
    var deleteAllCalled = false
    func saveLog(_ log: WorkoutLog) { savedLog = log }
    func getHistory() -> [WorkoutLog] { [] }
    func overwriteHistory(_ logs: [WorkoutLog]) {}
    func deleteAll() { deleteAllCalled = true }
}

private final class MockExerciseRepository_AppState: ExerciseRepositoryProtocol {
    var exercisesToReturn: [Exercise] = []
    func getAllExercises() -> [Exercise] { exercisesToReturn }
    func saveUserExercise(_ exercise: Exercise) {}
}

private final class MockAnalyticsService_AppState: AnalyticsServiceProtocol {
    var lastProgram: ActiveProgram?
    var lastLogs: [WorkoutLog]?

    func calculateE1RM(load: Double, reps: Int) -> Double { load }
    func generateHistory(logs: [WorkoutLog], exerciseId: String) -> [E1RMPoint] { [] }
    func analyzeTempo(logs: [WorkoutLog]) -> TempoWarning? { nil }

    func updateSnapshots(program: ActiveProgram, logs: [WorkoutLog]) -> [AnalyticsSnapshot] {
        lastProgram = program
        lastLogs = logs
        return []
    }
}

private final class MockProgressionService_AppState: ProgressionServiceProtocol {
    var calculateNextStateCalled = false
    var nextStateToReturn: ProgressionState?
    func calculateNextState(current: ProgressionState, log: WorkoutLog, exercise: Exercise, user: UserProfile, program: ActiveProgram, repRange: ClosedRange<Int>?) -> ProgressionState {
        calculateNextStateCalled = true
        return nextStateToReturn ?? current
    }
}

private final class MockProgramGenerator_AppState: ProgramGeneratorProtocol {
    var generatedProgram: ActiveProgram?
    private(set) var generateCalled = false

    func generateProgram(for user: UserProfile) -> ActiveProgram {
        generateCalled = true
        if let generatedProgram {
            return generatedProgram
        }

        return ActiveProgram(startDate: "", currentBlockPhase: .introductory)
    }
}

private final class MockPersistenceController_AppState: JSONPersistenceController {
    var savedObject: (any Codable)?
    var savedFilename: String?
    override func save<T: Codable>(_ object: T, to filename: String) {
        savedObject = object
        savedFilename = filename
    }
}

// MARK: - Tests

@MainActor
final class AppStateTests: XCTestCase {
    private var mockUserRepo: MockUserRepository_AppState!
    private var mockWorkoutRepo: MockWorkoutRepository_AppState!
    private var mockExerciseRepo: MockExerciseRepository_AppState!
    private var mockAnalyticsService: MockAnalyticsService_AppState!
    private var mockProgressionService: MockProgressionService_AppState!
    private var mockProgramGenerator: MockProgramGenerator_AppState!
    private var mockPersistence: MockPersistenceController_AppState!
    private var sut: AppState!

    private let squatExercise = Exercise(id: "squat", name: "Squat", pattern: .squat, type: .compound, equipment: .barbell, primaryMuscle: .quads)

    override func setUp() {
        super.setUp()
        mockUserRepo = MockUserRepository_AppState()
        mockWorkoutRepo = MockWorkoutRepository_AppState()
        mockExerciseRepo = MockExerciseRepository_AppState()
        mockAnalyticsService = MockAnalyticsService_AppState()
        mockProgressionService = MockProgressionService_AppState()
        mockProgramGenerator = MockProgramGenerator_AppState()
        mockPersistence = MockPersistenceController_AppState()

        sut = AppState(
            userRepository: mockUserRepo,
            workoutRepository: mockWorkoutRepo,
            exerciseRepository: mockExerciseRepo,
            analyticsService: mockAnalyticsService,
            progressionService: mockProgressionService,
            programGenerator: mockProgramGenerator,
            persistenceController: mockPersistence
        )
    }

    override func tearDown() {
        sut = nil
        mockUserRepo = nil
        mockWorkoutRepo = nil
        mockExerciseRepo = nil
        mockAnalyticsService = nil
        mockProgressionService = nil
        mockProgramGenerator = nil
        mockPersistence = nil
        super.tearDown()
    }

    func testOnboardUser_generatesProgramAndPersists() {
        // GIVEN
        let userProfile = UserProfile(name: "Tester", trainingAge: .novice, goal: .strength, onboardingCompleted: false)
        let generatedProgram = ActiveProgram(startDate: "2024-01-01", currentBlockPhase: .introductory)
        mockProgramGenerator.generatedProgram = generatedProgram

        // WHEN
        sut.onboardUser(profile: userProfile)

        // THEN
        XCTAssertEqual(mockUserRepo.savedProfile?.onboardingCompleted, true)
        XCTAssertEqual(sut.activeProgram, generatedProgram)
        XCTAssertTrue(mockProgramGenerator.generateCalled)
        XCTAssertEqual(mockPersistence.savedFilename, "active_program.json")
        XCTAssertNotNil(mockPersistence.savedObject as? ActiveProgram)
    }

    func testCompleteWorkout_UpdatesProgressionStateAndSchedule() {
        // GIVEN
        let initialLoad = 100.0
        let progressedLoad = 105.0
        
        // 1. Setup AppState with a user and an active program
        sut.userProfile = UserProfile(name: "Tester", trainingAge: .novice, goal: .strength)
        let scheduledExercise = ScheduledExercise(exerciseId: squatExercise.id, order: 1, targetSets: 3, targetReps: 5, targetLoad: initialLoad, targetRPE: 8)
        let session = ScheduledSession(dayOfWeek: 1, name: "Test Day", exercises: [scheduledExercise])
        sut.activeProgram = ActiveProgram(startDate: "", currentBlockPhase: .accumulation, weeklySchedule: [session], progressionData: [:])
        
        // 2. Setup mock exercise repo
        mockExerciseRepo.exercisesToReturn = [squatExercise]
        
        // 3. Setup mock progression service to return a progressed state
        mockProgressionService.nextStateToReturn = ProgressionState(exerciseId: squatExercise.id, currentLoad: progressedLoad, currentRepTarget: 5)
        
        // 4. Create a workout log that represents the completed workout
        let completedExercise = CompletedExercise(exerciseId: squatExercise.id, sets: [
            CompletedSet(setNumber: 1, targetLoad: initialLoad, targetReps: 5, load: initialLoad, reps: 5, rpe: 8)
        ])
        let workoutLog = WorkoutLog(programId: "p1", dateScheduled: "", dateCompleted: "", durationMinutes: 60, status: .completed, mode: .normal, exercises: [completedExercise], sessionRPE: 8, wellnessScore: 4)

        // WHEN
        sut.completeWorkout(workoutLog)

        // THEN
        // 1. Verify log was saved
        XCTAssertNotNil(mockWorkoutRepo.savedLog)
        
        // 2. Verify progression service was called
        XCTAssertTrue(mockProgressionService.calculateNextStateCalled)
        
        // 3. Verify the program's progression data was updated
        let updatedProgressionData = sut.activeProgram?.progressionData[squatExercise.id]
        XCTAssertNotNil(updatedProgressionData)
        XCTAssertEqual(updatedProgressionData?.currentLoad, progressedLoad)
        
        // 4. Verify the weekly schedule for the *next* workout was updated
        let updatedScheduledExercise = sut.activeProgram?.weeklySchedule.first?.exercises.first
        XCTAssertNotNil(updatedScheduledExercise)
        XCTAssertEqual(updatedScheduledExercise?.targetLoad, progressedLoad)
        
        // 5. Verify the updated program was persisted
        XCTAssertNotNil(mockPersistence.savedObject)
        XCTAssertEqual(mockPersistence.savedFilename, "active_program.json")

        // 6. Verify analytics snapshots refreshed with latest state
        XCTAssertEqual(mockAnalyticsService.lastProgram?.progressionData[squatExercise.id]?.currentLoad, progressedLoad)
        XCTAssertEqual(mockAnalyticsService.lastLogs?.count, sut.workoutLogs.count)
    }
}
