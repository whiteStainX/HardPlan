//
//  WorkoutSessionViewModelTests.swift
//  HardPlanTests
//
//  Verifies the state management logic of an active workout session.

import XCTest
@testable import HardPlan

// MARK: - Mocks

private final class MockWorkoutExerciseRepository: ExerciseRepositoryProtocol {
    func getAllExercises() -> [Exercise] {
        [
            Exercise(id: "squat", name: "Squat", pattern: .squat, type: .compound, equipment: .barbell, primaryMuscle: .quads),
            Exercise(id: "curls", name: "Bicep Curls", pattern: .isolation, type: .isolation, equipment: .dumbbell, primaryMuscle: .biceps),
            Exercise(id: "leg_press", name: "Leg Press", pattern: .squat, type: .machine, equipment: .machine, primaryMuscle: .quads)
        ]
    }
    func saveUserExercise(_ exercise: Exercise) {}
}

private final class MockAdherenceService: AdherenceServiceProtocol {
    var trimSessionCalled = false
    func checkScheduleStatus(lastLogDate: Date, currentDate: Date) -> AdherenceStatus { .onTrack }
    func shiftSchedule(program: ActiveProgram) -> ActiveProgram { program }
    func combineSessions(missed: ScheduledSession, current: ScheduledSession) -> ScheduledSession { current }

    func trimSession(for session: ScheduledSession) -> ScheduledSession {
        trimSessionCalled = true
        var trimmedSession = session
        trimmedSession.exercises.removeLast() // Simulate removing one accessory
        return trimmedSession
    }
}

private final class MockSubstitutionService: SubstitutionServiceProtocol {
    var optionsToReturn: [SubstitutionOption] = []
    
    func getOptions(for original: Exercise, allExercises: [Exercise], user: UserProfile) -> [SubstitutionOption] {
        return optionsToReturn
    }
}

// MARK: - Tests

@MainActor
final class WorkoutSessionViewModelTests: XCTestCase {
    private var session: ScheduledSession!
    private var mockExerciseRepo: MockWorkoutExerciseRepository!
    private var mockAdherenceService: MockAdherenceService!
    private var mockSubstitutionService: MockSubstitutionService!
    private var sut: WorkoutSessionViewModel!
    private var user: UserProfile!

    override func setUp() {
        super.setUp()
        let squat = ScheduledExercise(exerciseId: "squat", order: 1, targetSets: 3, targetReps: 5, targetLoad: 225, targetRPE: 8)
        let curls = ScheduledExercise(exerciseId: "curls", order: 2, targetSets: 3, targetReps: 12, targetLoad: 35, targetRPE: 9)
        session = ScheduledSession(dayOfWeek: 1, name: "Test Session", exercises: [squat, curls])

        mockExerciseRepo = MockWorkoutExerciseRepository()
        mockAdherenceService = MockAdherenceService()
        mockSubstitutionService = MockSubstitutionService()
        
        user = UserProfile(name: "Test", trainingAge: .novice, goal: .strength)
        
        sut = WorkoutSessionViewModel(
            session: session,
            exerciseRepository: mockExerciseRepo,
            adherenceService: mockAdherenceService,
            substitutionService: mockSubstitutionService
        )
        sut.updateUserProfile(user)
    }

    override func tearDown() {
        sut = nil
        mockAdherenceService = nil
        mockExerciseRepo = nil
        mockSubstitutionService = nil
        session = nil
        user = nil
        super.tearDown()
    }

    func testInitializesExerciseEntriesFromSession() {
        XCTAssertEqual(sut.exerciseEntries.count, 2)
        XCTAssertEqual(sut.exerciseEntries[0].exerciseName, "Squat")
        XCTAssertEqual(sut.exerciseEntries[0].sets.count, 3)
        XCTAssertEqual(sut.exerciseEntries[1].exerciseName, "Bicep Curls")
        XCTAssertEqual(sut.exerciseEntries[1].sets.count, 3)
    }

    func testMarkSetCompleteTogglesState() {
        guard let exerciseId = sut.exerciseEntries.first?.id,
              let setId = sut.exerciseEntries.first?.sets.first?.id else {
            XCTFail("Could not get IDs for test")
            return
        }

        // Mark as complete
        let result1 = sut.markSetComplete(exerciseId: exerciseId, setId: setId)
        XCTAssertTrue(result1)
        XCTAssertTrue(sut.exerciseEntries[0].sets[0].isComplete)

        // Mark as incomplete again
        let result2 = sut.markSetComplete(exerciseId: exerciseId, setId: setId)
        XCTAssertFalse(result2)
        XCTAssertFalse(sut.exerciseEntries[0].sets[0].isComplete)
    }

    func testToggleShortOnTimeCallsAdherenceServiceAndRebuildsEntries() {
        XCTAssertEqual(sut.exerciseEntries.count, 2)
        XCTAssertFalse(mockAdherenceService.trimSessionCalled)

        // WHEN
        sut.toggleShortOnTime()

        // THEN
        XCTAssertTrue(sut.isShortOnTime)
        XCTAssertTrue(mockAdherenceService.trimSessionCalled)
        XCTAssertEqual(sut.exerciseEntries.count, 1, "The trimmed session should have one fewer exercise")
        XCTAssertEqual(sut.exerciseEntries[0].exerciseName, "Squat")
        
        // WHEN toggled off
        sut.toggleShortOnTime()
        
        // THEN
        XCTAssertFalse(sut.isShortOnTime)
        XCTAssertEqual(sut.exerciseEntries.count, 2, "Toggling off should restore the original session")
    }

    func testApplySubstitutionUpdatesViewModelState() {
        // GIVEN
        let originalEntry = sut.exerciseEntries[0]
        XCTAssertEqual(originalEntry.exerciseName, "Squat")
        
        let substitution = SubstitutionOption(id: "leg_press", exerciseName: "Leg Press", specificityScore: 0.8, warning: nil)
        
        // WHEN
        sut.applySubstitution(option: substitution, to: originalEntry.id)
        
        // THEN
        let updatedEntry = sut.exerciseEntries[0]
        XCTAssertEqual(updatedEntry.exerciseName, "Leg Press")
        XCTAssertEqual(updatedEntry.scheduled.exerciseId, "leg_press")
    }

    func testAutoRegulationReducesLoadForNextSet() {
        // GIVEN
        let exerciseId = sut.exerciseEntries[0].id
        let firstSetId = sut.exerciseEntries[0].sets[0].id
        let initialNextSetLoad = sut.exerciseEntries[0].sets[1].load
        
        // Set an RPE of 9.5, which is > 1.0 over the target RPE of 8
        sut.exerciseEntries[0].sets[0].rpe = 9.5
        
        // WHEN
        _ = sut.markSetComplete(exerciseId: exerciseId, setId: firstSetId)
        
        // THEN
        let updatedNextSetLoad = sut.exerciseEntries[0].sets[1].load
        XCTAssertNotEqual(initialNextSetLoad, updatedNextSetLoad, "Load for next set should have changed")
        XCTAssertEqual(sut.toastMessage, "Load reduced for next set")
    }
}
