//
//  VolumeServiceTests.swift
//  HardPlanTests
//
//  Tests the Overlap Rule implementation for weekly volume.

import XCTest
@testable import HardPlan

final class VolumeServiceTests: XCTestCase {
    func testCalculatesPrimaryAndSecondaryVolumePerSet() {
        let squat = Exercise(
            id: "squat",
            name: "Back Squat",
            pattern: .squat,
            type: .compound,
            equipment: .barbell,
            primaryMuscle: .quads,
            secondaryMuscles: [
                MuscleImpact(muscle: .glutes, factor: 1.0),
                MuscleImpact(muscle: .hamstrings, factor: 0.5)
            ],
            defaultTempo: "3-1-1"
        )

        let mockRepository = MockExerciseRepository(exercises: [squat])
        let service = VolumeService(exerciseRepository: mockRepository)

        let completedSets = [
            CompletedSet(setNumber: 1, targetLoad: 225, targetReps: 8, load: 225, reps: 8, rpe: 8.0),
            CompletedSet(setNumber: 2, targetLoad: 225, targetReps: 8, load: 225, reps: 8, rpe: 8.5),
            CompletedSet(setNumber: 3, targetLoad: 225, targetReps: 8, load: 225, reps: 8, rpe: 9.0)
        ]

        let log = WorkoutLog(
            programId: "program",
            dateScheduled: "2024-05-01",
            dateCompleted: "2024-05-01",
            durationMinutes: 60,
            status: .completed,
            mode: .normal,
            exercises: [CompletedExercise(exerciseId: squat.id, sets: completedSets)],
            sessionRPE: 8.5,
            wellnessScore: 7
        )

        let totals = service.calculateWeeklyVolume(logs: [log])

        XCTAssertEqual(totals[.quads], 3.0)
        XCTAssertEqual(totals[.glutes], 3.0)
        XCTAssertEqual(totals[.hamstrings], 1.5)
    }

    func testIgnoresExercisesMissingFromRepository() {
        let mockRepository = MockExerciseRepository(exercises: [])
        let service = VolumeService(exerciseRepository: mockRepository)

        let completedSets = [CompletedSet(setNumber: 1, targetLoad: 50, targetReps: 12, load: 50, reps: 12, rpe: 7.0)]
        let orphanExercise = CompletedExercise(exerciseId: "unknown", sets: completedSets)

        let log = WorkoutLog(
            programId: "program",
            dateScheduled: "2024-05-02",
            dateCompleted: "2024-05-02",
            durationMinutes: 45,
            status: .completed,
            mode: .normal,
            exercises: [orphanExercise],
            sessionRPE: 7.5,
            wellnessScore: 8
        )

        let totals = service.calculateWeeklyVolume(logs: [log])

        XCTAssertTrue(totals.isEmpty)
    }
}

private final class MockExerciseRepository: ExerciseRepositoryProtocol {
    private(set) var exercises: [Exercise]

    init(exercises: [Exercise]) {
        self.exercises = exercises
    }

    func getAllExercises() -> [Exercise] {
        exercises
    }

    func saveUserExercise(_ exercise: Exercise) {
        exercises.append(exercise)
    }
}
