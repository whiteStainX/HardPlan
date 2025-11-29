import Foundation

struct ProgramValidationIssue: Identifiable, Equatable {
    enum Severity {
        case warning
        case error
    }

    let id = UUID()
    let message: String
    let affectedDays: [Int]
    let severity: Severity
}

struct ProgramRuleSummaryItem: Identifiable, Equatable {
    enum Status {
        case met
        case needsAttention
    }

    let id = UUID()
    let title: String
    let detail: String
    let status: Status
}

struct ProgramCorrection: Identifiable {
    let id = UUID()
    let description: String
    let apply: (ActiveProgram) -> ActiveProgram
}

struct ProgramValidationResult {
    let issues: [ProgramValidationIssue]
    let ruleSummary: [ProgramRuleSummaryItem]

    var blockingIssues: [ProgramValidationIssue] {
        issues.filter { $0.severity == .error }
    }
}

protocol ProgramValidationServiceProtocol {
    func validate(program: ActiveProgram, user: UserProfile?) -> ProgramValidationResult
    func suggestedCorrections(for program: ActiveProgram) -> [ProgramCorrection]
}

final class ProgramValidationService: ProgramValidationServiceProtocol {
    private let calendar: Calendar
    private let exerciseRepository: ExerciseRepositoryProtocol

    init(calendar: Calendar = .current, exerciseRepository: ExerciseRepositoryProtocol = ExerciseRepository()) {
        self.calendar = calendar
        self.exerciseRepository = exerciseRepository
    }

    func validate(program: ActiveProgram, user: UserProfile?) -> ProgramValidationResult {
        let schedule = program.weeklySchedule
        var issues: [ProgramValidationIssue] = []

        let groupedByDay = Dictionary(grouping: schedule, by: \.dayOfWeek)
        let duplicateDays = groupedByDay.filter { $0.value.count > 1 }.keys.sorted()
        if !duplicateDays.isEmpty {
            issues.append(
                ProgramValidationIssue(
                    message: "Multiple sessions assigned to the same day: " + duplicateDays.map(dayLabel).joined(separator: ", "),
                    affectedDays: duplicateDays,
                    severity: .error
                )
            )
        }

        let sessionCount = schedule.count
        if sessionCount < 2 {
            issues.append(
                ProgramValidationIssue(
                    message: "Only \(sessionCount) training day\(sessionCount == 1 ? "" : "s"). Aim for at least 2 per week for progress.",
                    affectedDays: Array(1...7),
                    severity: .warning
                )
            )
        }

        if sessionCount > 6 {
            issues.append(
                ProgramValidationIssue(
                    message: "\(sessionCount) training days detected. Consider scheduling at least one full rest day.",
                    affectedDays: Array(1...7),
                    severity: .warning
                )
            )
        }

        let overloadedDays = schedule.filter { $0.exercises.count > 8 }.map(\.dayOfWeek)
        if !overloadedDays.isEmpty {
            issues.append(
                ProgramValidationIssue(
                    message: "Some days have more than 8 exercises; consider splitting or trimming volume.",
                    affectedDays: overloadedDays,
                    severity: .warning
                )
            )
        }

        let missingDays = Set(1...7).subtracting(groupedByDay.keys).sorted()
        if missingDays.count >= 3 {
            issues.append(
                ProgramValidationIssue(
                    message: "Several days are unscheduled (" + missingDays.map(dayLabel).joined(separator: ", ") + "). Ensure weekly balance.",
                    affectedDays: missingDays,
                    severity: .warning
                )
            )
        }

        let ruleSummary = buildRuleSummary(schedule: schedule, user: user)

        return ProgramValidationResult(issues: issues, ruleSummary: ruleSummary)
    }

