//
//  NoviceStrategy.swift
//  HardPlan
//
//  Implements single progression with stall and hiatus handling.

import Foundation

struct NoviceStrategy: ProgressionStrategy {
    private let minPlateIncrement: Double
    private let dateProvider: () -> Date

    init(minPlateIncrement: Double, dateProvider: @escaping () -> Date = Date.init) {
        self.minPlateIncrement = minPlateIncrement
        self.dateProvider = dateProvider
    }

    func calculateNext(current: ProgressionState, log: WorkoutLog, exercise: Exercise) -> ProgressionState {
        guard let completedExercise = log.exercises.first(where: { $0.exerciseId == exercise.id }) else {
            return current
        }

        let success = completedExercise.sets.allSatisfy { $0.reps >= $0.targetReps }
        let daysSinceLast = daysSince(dateString: log.dateCompleted)

        if daysSinceLast > 14 {
            return applyReduction(current: current, multiplier: 0.8)
        }

        if success {
            return onSuccess(current: current, exercise: exercise)
        } else {
            return onFailure(current: current)
        }
    }

    private func onSuccess(current: ProgressionState, exercise: Exercise) -> ProgressionState {
        var next = current
        next.currentLoad = rounded(current.currentLoad + loadIncrement(for: exercise))
        next.consecutiveFails = 0
        return next
    }

    private func onFailure(current: ProgressionState) -> ProgressionState {
        var next = current
        let failures = current.consecutiveFails + 1

        if failures >= 2 {
            next = applyReduction(current: current, multiplier: 0.9)
            next.resetCount += 1
            next.consecutiveFails = 0
        } else {
            next.consecutiveFails = failures
        }

        return next
    }

    private func applyReduction(current: ProgressionState, multiplier: Double) -> ProgressionState {
        var next = current
        next.currentLoad = rounded(current.currentLoad * multiplier)
        next.consecutiveFails = 0
        return next
    }

    private func loadIncrement(for exercise: Exercise) -> Double {
        let lowerBodyMuscles: Set<MuscleGroup> = [.quads, .hamstrings, .glutes, .calves]
        return lowerBodyMuscles.contains(exercise.primaryMuscle) ? minPlateIncrement * 2 : minPlateIncrement
    }

    private func rounded(_ value: Double) -> Double {
        guard minPlateIncrement > 0 else { return value }
        return (value / minPlateIncrement).rounded() * minPlateIncrement
    }

    private func daysSince(dateString: String) -> Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        guard let date = formatter.date(from: dateString) else { return 0 }
        let interval = dateProvider().timeIntervalSince(date)
        return Int(interval / 86_400)
    }
}
