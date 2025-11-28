//
//  DoubleProgressionStrategy.swift
//  HardPlan
//
//  Handles accessory lift progression within a rep range.

import Foundation

struct DoubleProgressionStrategy: ProgressionStrategy {
    private let repRange: ClosedRange<Int>
    private let minPlateIncrement: Double

    init(repRange: ClosedRange<Int>, minPlateIncrement: Double) {
        self.repRange = repRange
        self.minPlateIncrement = minPlateIncrement
    }

    func calculateNext(current: ProgressionState, log: WorkoutLog, exercise: Exercise) -> ProgressionState {
        guard let completedExercise = log.exercises.first(where: { $0.exerciseId == exercise.id }) else {
            return current
        }

        let hitTopRange = completedExercise.sets.allSatisfy { $0.reps >= repRange.upperBound }
        var next = current
        let currentTarget = current.currentRepTarget == 0 ? repRange.lowerBound : current.currentRepTarget

        if hitTopRange {
            next.currentLoad = rounded(current.currentLoad + minPlateIncrement)
            next.currentRepTarget = repRange.lowerBound
        } else {
            next.currentLoad = current.currentLoad
            next.currentRepTarget = min(currentTarget + 1, repRange.upperBound)
        }

        return next
    }

    private func rounded(_ value: Double) -> Double {
        guard minPlateIncrement > 0 else { return value }
        return (value / minPlateIncrement).rounded() * minPlateIncrement
    }
}
