//
//  AdherenceServiceTests.swift
//  HardPlanTests
//
//  Verifies schedule shifting and session combination rules.

import XCTest
@testable import HardPlan

final class AdherenceServiceTests: XCTestCase {
    func testCheckScheduleStatusDetectsReturnFromBreak() {
        let calendar = Calendar(identifier: .gregorian)
        let currentDate = calendar.date(from: DateComponents(year: 2024, month: 6, day: 15))!
        let lastLogDate = calendar.date(from: DateComponents(year: 2024, month: 6, day: 8))!

        let service = AdherenceService(calendar: calendar)
        let status = service.checkScheduleStatus(lastLogDate: lastLogDate, currentDate: currentDate)

        XCTAssertEqual(status, .returningFromBreak(daysSinceLastLog: 7, loadModifier: 0.9))
        XCTAssertEqual(status.loadModifier, 0.9)
    }

    func testShiftScheduleIncrementsStartDateAndDays() {
        let bench = ScheduledExercise(
            exerciseId: "bench",
            order: 1,
            targetSets: 4,
            targetReps: 8,
            targetLoad: 185,
            targetRPE: 7.5
        )
        let sessionOne = ScheduledSession(dayOfWeek: 1, name: "Day 1", exercises: [bench])

        let squat = ScheduledExercise(
            exerciseId: "squat",
            order: 1,
            targetSets: 5,
            targetReps: 6,
            targetLoad: 225,
            targetRPE: 8.0
        )
        let sessionTwo = ScheduledSession(dayOfWeek: 5, name: "Day 5", exercises: [squat])

        let program = ActiveProgram(
            startDate: "2024-06-01",
            currentBlockPhase: .accumulation,
            weeklySchedule: [sessionOne, sessionTwo]
        )

        let service = AdherenceService()
        let shifted = service.shiftSchedule(program: program)

        XCTAssertEqual(shifted.startDate, "2024-06-02")
        XCTAssertEqual(shifted.weeklySchedule.map { $0.dayOfWeek }, [2, 6])
        XCTAssertEqual(shifted.weeklySchedule.first?.exercises.first?.exerciseId, "bench")
        XCTAssertEqual(shifted.weeklySchedule.last?.exercises.first?.exerciseId, "squat")
    }

    func testCombineSessionsKeepsCompoundsAndCapsAccessories() {
        let squat = Exercise(
            id: "squat",
            name: "Back Squat",
            pattern: .squat,
            type: .compound,
            equipment: .barbell,
            primaryMuscle: .quads,
            defaultTempo: "3-1-1",
            tier: .tier1,
            isCompetitionLift: true
        )

        let bench = Exercise(
            id: "bench",
            name: "Bench Press",
            pattern: .pushHorizontal,
            type: .compound,
            equipment: .barbell,
            primaryMuscle: .chest,
            defaultTempo: "2-1-1",
            tier: .tier1
        )

        let curls = Exercise(
            id: "curls",
            name: "Dumbbell Curls",
            pattern: .isolation,
            type: .isolation,
            equipment: .dumbbell,
            primaryMuscle: .biceps,
            defaultTempo: "2-1-2",
            tier: .tier3
        )

        let flyes = Exercise(
            id: "flyes",
            name: "Cable Fly",
            pattern: .pushHorizontal,
            type: .isolation,
            equipment: .cable,
            primaryMuscle: .chest,
            defaultTempo: "2-1-2",
            tier: .tier3
        )

        let extendedAbs = Exercise(
            id: "abs",
            name: "Hanging Leg Raise",
            pattern: .isolation,
            type: .isolation,
            equipment: .bodyweight,
            primaryMuscle: .abs,
            defaultTempo: "2-1-2",
            tier: .tier2
        )

        let repository = MockAdherenceExerciseRepository(exercises: [squat, bench, curls, flyes, extendedAbs])
        let service = AdherenceService(exerciseRepository: repository)

        let missedSession = ScheduledSession(
            dayOfWeek: 2,
            name: "Upper",
            exercises: [
                ScheduledExercise(exerciseId: bench.id, order: 1, targetSets: 5, targetReps: 8, targetLoad: 185, targetRPE: 7.5),
                ScheduledExercise(exerciseId: curls.id, order: 2, targetSets: 4, targetReps: 12, targetLoad: 35, targetRPE: 8.0),
                ScheduledExercise(exerciseId: extendedAbs.id, order: 3, targetSets: 8, targetReps: 15, targetLoad: 0, targetRPE: 7.0)
            ]
        )

        let currentSession = ScheduledSession(
            dayOfWeek: 3,
            name: "Lower", 
            exercises: [
                ScheduledExercise(exerciseId: squat.id, order: 1, targetSets: 5, targetReps: 6, targetLoad: 225, targetRPE: 8.0),
                ScheduledExercise(exerciseId: flyes.id, order: 2, targetSets: 6, targetReps: 12, targetLoad: 60, targetRPE: 7.0)
            ]
        )

        let combined = service.combineSessions(missed: missedSession, current: currentSession)

        XCTAssertEqual(combined.dayOfWeek, currentSession.dayOfWeek)
        XCTAssertEqual(combined.name, "Combined: \(missedSession.name) + \(currentSession.name)")
        XCTAssertEqual(combined.exercises.count, 4)

        let compoundExercises = combined.exercises.prefix(2)
        XCTAssertEqual(compoundExercises.map { $0.exerciseId }, [squat.id, bench.id])

        let accessoryExercises = combined.exercises.suffix(2)
        XCTAssertEqual(accessoryExercises.map { $0.targetSets }, [5, 3])

        let totalSets = combined.exercises.map { $0.targetSets }.reduce(0, +)
        XCTAssertLessThan(totalSets, 25)
    }
}

private final class MockAdherenceExerciseRepository: ExerciseRepositoryProtocol {
    private let exercises: [Exercise]

    init(exercises: [Exercise]) {
        self.exercises = exercises
    }

    func getAllExercises() -> [Exercise] {
        exercises
    }

    func saveUserExercise(_ exercise: Exercise) {
        // No-op for tests
    }
}