    func suggestedCorrections(for program: ActiveProgram) -> [ProgramCorrection] {
        let schedule = program.weeklySchedule
        let existingDays = Set(schedule.map(\.dayOfWeek))
        let openDays = Array(Set(1...7).subtracting(existingDays)).sorted()

        var corrections: [ProgramCorrection] = []

        if let duplicateDay = mostCommonDay(in: schedule), let newDay = openDays.first {
            corrections.append(
                ProgramCorrection(
                    description: "Move one session from \(dayLabel(duplicateDay)) to \(dayLabel(newDay)) to avoid duplicates.",
                    apply: { program in
                        guard var movingSession = schedule.first(where: { $0.dayOfWeek == duplicateDay }) else { return program }
                        var updated = program
                        movingSession.dayOfWeek = newDay
                        if let index = updated.weeklySchedule.firstIndex(where: { $0.id == movingSession.id }) {
                            updated.weeklySchedule[index] = movingSession
                        }
                        return updated
                    }
                )
            )
        }

        if openDays.count >= 2, let heavyDay = schedule.max(by: { $0.exercises.count < $1.exercises.count }) {
            corrections.append(
                ProgramCorrection(
                    description: "Split \(heavyDay.name) across an open rest day to reduce overload.",
                    apply: { program in
                        guard let firstOpen = openDays.first, let idx = program.weeklySchedule.firstIndex(of: heavyDay) else {
                            return program
                        }
                        var updated = program
                        var original = heavyDay
                        let splitExercises = original.exercises.suffix(original.exercises.count / 2)
                        original.exercises.removeLast(splitExercises.count)
                        var newSession = ScheduledSession(dayOfWeek: firstOpen, name: "Balanced Session", exercises: Array(splitExercises))
                        if newSession.name.isEmpty { newSession.name = heavyDay.name }
                        updated.weeklySchedule[idx] = original
                        updated.weeklySchedule.append(newSession)
                        return updated
                    }
                )
            )
        }

        return corrections
    }

    private func dayLabel(_ weekday: Int) -> String {
        let symbols = calendar.weekdaySymbols
        guard weekday >= 1, weekday <= symbols.count else { return "Day \(weekday)" }
        return symbols[weekday - 1]
    }

    private func mostCommonDay(in schedule: [ScheduledSession]) -> Int? {
        let counts = Dictionary(grouping: schedule, by: \.dayOfWeek).mapValues { $0.count }
        return counts.max(by: { $0.value < $1.value })?.key
    }

    private func buildRuleSummary(schedule: [ScheduledSession], user: UserProfile?) -> [ProgramRuleSummaryItem] {
        guard !schedule.isEmpty else { return [] }

        let exerciseLookup = Dictionary(uniqueKeysWithValues: exerciseRepository.getAllExercises().map { ($0.id, $0) })
        let volumeByMuscle = calculateWeeklyVolume(schedule: schedule, exerciseLookup: exerciseLookup)
        let frequencyByMuscle = calculateWeeklyFrequency(schedule: schedule, exerciseLookup: exerciseLookup)
        let repDistribution = calculateRepDistribution(schedule: schedule, exerciseLookup: exerciseLookup)
        let rpeValues = schedule.flatMap { session in
            session.exercises.compactMap { exercise in exerciseLookup[exercise.exerciseId].map { _ in exercise.targetRPE } }
        }

        var summary: [ProgramRuleSummaryItem] = []

        let outOfRangeVolume = volumeByMuscle.filter { $0.value < 10 || $0.value > 20 }
        let volumeDetail: String
        if outOfRangeVolume.isEmpty {
            volumeDetail = "Weekly sets land inside the 10–20 set guideline (overlap counted)."
        } else {
            let adjustments = outOfRangeVolume
                .sorted { $0.key.rawValue < $1.key.rawValue }
                .map { "\($0.key.readableName): \(String(format: "%.1f", $0.value))" }
                .joined(separator: ", ")
            volumeDetail = "Adjust volume toward 10–20 weekly sets for: \(adjustments)."
        }

        summary.append(
            ProgramRuleSummaryItem(
                title: "Volume (10–20 sets per muscle)",
                detail: volumeDetail,
                status: outOfRangeVolume.isEmpty ? .met : .needsAttention
            )
        )

        let undertrained = frequencyByMuscle.filter { $0.value < 2 }
        let frequencyDetail: String
        if undertrained.isEmpty {
            frequencyDetail = "Each muscle/movement gets 2+ weekly exposures for quality and recovery."
        } else {
            let needsMore = undertrained
                .sorted { $0.key.rawValue < $1.key.rawValue }
                .map { "\($0.key.readableName) (\($0.value)x)" }
                .joined(separator: ", ")
            frequencyDetail = "Add another touchpoint for: \(needsMore)."
        }

        summary.append(
            ProgramRuleSummaryItem(
                title: "Frequency (2x/week per muscle)",
                detail: frequencyDetail,
                status: undertrained.isEmpty ? .met : .needsAttention
            )
        )

        if let goal = user?.goal, repDistribution.totalSets > 0 {
            let emphasis: (met: Bool, detail: String)

            switch goal {
            case .strength:
                let heavyShare = repDistribution.totalSets > 0 ? repDistribution.heavyShare : 0
                let detail = String(format: "Heavy volume: %.0f%% in the 1–6 rep range (target: ⅔–¾).", heavyShare * 100)
                emphasis = (heavyShare >= 0.66, detail)
            case .hypertrophy:
                let moderateShare = repDistribution.moderateShare
                let detail = String(format: "Working volume: %.0f%% in the 6–12 rep range (target: ⅔–¾).", moderateShare * 100)
                emphasis = (moderateShare >= 0.66, detail)
            }

            summary.append(
                ProgramRuleSummaryItem(
                    title: "Rep targets for \(goal.rawValue)",
                    detail: emphasis.detail,
                    status: emphasis.met ? .met : .needsAttention
                )
            )
        }

        if !rpeValues.isEmpty {
            let outOfRange = rpeValues.filter { $0 < 5 || $0 > 10 }
            let status: ProgramRuleSummaryItem.Status = outOfRange.isEmpty ? .met : .needsAttention
            let detail: String

            if let min = rpeValues.min(), let max = rpeValues.max() {
                if outOfRange.isEmpty {
                    detail = String(format: "Intensity sits between RPE 5–10 (range: %.1f–%.1f).", min, max)
                } else {
                    detail = String(format: "Keep sets in the RPE 5–10 band (current range: %.1f–%.1f).", min, max)
                }
            } else {
                detail = "Maintain effort within the RPE 5–10 guideline."
            }

            summary.append(
                ProgramRuleSummaryItem(
                    title: "Effort (RPE 5–10 emphasis)",
                    detail: detail,
                    status: status
                )
            )
        }

        return summary
    }

