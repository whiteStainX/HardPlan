//
//  ProgramGenerator.swift
//  HardPlan
//
//  Generates an ActiveProgram bridging the user profile to a scheduled
//  training week. Implements simplified split, volume, and exercise
//  selection logic described in Phase 3.2.

import Foundation

protocol ProgramGeneratorProtocol {
    func generateProgram(for user: UserProfile) -> ActiveProgram
}

struct ProgramGenerator: ProgramGeneratorProtocol {
    private let exerciseRepository: ExerciseRepositoryProtocol
    private let dateProvider: () -> Date
    private let isoFormatter: ISO8601DateFormatter

    init(
        exerciseRepository: ExerciseRepositoryProtocol = ExerciseRepository(),
        dateProvider: @escaping () -> Date = Date.init
    ) {
        self.exerciseRepository = exerciseRepository
        self.dateProvider = dateProvider
        self.isoFormatter = ISO8601DateFormatter()
    }

    func generateProgram(for user: UserProfile) -> ActiveProgram {
        let sessionPlans = buildSessionPlans(for: user)
        let baseVolume = volumeTarget(for: user.trainingAge)
        let muscleHitCounts = countMuscleHits(in: sessionPlans, weakPoints: user.weakPoints)

        let weeklySchedule = buildSchedule(
            from: sessionPlans,
            user: user,
            baseVolume: baseVolume,
            muscleHitCounts: muscleHitCounts
        )

        let progression = buildProgressionData(from: weeklySchedule)
        let startDate = isoFormatter.string(from: dateProvider())

        return ActiveProgram(
            startDate: startDate,
            currentBlockPhase: .introductory,
            weeklySchedule: weeklySchedule,
            progressionData: progression
        )
    }

    private func volumeTarget(for trainingAge: TrainingAge) -> Int {
        switch trainingAge {
        case .novice:
            return 10
        case .intermediate, .advanced:
            return 14
        }
    }

    private func buildSchedule(
        from plans: [SessionPlan],
        user: UserProfile,
        baseVolume: Int,
        muscleHitCounts: [MuscleGroup: Int]
    ) -> [ScheduledSession] {
        let availableDays = normalizedDays(user.availableDays, count: plans.count)
        var sessions: [ScheduledSession] = []

        for (index, plan) in plans.enumerated() {
            let dayOfWeek = availableDays[safe: index] ?? (index + 1)
            let reorderedAccessories = reorderForWeakPoints(plan.accessoryMuscles, weakPoints: user.weakPoints)

            var exercises: [ScheduledExercise] = []
            var order = 1

            for muscle in plan.primaryMuscles {
                if let scheduled = scheduleExercise(
                    for: muscle,
                    isPrimary: true,
                    order: order,
                    user: user,
                    baseVolume: baseVolume,
                    muscleHitCounts: muscleHitCounts
                ) {
                    exercises.append(scheduled.exercise)
                    order += 1
                }
            }

            for muscle in reorderedAccessories {
                if let scheduled = scheduleExercise(
                    for: muscle,
                    isPrimary: false,
                    order: order,
                    user: user,
                    baseVolume: baseVolume,
                    muscleHitCounts: muscleHitCounts
                ) {
                    exercises.append(scheduled.exercise)
                    order += 1
                }
            }

            let session = ScheduledSession(
                dayOfWeek: dayOfWeek,
                name: plan.name,
                exercises: exercises
            )
            sessions.append(session)
        }

        return sessions.sorted { $0.dayOfWeek < $1.dayOfWeek }
    }

