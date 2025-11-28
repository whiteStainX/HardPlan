//
//  IntermediateStrategy.swift
//  HardPlan
//
//  Implements wave loading logic for intermediate users.

import Foundation

struct IntermediateStrategy: ProgressionStrategy {
    private let goal: Goal
    private let currentWeek: Int
    private let minPlateIncrement: Double
    private let consecutiveBlocksWithoutDeload: Int

    init(goal: Goal, currentWeek: Int, minPlateIncrement: Double, consecutiveBlocksWithoutDeload: Int) {
        self.goal = goal
        self.currentWeek = currentWeek
        self.minPlateIncrement = minPlateIncrement
        self.consecutiveBlocksWithoutDeload = consecutiveBlocksWithoutDeload
    }

    func calculateNext(current: ProgressionState, log: WorkoutLog, exercise: Exercise) -> ProgressionState {
        var next = current
        let base = current.baseLoad > 0 ? current.baseLoad : current.currentLoad
        let repTargets = goal == .strength ? [8, 7, 6] : [12, 10, 8]
        let waveIncrement = minPlateIncrement * 2

        switch currentWeek {
        case 1:
            next.currentRepTarget = repTargets[0]
            next.currentLoad = rounded(base)
        case 2:
            next.currentRepTarget = repTargets[1]
            next.currentLoad = rounded(base + waveIncrement)
        case 3:
            next.currentRepTarget = repTargets[2]
            next.currentLoad = rounded(base + waveIncrement * 2)
        default:
            if consecutiveBlocksWithoutDeload >= 3 {
                next.currentRepTarget = repTargets[0]
                next.currentLoad = rounded(base)
            } else {
                let newBase = base + waveIncrement
                next.baseLoad = rounded(newBase)
                next.currentRepTarget = repTargets[0]
                next.currentLoad = rounded(newBase)
            }
        }

        next.consecutiveFails = 0
        return next
    }

    private func rounded(_ value: Double) -> Double {
        guard minPlateIncrement > 0 else { return value }
        return (value / minPlateIncrement).rounded() * minPlateIncrement
    }
}
