//
//  ProgramGenerator.swift
//  HardPlan
//
//  Generates an ActiveProgram bridging the user profile to a scheduled
//  training week. Implements simplified split, volume, and exercise
//  selection logic described in Phase 3.2.

import Foundation

protocol ProgramGeneratorProtocol {
    func generateProgram(for user: UserProfile, assignedBlocks: [Int: WorkoutBlock]?) -> ActiveProgram
    func generateWeeklyBlocks(for user: UserProfile) -> [WorkoutBlock]
}

extension ProgramGeneratorProtocol {
    func generateProgram(for user: UserProfile) -> ActiveProgram {
        generateProgram(for: user, assignedBlocks: nil)
    }
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

    func generateProgram(for user: UserProfile, assignedBlocks: [Int: WorkoutBlock]? = nil) -> ActiveProgram {
        var programUser = user

        let sessionPlans: [SessionPlan]
        if let assignedBlocks, !assignedBlocks.isEmpty {
            let sortedDays = assignedBlocks.keys.sorted()
            programUser.availableDays = sortedDays
            sessionPlans = sortedDays.compactMap { day in
                guard let block = assignedBlocks[day] else { return nil }
                return SessionPlan(
                    name: block.name,
                    primaryMuscles: block.primaryMuscles,
                    accessoryMuscles: block.accessoryMuscles
                )
            }
        } else {
            sessionPlans = buildSessionPlans(for: user)
        }

        let baseVolume = volumeTarget(for: user.trainingAge)
        let introAdjustedVolume = introductoryAdjustedVolume(baseVolume)
        let muscleHitCounts = countMuscleHits(in: sessionPlans, weakPoints: programUser.weakPoints)

        let weeklySchedule = buildSchedule(
            from: sessionPlans,
            user: programUser,
            baseVolume: introAdjustedVolume,
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

    func generateWeeklyBlocks(for user: UserProfile) -> [WorkoutBlock] {
        buildSessionPlans(for: user).map { plan in
            WorkoutBlock(
                name: plan.name,
                primaryMuscles: plan.primaryMuscles,
                accessoryMuscles: plan.accessoryMuscles
            )
        }
    }

    private func volumeTarget(for trainingAge: TrainingAge) -> Int {
        switch trainingAge {
        case .novice:
            return 11
        case .intermediate:
            return 14
        case .advanced:
            return 18
        }
    }

    private func introductoryAdjustedVolume(_ baseVolume: Int) -> Int {
        let adjusted = Int(round(Double(baseVolume) * 0.75))
        return max(6, adjusted)
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
            targetRPE: targetRPE(
                for: user.goal,
                isPrimary: isPrimary,
                exercise: exercise,
                trainingAge: user.trainingAge
            ),
            note: note(
                for: exercise,
                goal: user.goal,
                trainingAge: user.trainingAge,
                isPrimary: isPrimary
            ),
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
            return isPrimary ? 4 : 8
        case .hypertrophy:
            return isPrimary ? 8 : 12
        }
    }

    private func targetRPE(
        for goal: Goal,
        isPrimary: Bool,
        exercise: Exercise,
        trainingAge: TrainingAge
    ) -> Double {
        let base: Double
        switch goal {
        case .strength:
            base = isPrimary || exercise.isCompetitionLift ? 8.5 : 8.0
        case .hypertrophy:
            base = isPrimary ? 7.5 : 8.5
        }

        let trainingAgeOffset: Double
        switch trainingAge {
        case .novice:
            trainingAgeOffset = -0.5
        case .intermediate:
            trainingAgeOffset = 0
        case .advanced:
            trainingAgeOffset = 0.5
        }

        let introductoryOffset = -1.0
        let target = base + trainingAgeOffset + introductoryOffset

        return min(10.0, max(5.0, target))
    }

    private func note(
        for exercise: Exercise,
        goal: Goal,
        trainingAge: TrainingAge,
        isPrimary: Bool
    ) -> String {
        var components: [String] = []

        if exercise.isCompetitionLift {
            components.append("Main lift focus")
        }

        switch trainingAge {
        case .novice:
            components.append("Single progression: keep reps steady, add 2.5–10 lbs when all sets land at target.")
            components.append("Miss targets twice? Drop ~10% then rebuild.")
        case .intermediate:
            if isPrimary {
                components.append("Use 3-week wave loading (reps trend down as load trends up).")
            } else {
                components.append("Double progression: push reps to the top of the range before adding load.")
            }
            components.append("If fatigue climbs, plan a light deload week after the wave.")
        case .advanced:
            components.append("Block focus: accumulate with extra sets/reps, then intensify with heavier, lower-rep work.")
            components.append("Intro week runs at ~75% volume and ~1 RPE lower to manage fatigue.")
        }

        switch goal {
        case .strength:
            components.append("Keep ~⅔ of work in the 1–6 rep range; use accessories to fill remaining volume.")
        case .hypertrophy:
            components.append("Aim for most work in the 6–12 rep range; higher reps are fine on accessories.")
        }

        return components.joined(separator: " ")
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
