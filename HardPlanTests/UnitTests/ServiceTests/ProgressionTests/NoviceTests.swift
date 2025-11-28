//
//  NoviceTests.swift
//  HardPlanTests
//
//  Verifies novice single progression logic.

import XCTest
@testable import HardPlan

final class NoviceTests: XCTestCase {
    private let squat = Exercise(
        id: "squat",
        name: "Back Squat",
        pattern: .squat,
        type: .compound,
        equipment: .barbell,
        primaryMuscle: .quads,
        secondaryMuscles: [],
        defaultTempo: ""
    )

    private var user: UserProfile {
        UserProfile(
            name: "Tester",
            trainingAge: .novice,
            goal: .strength,
            minPlateIncrement: 2.5
        )
    }

    private var program: ActiveProgram {
        ActiveProgram(
            startDate: "2024-05-01",
            currentBlockPhase: .accumulation
        )
    }

    private func log(reps: [Int], dateCompleted: String = "2024-05-10") -> WorkoutLog {
        let sets = reps.enumerated().map { index, rep in
            CompletedSet(
                setNumber: index + 1,
                targetLoad: 135,
                targetReps: 5,
                load: 135,
                reps: rep,
                rpe: 8.0
            )
        }

        return WorkoutLog(
            programId: "program",
            dateScheduled: dateCompleted,
            dateCompleted: dateCompleted,
            durationMinutes: 60,
            status: .completed,
            mode: .normal,
            exercises: [CompletedExercise(exerciseId: squat.id, sets: sets)],
            sessionRPE: 8.5,
            wellnessScore: 7
        )
    }

    func testNoviceSuccessIncreasesLoad() {
        let service = ProgressionService(dateProvider: { Date(timeIntervalSince1970: 0) })
        let current = ProgressionState(exerciseId: squat.id, currentLoad: 135)

        let next = service.calculateNextState(
            current: current,
            log: log(reps: [5, 5, 5]),
            exercise: squat,
            user: user,
            program: program
        )

        XCTAssertEqual(next.currentLoad, 140)
        XCTAssertEqual(next.consecutiveFails, 0)
    }

    func testNoviceFirstFailRetriesSameLoad() {
        let service = ProgressionService(dateProvider: { Date(timeIntervalSince1970: 0) })
        let current = ProgressionState(exerciseId: squat.id, currentLoad: 135)

        let next = service.calculateNextState(
            current: current,
            log: log(reps: [5, 4, 5]),
            exercise: squat,
            user: user,
            program: program
        )

        XCTAssertEqual(next.currentLoad, 135)
        XCTAssertEqual(next.consecutiveFails, 1)
    }

    func testNoviceSecondFailTriggersReset() {
        let service = ProgressionService(dateProvider: { Date(timeIntervalSince1970: 0) })
        let current = ProgressionState(exerciseId: squat.id, currentLoad: 135, consecutiveFails: 1)

        let next = service.calculateNextState(
            current: current,
            log: log(reps: [4, 4, 4]),
            exercise: squat,
            user: user,
            program: program
        )

        XCTAssertEqual(next.currentLoad, 122.5)
        XCTAssertEqual(next.consecutiveFails, 0)
        XCTAssertEqual(next.resetCount, 1)
    }

    func testLongHiatusTriggersReduction() {
        // GIVEN: A log from 15 days ago
        let lastWorkoutDate = "2024-05-10"
        let workoutLog = log(reps: [5, 5, 5], dateCompleted: lastWorkoutDate)
        
        // A date provider that simulates the current date being 15 days later
        let fifteenDaysInSeconds: TimeInterval = 15 * 24 * 60 * 60
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.date(from: lastWorkoutDate)!.addingTimeInterval(fifteenDaysInSeconds)
        
        let service = ProgressionService(dateProvider: { today })
        let current = ProgressionState(exerciseId: squat.id, currentLoad: 135)

        // WHEN
        let next = service.calculateNextState(
            current: current,
            log: workoutLog,
            exercise: squat,
            user: user,
            program: program
        )

        // THEN: Load should be reduced by 20% (135 * 0.8 = 108), rounded to 107.5
        XCTAssertEqual(next.currentLoad, 107.5)
        XCTAssertEqual(next.consecutiveFails, 0)
    }
}
