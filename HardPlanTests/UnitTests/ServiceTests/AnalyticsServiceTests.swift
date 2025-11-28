//
//  AnalyticsServiceTests.swift
//  HardPlanTests
//
//  Verifies derived analytics calculations for charts and warnings.

import XCTest
@testable import HardPlan

final class AnalyticsServiceTests: XCTestCase {
    private let service = AnalyticsService()

    func testCalculateE1RMUsesEpleyFormula() {
        let e1rm = service.calculateE1RM(load: 200, reps: 5)
        XCTAssertEqual(e1rm, 200 * (1 + (Double(5) / 30.0)))
    }

    func testGenerateHistoryPicksTopWorkingSetPerLog() {
        let benchPress = Exercise(
            id: "bench", name: "Bench Press", pattern: .pushHorizontal, type: .compound, equipment: .barbell,
            primaryMuscle: .chest
        )

        let log1 = WorkoutLog(
            programId: "program",
            dateScheduled: "2024-05-01",
            dateCompleted: "2024-05-01",
            durationMinutes: 60,
            status: .completed,
            mode: .normal,
            exercises: [CompletedExercise(
                exerciseId: benchPress.id,
                sets: [
                    CompletedSet(setNumber: 1, targetLoad: 135, targetReps: 8, load: 135, reps: 8, rpe: 6.5),
                    CompletedSet(setNumber: 2, targetLoad: 185, targetReps: 8, load: 185, reps: 8, rpe: 8.0),
                    CompletedSet(setNumber: 3, targetLoad: 205, targetReps: 8, load: 205, reps: 6, rpe: 10.0)
                ]
            )],
            sessionRPE: 8.5,
            wellnessScore: 7
        )

        let log2 = WorkoutLog(
            programId: "program",
            dateScheduled: "2024-05-08",
            dateCompleted: "2024-05-08",
            durationMinutes: 55,
            status: .completed,
            mode: .normal,
            exercises: [CompletedExercise(
                exerciseId: benchPress.id,
                sets: [
                    CompletedSet(setNumber: 1, targetLoad: 190, targetReps: 6, load: 190, reps: 6, rpe: 7.5, tags: [.warmup]),
                    CompletedSet(setNumber: 2, targetLoad: 205, targetReps: 6, load: 205, reps: 6, rpe: 8.5),
                    CompletedSet(setNumber: 3, targetLoad: 210, targetReps: 6, load: 210, reps: 6, rpe: 9.0)
                ]
            )],
            sessionRPE: 8.0,
            wellnessScore: 8
        )

        let points = service.generateHistory(logs: [log1, log2], exerciseId: benchPress.id)

        XCTAssertEqual(points.count, 2)
        XCTAssertEqual(points[0].date, "2024-05-01")
        XCTAssertEqual(points[1].date, "2024-05-08")

        let firstE1RM = service.calculateE1RM(load: 185, reps: 8)
        let secondE1RM = service.calculateE1RM(load: 210, reps: 6)

        XCTAssertEqual(points[0].e1rm, firstE1RM)
        XCTAssertEqual(points[1].e1rm, secondE1RM)
    }

    func testAnalyzeTempoReturnsWarningWhenSlowEccentricDominates() {
        let squat = Exercise(
            id: "squat", name: "Back Squat", pattern: .squat, type: .compound, equipment: .barbell, primaryMuscle: .quads
        )

        let slowTempo = Tempo(eccentric: 5, pause: 1, concentric: 1)
        let normalTempo = Tempo(eccentric: 3, pause: 0, concentric: 1)

        let log = WorkoutLog(
            programId: "program",
            dateScheduled: "2024-06-01",
            dateCompleted: "2024-06-01",
            durationMinutes: 70,
            status: .completed,
            mode: .normal,
            exercises: [CompletedExercise(
                exerciseId: squat.id,
                sets: [
                    CompletedSet(setNumber: 1, targetLoad: 225, targetReps: 5, load: 225, reps: 5, rpe: 8.0, actualTempo: slowTempo),
                    CompletedSet(setNumber: 2, targetLoad: 225, targetReps: 5, load: 225, reps: 5, rpe: 8.0, actualTempo: slowTempo),
                    CompletedSet(setNumber: 3, targetLoad: 225, targetReps: 5, load: 225, reps: 5, rpe: 8.0, actualTempo: normalTempo)
                ]
            )],
            sessionRPE: 8.0,
            wellnessScore: 8
        )

        let warning = service.analyzeTempo(logs: [log])
        XCTAssertNotNil(warning)
        XCTAssertEqual(warning?.level, .warning)
    }

    func testAnalyzeTempoReturnsNilWhenNoTempoDataOrMinoritySlow() {
        let deadlift = Exercise(
            id: "deadlift", name: "Deadlift", pattern: .hinge, type: .compound, equipment: .barbell, primaryMuscle: .hamstrings
        )

        let log = WorkoutLog(
            programId: "program",
            dateScheduled: "2024-06-02",
            dateCompleted: "2024-06-02",
            durationMinutes: 50,
            status: .completed,
            mode: .normal,
            exercises: [CompletedExercise(
                exerciseId: deadlift.id,
                sets: [
                    CompletedSet(setNumber: 1, targetLoad: 275, targetReps: 5, load: 275, reps: 5, rpe: 7.5),
                    CompletedSet(setNumber: 2, targetLoad: 315, targetReps: 5, load: 315, reps: 5, rpe: 8.0,
                                 actualTempo: Tempo(eccentric: 3, pause: 0, concentric: 1))
                ]
            )],
            sessionRPE: 8.0,
            wellnessScore: 8
        )

        let warning = service.analyzeTempo(logs: [log])
        XCTAssertNil(warning)
    }
}
