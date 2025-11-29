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
            score = min(1.0, score + 0.1)
        }

        return SubstitutionOption(
            id: candidate.id,
            exerciseName: candidate.name,
            specificityScore: min(score, 1.0),
            warning: warning
        )
    }

    private func specificityScore(original: Exercise, candidate: Exercise) -> Double {
        let patternWeight = 0.2
        let primaryMuscleWeight = 0.35
        let secondaryMuscleWeight = 0.15
        let equipmentWeight = 0.1
        let typeWeight = 0.05
        let competitionWeight = 0.1
        let tierWeight = 0.05

        var score = 0.0

        if candidate.pattern == original.pattern {
            score += patternWeight
        }

        if candidate.primaryMuscle == original.primaryMuscle {
            score += primaryMuscleWeight
        }

        score += secondaryMuscleWeight * secondaryMuscleOverlap(original: original, candidate: candidate)
        score += equipmentWeight * equipmentSimilarity(original: original, candidate: candidate)
        score += typeWeight * movementTypeSimilarity(original: original, candidate: candidate)
        score += competitionWeight * (candidate.isCompetitionLift == original.isCompetitionLift ? 1.0 : 0.0)
        score += tierWeight * tierSimilarity(original: original, candidate: candidate)

        return min(score, 1.0)
    }

    private func secondaryMuscleOverlap(original: Exercise, candidate: Exercise) -> Double {
        let originalImpacts = Dictionary(uniqueKeysWithValues: original.secondaryMuscles.map { ($0.muscle, $0.factor) })
        let candidateImpacts = Dictionary(uniqueKeysWithValues: candidate.secondaryMuscles.map { ($0.muscle, $0.factor) })

        let sharedMuscles = Set(originalImpacts.keys).intersection(candidateImpacts.keys)
        guard !sharedMuscles.isEmpty else { return 0.0 }

        let sharedContribution = sharedMuscles.reduce(0.0) { partialResult, muscle in
            partialResult + min(originalImpacts[muscle] ?? 0, candidateImpacts[muscle] ?? 0)
        }

        let maxContribution = originalImpacts.values.reduce(0.0, +)
        guard maxContribution > 0 else { return 0.0 }

        return min(1.0, sharedContribution / maxContribution)
    }

    private func equipmentSimilarity(original: Exercise, candidate: Exercise) -> Double {
        if original.equipment == candidate.equipment {
            return 1.0
        }

        let freeWeight: Set<EquipmentType> = [.barbell, .dumbbell, .bodyweight]
        let machineLike: Set<EquipmentType> = [.machine, .cable]

        if freeWeight.contains(original.equipment) && freeWeight.contains(candidate.equipment) {
            return 0.6
        }

        if machineLike.contains(original.equipment) && machineLike.contains(candidate.equipment) {
            return 0.7
        }

        return 0.3
    }

    private func movementTypeSimilarity(original: Exercise, candidate: Exercise) -> Double {
        if original.type == candidate.type {
            return 1.0
        }

        let machineCombo: Set<ExerciseType> = [.machine, .compound]
        if machineCombo.contains(original.type) && machineCombo.contains(candidate.type) {
            return 0.6
        }

        return 0.4
    }

    private func tierSimilarity(original: Exercise, candidate: Exercise) -> Double {
        let tierRank: [ExerciseTier: Int] = [.tier1: 1, .tier2: 2, .tier3: 3]
        let originalRank = tierRank[original.tier] ?? 2
        let candidateRank = tierRank[candidate.tier] ?? 2

        let difference = abs(originalRank - candidateRank)
        switch difference {
        case 0:
            return 1.0
        case 1:
            return 0.5
        default:
            return 0.0
        }
    }
}