    private func calculateWeeklyVolume(
        schedule: [ScheduledSession],
        exerciseLookup: [String: Exercise]
    ) -> [MuscleGroup: Double] {
        var totals: [MuscleGroup: Double] = [:]

        for session in schedule {
            for exercise in session.exercises {
                guard let catalogExercise = exerciseLookup[exercise.exerciseId] else { continue }

                totals[catalogExercise.primaryMuscle, default: 0] += Double(exercise.targetSets)

                for impact in catalogExercise.secondaryMuscles {
                    totals[impact.muscle, default: 0] += Double(exercise.targetSets) * impact.factor
                }
            }
        }

        for muscle in MuscleGroup.allCases {
            totals[muscle, default: 0] += 0
        }

        return totals
    }

    private func calculateWeeklyFrequency(
        schedule: [ScheduledSession],
        exerciseLookup: [String: Exercise]
    ) -> [MuscleGroup: Int] {
        var daysPerMuscle: [MuscleGroup: Set<Int>] = [:]

        for session in schedule {
            for exercise in session.exercises {
                guard let catalogExercise = exerciseLookup[exercise.exerciseId] else { continue }

                daysPerMuscle[catalogExercise.primaryMuscle, default: []].insert(session.dayOfWeek)
                for impact in catalogExercise.secondaryMuscles {
                    daysPerMuscle[impact.muscle, default: []].insert(session.dayOfWeek)
                }
            }
        }

        for muscle in MuscleGroup.allCases {
            daysPerMuscle[muscle, default: []].formUnion([])
        }

        return daysPerMuscle.mapValues { $0.count }
    }

    private func calculateRepDistribution(
        schedule: [ScheduledSession],
        exerciseLookup: [String: Exercise]
    ) -> (heavy: Int, moderate: Int, high: Int, totalSets: Int, heavyShare: Double, moderateShare: Double) {
        var heavy = 0
        var moderate = 0
        var high = 0

        for session in schedule {
            for exercise in session.exercises {
                guard exerciseLookup[exercise.exerciseId] != nil else { continue }

                if exercise.targetReps <= 6 {
                    heavy += exercise.targetSets
                } else if exercise.targetReps <= 12 {
                    moderate += exercise.targetSets
                } else {
                    high += exercise.targetSets
                }
            }
        }

        let total = heavy + moderate + high
        let heavyShare = total > 0 ? Double(heavy) / Double(total) : 0
        let moderateShare = total > 0 ? Double(moderate) / Double(total) : 0

        return (heavy, moderate, high, total, heavyShare, moderateShare)
    }
}

private extension MuscleGroup {
    var readableName: String {
        rawValue.replacingOccurrences(of: "_", with: " ")
    }
}
