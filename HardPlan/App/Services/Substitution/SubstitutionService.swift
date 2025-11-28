//
//  SubstitutionService.swift
//  HardPlan
//
//  Filters and scores exercise swap options based on specificity rules.

import Foundation

protocol SubstitutionServiceProtocol {
    func getOptions(for original: Exercise, allExercises: [Exercise], user: UserProfile) -> [SubstitutionOption]
}

struct SubstitutionService: SubstitutionServiceProtocol {
    func getOptions(for original: Exercise, allExercises: [Exercise], user: UserProfile) -> [SubstitutionOption] {
        let candidates = allExercises.filter { exercise in
            exercise.id != original.id &&
                exercise.pattern == original.pattern &&
                !user.excludedExercises.contains(exercise.id)
        }

        return candidates
            .map { candidate in
                buildOption(original: original, candidate: candidate, goal: user.goal)
            }
            .sorted { $0.specificityScore > $1.specificityScore }
    }

    private func buildOption(original: Exercise, candidate: Exercise, goal: Goal) -> SubstitutionOption {
        var score = specificityScore(original: original, candidate: candidate)
        var warning: SubstitutionWarning?

        if goal == .strength && original.isCompetitionLift && !candidate.isCompetitionLift {
            score *= 0.5
            warning = SubstitutionWarning(
                level: .warning,
                message: "You are replacing a competition lift with a non-competition variant. This may reduce specificity for strength. Are you sure?"
            )
        } else if goal == .strength && !original.isCompetitionLift && candidate.isCompetitionLift {
            score = min(1.0, score + 0.2)
        }

        return SubstitutionOption(
            id: candidate.id,
            exerciseName: candidate.name,
            specificityScore: min(score, 1.0),
            warning: warning
        )
    }

    private func specificityScore(original: Exercise, candidate: Exercise) -> Double {
        var score = 0.0

        if candidate.pattern == original.pattern {
            score += 0.5
        }

        if candidate.equipment == original.equipment {
            score += 0.2
        }

        if candidate.isCompetitionLift == original.isCompetitionLift {
            score += 0.3
        }

        return min(score, 1.0)
    }
}
