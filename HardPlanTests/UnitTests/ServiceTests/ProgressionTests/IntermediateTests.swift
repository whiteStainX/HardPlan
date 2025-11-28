//
//  IntermediateTests.swift
//  HardPlanTests
//
//  Validates wave loading progression for intermediate users.

import XCTest
@testable import HardPlan

final class IntermediateTests: XCTestCase {
    private let bench = Exercise(
        id: "bench",
        name: "Bench Press",
        pattern: .pushHorizontal,
        type: .compound,
        equipment: .barbell,
        primaryMuscle: .chest,
        secondaryMuscles: [],
        defaultTempo: ""
    )

    private func user(goal: Goal) -> UserProfile {
        UserProfile(
            name: "Tester",
            trainingAge: .intermediate,
            goal: goal,
            minPlateIncrement: 2.5
        )
    }

    private func program(week: Int, consecutiveBlocksWithoutDeload: Int = 0) -> ActiveProgram {
        ActiveProgram(
            startDate: "2024-05-01",
            currentBlockPhase: .accumulation,
            currentWeek: week,
            consecutiveBlocksWithoutDeload: consecutiveBlocksWithoutDeload
        )
    }

    private var log: WorkoutLog {
        let set = CompletedSet(
            setNumber: 1,
            targetLoad: 185,
            targetReps: 8,
            load: 185,
            reps: 8,
            rpe: 8.0
        )

        return WorkoutLog(
            programId: "program",
            dateScheduled: "2024-05-10",
            dateCompleted: "2024-05-10",
            durationMinutes: 60,
            status: .completed,
            mode: .normal,
            exercises: [CompletedExercise(exerciseId: bench.id, sets: [set])],
            sessionRPE: 8.0,
            wellnessScore: 8
        )
    }

    func testWaveProgressionAcrossWeeksForStrength() {
        let service = ProgressionService()
        let testUser = user(goal: .strength)
        let baseState = ProgressionState(exerciseId: bench.id, currentLoad: 185, baseLoad: 185)

        // Week 1
        let weekOne = service.calculateNextState(current: baseState, log: log, exercise: bench, user: testUser, program: program(week: 1))
        XCTAssertEqual(weekOne.currentLoad, 185)
        XCTAssertEqual(weekOne.currentRepTarget, 8)

        // Week 2
        let weekTwo = service.calculateNextState(current: baseState, log: log, exercise: bench, user: testUser, program: program(week: 2))
        XCTAssertEqual(weekTwo.currentLoad, 190)
        XCTAssertEqual(weekTwo.currentRepTarget, 7)

        // Week 3
        let weekThree = service.calculateNextState(current: baseState, log: log, exercise: bench, user: testUser, program: program(week: 3))
        XCTAssertEqual(weekThree.currentLoad, 195)
        XCTAssertEqual(weekThree.currentRepTarget, 6)
    }
    
    func testWaveProgressionForHypertrophy() {
        let service = ProgressionService()
        let testUser = user(goal: .hypertrophy)
        let baseState = ProgressionState(exerciseId: bench.id, currentLoad: 150, baseLoad: 150)
        
        let weekOne = service.calculateNextState(current: baseState, log: log, exercise: bench, user: testUser, program: program(week: 1))
        XCTAssertEqual(weekOne.currentRepTarget, 12)

        let weekTwo = service.calculateNextState(current: baseState, log: log, exercise: bench, user: testUser, program: program(week: 2))
        XCTAssertEqual(weekTwo.currentRepTarget, 10)

        let weekThree = service.calculateNextState(current: baseState, log: log, exercise: bench, user: testUser, program: program(week: 3))
        XCTAssertEqual(weekThree.currentRepTarget, 8)
    }
    
    func testMandatoryDeloadAfterThreeBlocks() {
        let service = ProgressionService()
        let testUser = user(goal: .strength)
        let baseState = ProgressionState(exerciseId: bench.id, currentLoad: 195, baseLoad: 185)
        
        // Simulating the transition after Week 3, which is effectively "Week 4" logic
        let deloadState = service.calculateNextState(
            current: baseState,
            log: log,
            exercise: bench,
            user: testUser,
            program: program(week: 4, consecutiveBlocksWithoutDeload: 3)
        )
        
        // Should reset to Week 1 load for the deload, but NOT increase the base load yet.
        XCTAssertEqual(deloadState.baseLoad, 185) // Base load does not increase before deload
        XCTAssertEqual(deloadState.currentLoad, 185) // Deload week load is Week 1 load
        XCTAssertEqual(deloadState.currentRepTarget, 8) // Target reps reset to Week 1
    }

    func testBaseLoadIncreaseAfterSuccessfulBlock() {
        let service = ProgressionService()
        let testUser = user(goal: .strength)
        let baseState = ProgressionState(exerciseId: bench.id, currentLoad: 195, baseLoad: 185)
        
        // Simulating the transition after Week 3, where no mandatory deload is needed
        let nextBlockState = service.calculateNextState(
            current: baseState,
            log: log,
            exercise: bench,
            user: testUser,
            program: program(week: 4, consecutiveBlocksWithoutDeload: 1)
        )
        
        // Should increase base load and set current load/reps for Week 1 of the new block
        XCTAssertEqual(nextBlockState.baseLoad, 190) // 185 + 5
        XCTAssertEqual(nextBlockState.currentLoad, 190) // New Week 1 starts at new base
        XCTAssertEqual(nextBlockState.currentRepTarget, 8)
    }
}