    private func scheduleExercise(
        for muscle: MuscleGroup,
        isPrimary: Bool,
        order: Int,
        user: UserProfile,
        baseVolume: Int,
        muscleHitCounts: [MuscleGroup: Int]
    ) -> (exercise: ScheduledExercise, targetReps: Int)? {
        let tierPreferences: [ExerciseTier] = isPrimary ? [.tier1, .tier2, .tier3] : [.tier2, .tier3, .tier1]
        let exercise = selectExercise(
            for: muscle,
            tierPreferences: tierPreferences,
            excluded: Set(user.excludedExercises)
        )

        guard let exercise else {
            return nil
        }

        let hitCount = muscleHitCounts[muscle] ?? 1
        let setsPerSession = calculateSetsPerSession(
            baseVolume: baseVolume,
            hitCount: hitCount,
            isPrimary: isPrimary
        )

        let reps = targetReps(for: user.goal, isPrimary: isPrimary)
        let scheduled = ScheduledExercise(
            exerciseId: exercise.id,
            order: order,
            targetSets: setsPerSession,
            targetReps: reps,
            targetLoad: 0,
            targetRPE: targetRPE(for: user.goal),
            note: note(for: exercise),
            isWeakPointPriority: user.weakPoints.contains(muscle)
        )

        return (scheduled, reps)
    }

    private func selectExercise(
        for muscle: MuscleGroup,
        tierPreferences: [ExerciseTier],
        excluded: Set<String>
    ) -> Exercise? {
        let candidates = exerciseRepository
            .getAllExercises()
            .filter { $0.primaryMuscle == muscle && !excluded.contains($0.id) }

        return candidates.sorted { lhs, rhs in
            let lhsTierIndex = tierPreferences.firstIndex(of: lhs.tier) ?? tierPreferences.count
            let rhsTierIndex = tierPreferences.firstIndex(of: rhs.tier) ?? tierPreferences.count

            if lhsTierIndex != rhsTierIndex {
                return lhsTierIndex < rhsTierIndex
            }

            if lhs.isCompetitionLift != rhs.isCompetitionLift {
                return lhs.isCompetitionLift
            }

            return lhs.name < rhs.name
        }.first
    }

    private func calculateSetsPerSession(baseVolume: Int, hitCount: Int, isPrimary: Bool) -> Int {
        guard hitCount > 0 else { return isPrimary ? 3 : 2 }

        let perSession = Double(baseVolume) / Double(hitCount)
        let adjusted = isPrimary ? perSession : perSession * 0.7
        let rounded = Int(round(adjusted))

        return max(isPrimary ? 3 : 2, rounded)
    }

    private func targetReps(for goal: Goal, isPrimary: Bool) -> Int {
        switch goal {
        case .strength:
            return isPrimary ? 5 : 8
        case .hypertrophy:
            return isPrimary ? 8 : 12
        }
    }

    private func targetRPE(for goal: Goal) -> Double {
        switch goal {
        case .strength:
            return 8.0
        case .hypertrophy:
            return 7.5
        }
    }

    private func note(for exercise: Exercise) -> String {
        exercise.isCompetitionLift ? "Main lift focus" : ""
    }

    private func buildProgressionData(
        from schedule: [ScheduledSession]
    ) -> [String: ProgressionState] {
        var progression: [String: ProgressionState] = [:]

        for session in schedule {
            for exercise in session.exercises {
                progression[exercise.exerciseId] = ProgressionState(
                    exerciseId: exercise.exerciseId,
                    currentRepTarget: exercise.targetReps
                )
            }
        }

        return progression
    }

    private func buildSessionPlans(for user: UserProfile) -> [SessionPlan] {
        let dayCount = max(user.availableDays.count, 3)

        switch dayCount {
        case 3:
            return fullBodyPlans()
        case 4:
            return upperLowerPlans()
        case 5:
            return pushPullLegsPlans(includeSecondCycle: false)
        default:
            return pushPullLegsPlans(includeSecondCycle: dayCount >= 6)
        }
    }

    private func fullBodyPlans() -> [SessionPlan] {
        [
            SessionPlan(
                name: "Full Body A",
                primaryMuscles: [.chest, .quads],
                accessoryMuscles: [.backLats, .hamstrings, .deltsSide]
            ),
            SessionPlan(
                name: "Full Body B",
                primaryMuscles: [.backLats, .hamstrings],
                accessoryMuscles: [.chest, .quads, .deltsRear]
            ),
            SessionPlan(
                name: "Full Body C",
                primaryMuscles: [.deltsFront, .glutes],
                accessoryMuscles: [.triceps, .biceps, .calves]
            )
        ]
    }

