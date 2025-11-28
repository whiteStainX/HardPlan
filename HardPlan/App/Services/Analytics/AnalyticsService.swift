//
//  AnalyticsService.swift
//  HardPlan
//
//  Computes derived metrics for analytics visualizations (Phase 2.5).

import Foundation

protocol AnalyticsServiceProtocol {
    func calculateE1RM(load: Double, reps: Int) -> Double
    func generateHistory(logs: [WorkoutLog], exerciseId: String) -> [E1RMPoint]
    func analyzeTempo(logs: [WorkoutLog]) -> TempoWarning?
}

struct AnalyticsService: AnalyticsServiceProtocol {
    func calculateE1RM(load: Double, reps: Int) -> Double {
        load * (1 + (Double(reps) / 30.0))
    }

    func generateHistory(logs: [WorkoutLog], exerciseId: String) -> [E1RMPoint] {
        var points: [E1RMPoint] = []

        for log in logs {
            guard let exercise = log.exercises.first(where: { $0.exerciseId == exerciseId }) else { continue }

            let eligibleSets = exercise.sets.filter { set in
                let failedSet = set.reps < set.targetReps && set.rpe >= 10.0
                let isWarmup = set.tags.contains(.warmup)

                return !failedSet && !isWarmup && set.rpe >= 7.0 && set.rpe <= 9.5
            }

            guard let topSet = eligibleSets.max(by: { lhs, rhs in lhs.load < rhs.load }) else { continue }
            let e1rm = calculateE1RM(load: topSet.load, reps: topSet.reps)
            points.append(E1RMPoint(date: log.dateCompleted, e1rm: e1rm))
        }

        return points
    }

    func analyzeTempo(logs: [WorkoutLog]) -> TempoWarning? {
        var totalWorkingSets = 0
        var slowEccentricSets = 0

        for log in logs {
            for exercise in log.exercises {
                for set in exercise.sets {
                    guard let tempo = set.actualTempo else { continue }
                    if set.tags.contains(.warmup) { continue }

                    totalWorkingSets += 1

                    if tempo.eccentric >= 5 {
                        slowEccentricSets += 1
                    }
                }
            }
        }

        guard totalWorkingSets > 0 else { return nil }

        let slowRatio = Double(slowEccentricSets) / Double(totalWorkingSets)
        if slowRatio > 0.5 {
            return TempoWarning(
                level: .warning,
                message: "Most working sets use very slow eccentrics. Consider slightly faster tempos to keep volume practical."
            )
        }

        return nil
    }
}
