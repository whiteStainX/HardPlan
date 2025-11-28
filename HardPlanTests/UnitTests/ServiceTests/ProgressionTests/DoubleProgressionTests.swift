//
//  DoubleProgressionTests.swift
//  HardPlanTests
//
//  Verifies double progression logic for accessory exercises.

import XCTest
@testable import HardPlan

final class DoubleProgressionTests: XCTestCase {
    private let lateralRaise = Exercise(
        id: "lat_raise",
        name: "Dumbbell Lateral Raise",
        pattern: .isolation,
        type: .isolation,
        equipment: .dumbbell,
        primaryMuscle: .deltsSide,
        secondaryMuscles: [],
        defaultTempo: ""
    )

    private var user: UserProfile {
        UserProfile(
            name: "Accessory Tester",
            trainingAge: .intermediate,
            goal: .hypertrophy,
            minPlateIncrement: 2.5
        )
    }
    
    private var program: ActiveProgram {
        ActiveProgram(
            startDate: "2024-05-01",
            currentBlockPhase: .accumulation
        )
    }

    private func log(reps: [Int]) -> WorkoutLog {
        let sets = reps.enumerated().map { index, rep in
            CompletedSet(
                setNumber: index + 1,
                targetLoad: 15,
                targetReps: 15,
                load: 15,
                reps: rep,
                rpe: 8.0
            )
        }

        return WorkoutLog(
            programId: "program",
            dateScheduled: "2024-05-10",
            dateCompleted: "2024-05-10",
            durationMinutes: 60,
            status: .completed,
            mode: .normal,
            exercises: [CompletedExercise(exerciseId: lateralRaise.id, sets: sets)],
            sessionRPE: 8.0,
            wellnessScore: 8
        )
    }
    
    func testHittingTopOfRepRangeIncreasesLoad() {
        // MARK: - GIVEN
        let repRange = 12...15
        let service = ProgressionService(defaultRepRange: repRange)
        let currentState = ProgressionState(exerciseId: lateralRaise.id, currentLoad: 15, currentRepTarget: 15)
        
        let workoutLog = log(reps: [15, 15, 15]) // All sets hit top of range

        // MARK: - WHEN
        let nextState = service.calculateNextState(
            current: currentState,
            log: workoutLog,
            exercise: lateralRaise,
            user: user,
            program: program,
            repRange: repRange
        )
        
        // MARK: - THEN
        XCTAssertEqual(nextState.currentLoad, 17.5) // 15 + 2.5
        XCTAssertEqual(nextState.currentRepTarget, 12) // Resets to bottom of range
    }
    
    func testNotHittingTopOfRepRangeIncreasesReps() {
        // MARK: - GIVEN
        let repRange = 12...15
        let service = ProgressionService(defaultRepRange: repRange)
        let currentState = ProgressionState(exerciseId: lateralRaise.id, currentLoad: 15, currentRepTarget: 13)

        let workoutLog = log(reps: [14, 13, 12]) // Did not hit 15 on all sets
        
        // MARK: - WHEN
        let nextState = service.calculateNextState(
            current: currentState,
            log: workoutLog,
            exercise: lateralRaise,
            user: user,
            program: program,
            repRange: repRange
        )

        // MARK: - THEN
        XCTAssertEqual(nextState.currentLoad, 15) // Load stays the same
        XCTAssertEqual(nextState.currentRepTarget, 14) // Tries for one more rep
    }
}
