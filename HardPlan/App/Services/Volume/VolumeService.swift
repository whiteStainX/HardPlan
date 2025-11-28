//
//  VolumeService.swift
//  HardPlan
//
//  Implements the Overlap Rule for weekly volume calculation (Phase 2.1).

import Foundation

protocol VolumeServiceProtocol {
    func calculateWeeklyVolume(logs: [WorkoutLog]) -> [MuscleGroup: Double]
}

struct VolumeService: VolumeServiceProtocol {
    private let exerciseRepository: ExerciseRepositoryProtocol
    private let secondaryMuscleDefaultFactor: Double

    init(
        exerciseRepository: ExerciseRepositoryProtocol = ExerciseRepository(),
        secondaryMuscleFactor: Double = 0.5
    ) {
        self.exerciseRepository = exerciseRepository
        self.secondaryMuscleDefaultFactor = secondaryMuscleFactor
    }

    func calculateWeeklyVolume(logs: [WorkoutLog]) -> [MuscleGroup: Double] {
        let exercisesById = Dictionary(uniqueKeysWithValues: exerciseRepository
            .getAllExercises()
            .map { ($0.id, $0) })

        var totals: [MuscleGroup: Double] = [:]

        for log in logs {
            for completedExercise in log.exercises {
                guard let exercise = exercisesById[completedExercise.exerciseId] else { continue }

                for _ in completedExercise.sets {
                    totals[exercise.primaryMuscle, default: 0] += 1.0

                    for impact in exercise.secondaryMuscles {
                        let factor = impact.factor == 0 ? secondaryMuscleDefaultFactor : impact.factor
                        totals[impact.muscle, default: 0] += factor
                    }
                }
            }
        }

        return totals
    }
}
