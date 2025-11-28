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

    func testUpdateSnapshotsBuildsTier1HistoryAndRPEDistribution() {
        let squat = Exercise(
            id: "squat",
            name: "Back Squat",
            pattern: .squat,
            type: .compound,
            equipment: .barbell,
            primaryMuscle: .quads,
            tier: .tier1
        )

        let legCurl = Exercise(
            id: "leg_curl",
            name: "Leg Curl",
            pattern: .hinge,
            type: .machine,
            equipment: .machine,
            primaryMuscle: .hamstrings,
            tier: .tier2
        )

        let program = ActiveProgram(
            startDate: "2024-05-01",
            currentBlockPhase: .accumulation,
            weeklySchedule: [
                ScheduledSession(
                    dayOfWeek: 2,
                    name: "Lower",
                    exercises: [
                        ScheduledExercise(exerciseId: squat.id, order: 1, targetSets: 3, targetReps: 5, targetLoad: 0, targetRPE: 8),
                        ScheduledExercise(exerciseId: legCurl.id, order: 2, targetSets: 3, targetReps: 12, targetLoad: 0, targetRPE: 8)
                    ]
                )
            ]
        )

        let log1 = WorkoutLog(
            programId: program.id,
            dateScheduled: "2024-05-01",
            dateCompleted: "2024-05-01",
            durationMinutes: 60,
            status: .completed,
            mode: .normal,
            exercises: [
                CompletedExercise(
                    exerciseId: squat.id,
                    sets: [
                        CompletedSet(setNumber: 1, targetLoad: 135, targetReps: 5, load: 135, reps: 5, rpe: 6.0, tags: [.warmup]),
                        CompletedSet(setNumber: 2, targetLoad: 185, targetReps: 5, load: 185, reps: 5, rpe: 7.5),
                        CompletedSet(setNumber: 3, targetLoad: 195, targetReps: 5, load: 195, reps: 5, rpe: 8.5),
                        CompletedSet(setNumber: 4, targetLoad: 205, targetReps: 5, load: 205, reps: 5, rpe: 9.2)
                    ]
                ),
                CompletedExercise(
                    exerciseId: legCurl.id,
                    sets: [CompletedSet(setNumber: 1, targetLoad: 80, targetReps: 12, load: 80, reps: 12, rpe: 7.5)]
                )
            ],
            sessionRPE: 8.0,
            wellnessScore: 7
        )

        let log2 = WorkoutLog(
            programId: program.id,
            dateScheduled: "2024-05-08",
            dateCompleted: "2024-05-08",
            durationMinutes: 55,
            status: .completed,
            mode: .normal,
            exercises: [
                CompletedExercise(
                    exerciseId: squat.id,
                    sets: [
                        CompletedSet(setNumber: 1, targetLoad: 160, targetReps: 5, load: 160, reps: 5, rpe: 6.5),
                        CompletedSet(setNumber: 2, targetLoad: 200, targetReps: 5, load: 200, reps: 5, rpe: 7.8),
                        CompletedSet(setNumber: 3, targetLoad: 210, targetReps: 5, load: 210, reps: 5, rpe: 9.0)
                    ]
                )
            ],
            sessionRPE: 8.0,
            wellnessScore: 8
        )

        let mockRepository = MockExerciseRepository_Analytics(exercises: [squat, legCurl])
        let service = AnalyticsService(exerciseRepository: mockRepository)

        let snapshots = service.updateSnapshots(program: program, logs: [log1, log2])
        XCTAssertEqual(snapshots.count, 1)

        guard let snapshot = snapshots.first else {
            XCTFail("Expected snapshot for squat")
            return
        }

        XCTAssertEqual(snapshot.liftId, squat.id)
        XCTAssertEqual(snapshot.e1RMHistory.count, 2)

        let expectedFirstE1RM = service.calculateE1RM(load: 205, reps: 5)
        let expectedSecondE1RM = service.calculateE1RM(load: 210, reps: 5)
        XCTAssertEqual(snapshot.e1RMHistory.first?.e1rm, expectedFirstE1RM)
        XCTAssertEqual(snapshot.e1RMHistory.last?.e1rm, expectedSecondE1RM)

        let bins = snapshot.rpeDistribution
        XCTAssertEqual(bins.count, 4)
        XCTAssertEqual(bins[0].count, 1) // 6-7
        XCTAssertEqual(bins[1].count, 2) // 7-8
        XCTAssertEqual(bins[2].count, 1) // 8-9
        XCTAssertEqual(bins[3].count, 2) // 9-10
        XCTAssertEqual(bins.first?.periodWeeks, 2)

        XCTAssertEqual(snapshot.blockPhaseSegments.first?.phase, program.currentBlockPhase.rawValue)
        XCTAssertEqual(snapshot.blockPhaseSegments.first?.startDate, program.startDate)
    }
}

private final class MockExerciseRepository_Analytics: ExerciseRepositoryProtocol {
    private var exercises: [Exercise]

    init(exercises: [Exercise]) {
        self.exercises = exercises
    }

    func getAllExercises() -> [Exercise] { exercises }
    func saveUserExercise(_ exercise: Exercise) { exercises.append(exercise) }
}