    private func upperLowerPlans() -> [SessionPlan] {
        [
            SessionPlan(
                name: "Upper A",
                primaryMuscles: [.chest, .backLats],
                accessoryMuscles: [.deltsSide, .triceps, .biceps]
            ),
            SessionPlan(
                name: "Lower A",
                primaryMuscles: [.quads, .hamstrings],
                accessoryMuscles: [.glutes, .calves, .abs]
            ),
            SessionPlan(
                name: "Upper B",
                primaryMuscles: [.deltsFront, .backTraps],
                accessoryMuscles: [.chest, .biceps, .triceps]
            ),
            SessionPlan(
                name: "Lower B",
                primaryMuscles: [.quads, .glutes],
                accessoryMuscles: [.hamstrings, .calves, .abs]
            )
        ]
    }

    private func pushPullLegsPlans(includeSecondCycle: Bool) -> [SessionPlan] {
        var plans: [SessionPlan] = [
            SessionPlan(
                name: "Push",
                primaryMuscles: [.chest, .deltsFront],
                accessoryMuscles: [.deltsSide, .triceps]
            ),
            SessionPlan(
                name: "Pull",
                primaryMuscles: [.backLats, .backTraps],
                accessoryMuscles: [.biceps, .deltsRear]
            ),
            SessionPlan(
                name: "Legs",
                primaryMuscles: [.quads, .hamstrings],
                accessoryMuscles: [.glutes, .calves, .abs]
            )
        ]

        if includeSecondCycle {
            plans.append(contentsOf: [
                SessionPlan(
                    name: "Push (Power)",
                    primaryMuscles: [.chest, .deltsFront],
                    accessoryMuscles: [.triceps, .deltsSide]
                ),
                SessionPlan(
                    name: "Pull (Power)",
                    primaryMuscles: [.backLats, .backTraps],
                    accessoryMuscles: [.biceps, .deltsRear]
                ),
                SessionPlan(
                    name: "Legs (Power)",
                    primaryMuscles: [.quads, .hamstrings],
                    accessoryMuscles: [.glutes, .calves, .abs]
                )
            ])
        } else {
            plans.append(
                SessionPlan(
                    name: "Upper Accessory",
                    primaryMuscles: [.chest, .backLats],
                    accessoryMuscles: [.deltsSide, .biceps, .triceps]
                )
            )
        }

        return plans
    }

    private func reorderForWeakPoints(_ muscles: [MuscleGroup], weakPoints: [MuscleGroup]) -> [MuscleGroup] {
        muscles.sorted { lhs, rhs in
            let lhsPriority = weakPoints.contains(lhs)
            let rhsPriority = weakPoints.contains(rhs)

            if lhsPriority == rhsPriority {
                return lhs.rawValue < rhs.rawValue
            }

            return lhsPriority && !rhsPriority
        }
    }

    private func countMuscleHits(in plans: [SessionPlan], weakPoints: [MuscleGroup]) -> [MuscleGroup: Int] {
        var counts: [MuscleGroup: Int] = [:]

        for plan in plans {
            for muscle in plan.primaryMuscles {
                counts[muscle, default: 0] += 1
            }

            for muscle in reorderForWeakPoints(plan.accessoryMuscles, weakPoints: weakPoints) {
                counts[muscle, default: 0] += 1
            }
        }

        return counts
    }

    private func normalizedDays(_ days: [Int], count: Int) -> [Int] {
        guard !days.isEmpty else {
            return Array(1...count)
        }

        let uniqueDays = Array(Set(days)).sorted()
        if uniqueDays.count >= count {
            return Array(uniqueDays.prefix(count))
        }

        var padded = uniqueDays
        var nextDay = 1
        while padded.count < count {
            if !padded.contains(nextDay) {
                padded.append(nextDay)
            }
            nextDay += 1
        }

        return padded.sorted()
    }
}

private struct SessionPlan {
    let name: String
    let primaryMuscles: [MuscleGroup]
    let accessoryMuscles: [MuscleGroup]
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
