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
    func updateSnapshots(program: ActiveProgram, logs: [WorkoutLog], goal: GoalSetting?, calendar: Calendar) -> [AnalyticsSnapshot]
}

extension AnalyticsServiceProtocol {
    func updateSnapshots(program: ActiveProgram, logs: [WorkoutLog], goal: GoalSetting? = nil) -> [AnalyticsSnapshot] {
        updateSnapshots(program: program, logs: logs, goal: goal, calendar: Calendar(identifier: .gregorian))
    }
}

struct AnalyticsService: AnalyticsServiceProtocol {
    private let exerciseRepository: ExerciseRepositoryProtocol
    private let isoFormatter: ISO8601DateFormatter
    private let dateOnlyFormatter: ISO8601DateFormatter

    init(exerciseRepository: ExerciseRepositoryProtocol = ExerciseRepository()) {
        self.exerciseRepository = exerciseRepository
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        self.isoFormatter = isoFormatter

        let dateOnlyFormatter = ISO8601DateFormatter()
        dateOnlyFormatter.formatOptions = [.withFullDate]
        self.dateOnlyFormatter = dateOnlyFormatter
    }

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

    func updateSnapshots(program: ActiveProgram, logs: [WorkoutLog], goal: GoalSetting?, calendar: Calendar) -> [AnalyticsSnapshot] {
        let exercisesById = Dictionary(uniqueKeysWithValues: exerciseRepository
            .getAllExercises()
            .map { ($0.id, $0) })

        let tier1ExerciseIds = tier1Lifts(in: program, logs: logs, exercisesById: exercisesById)
        let blockSegments = buildBlockPhaseSegments(program: program, logs: logs)
        let lastUpdated = isoFormatter.string(from: Date())

        return tier1ExerciseIds.map { liftId in
            let e1rmHistory = generateHistory(logs: logs, exerciseId: liftId)
            let rpeBins = buildRPEDistribution(logs: logs, exerciseId: liftId, calendar: calendar)
            let projection = buildE1RMProjection(
                for: liftId,
                history: e1rmHistory,
                goal: goal,
                programStartDate: program.startDate,
                calendar: calendar
            )

            return AnalyticsSnapshot(
                liftId: liftId,
                e1RMHistory: e1rmHistory,
                projectedE1RMHistory: projection.points,
                rpeDistribution: rpeBins,
                blockPhaseSegments: blockSegments,
                projectionSummary: projection.summary,
                lastUpdatedAt: lastUpdated
            )
        }
    }

    // MARK: - Helpers

    private func tier1Lifts(
        in program: ActiveProgram,
        logs: [WorkoutLog],
        exercisesById: [String: Exercise]
    ) -> [String] {
        var tier1Ids: Set<String> = []

        for session in program.weeklySchedule {
            for exercise in session.exercises {
                if exercisesById[exercise.exerciseId]?.tier == .tier1 {
                    tier1Ids.insert(exercise.exerciseId)
                }
            }
        }

        for log in logs {
            for exercise in log.exercises where exercisesById[exercise.exerciseId]?.tier == .tier1 {
                tier1Ids.insert(exercise.exerciseId)
            }
        }

        return tier1Ids.sorted()
    }

    private func buildRPEDistribution(logs: [WorkoutLog], exerciseId: String, calendar: Calendar) -> [RPERangeBin] {
        let buckets: [(label: String, range: Range<Double>)] = [
            ("6-7", 6.0..<7.0),
            ("7-8", 7.0..<8.0),
            ("8-9", 8.0..<9.0),
            ("9-10", 9.0..<10.5)
        ]

        var counts = Array(repeating: 0, count: buckets.count)
        var earliest: Date?
        var latest: Date?

        for log in logs {
            var foundExerciseInLog = false

            for exercise in log.exercises where exercise.exerciseId == exerciseId {
                foundExerciseInLog = true
                for set in exercise.sets where !set.tags.contains(.warmup) {
                    if let index = buckets.firstIndex(where: { $0.range.contains(set.rpe) }) {
                        counts[index] += 1
                    }
                }
            }

            if foundExerciseInLog, let logDate = parseDate(log.dateCompleted) {
                earliest = minDate(earliest, logDate)
                latest = maxDate(latest, logDate)
            }
        }

        let weeksSpanned = computeWeeksSpanned(earliest: earliest, latest: latest, calendar: calendar)

        return zip(buckets, counts).map { bucket, count in
            RPERangeBin(rangeLabel: bucket.label, count: count, periodWeeks: weeksSpanned)
        }
    }

    private func buildBlockPhaseSegments(program: ActiveProgram, logs: [WorkoutLog]) -> [BlockPhaseSegment] {
        guard let startDate = parseDate(program.startDate) else { return [] }
        let latestLogDate = logs.compactMap { parseDate($0.dateCompleted) }.max() ?? Date()

        return [
            BlockPhaseSegment(
                startDate: program.startDate,
                endDate: isoFormatter.string(from: latestLogDate),
                phase: program.currentBlockPhase.rawValue
            )
        ]
    }

    private func computeWeeksSpanned(earliest: Date?, latest: Date?, calendar: Calendar) -> Int {
        guard let start = earliest, let end = latest else { return 0 }
        let days = calendar.dateComponents([.day], from: start, to: end).day ?? 0
        return max(1, Int(ceil(Double(days + 1) / 7.0)))
    }

    private func minDate(_ lhs: Date?, _ rhs: Date) -> Date {
        guard let lhs else { return rhs }
        return min(lhs, rhs)
    }

    private func maxDate(_ lhs: Date?, _ rhs: Date) -> Date {
        guard let lhs else { return rhs }
        return max(lhs, rhs)
    }

    private func buildE1RMProjection(
        for liftId: String,
        history: [E1RMPoint],
        goal: GoalSetting?,
        programStartDate: String,
        calendar: Calendar
    ) -> (points: [E1RMPoint], summary: ProjectionSummary?) {
        guard let goal, goal.liftId == liftId else { return ([], nil) }
        guard let startDate = parseDate(programStartDate) ?? calendar.date(byAdding: .weekOfYear, value: -history.count, to: Date()) else {
            return ([], nil)
        }

        let targetDate = parseDate(goal.targetDate ?? programStartDate) ?? calendar.date(byAdding: .weekOfYear, value: 12, to: startDate) ?? startDate
        let baseline = goal.baselineValue ?? history.last?.e1rm ?? 0
        let weeksToTarget = max(1, calendar.dateComponents([.weekOfYear], from: startDate, to: targetDate).weekOfYear ?? 1)

        let weeklyRate: Double
        if let override = goal.weeklyProgressRate, override > 0 {
            weeklyRate = override
        } else {
            let delta = (goal.targetValue ?? baseline) - baseline
            weeklyRate = delta / Double(weeksToTarget)
        }

        var points: [E1RMPoint] = []
        var cursorDate = startDate
        var current = baseline

        for week in 0...weeksToTarget {
            let date = calendar.date(byAdding: .weekOfYear, value: week, to: startDate) ?? cursorDate
            cursorDate = date
            points.append(E1RMPoint(date: isoFormatter.string(from: date), e1rm: current))
            current = min(goal.targetValue ?? current + weeklyRate, current + weeklyRate)
        }

        let projectedToday = interpolateProjection(points: points, on: Date(), calendar: calendar)
        let latestActual = history.last?.e1rm ?? baseline
        let variance = latestActual - projectedToday

        let summary = ProjectionSummary(
            baseline: baseline,
            projectedToday: projectedToday,
            variance: variance,
            targetDate: goal.targetDate,
            targetValue: goal.targetValue
        )

        return (points, summary)
    }

    private func interpolateProjection(points: [E1RMPoint], on date: Date, calendar: Calendar) -> Double {
        guard let first = points.first, let firstDate = parseDate(first.date) else { return 0 }

        guard let targetIndex = points.firstIndex(where: { point in
            guard let pointDate = parseDate(point.date) else { return false }
            return pointDate >= date
        }) else {
            return points.last?.e1rm ?? 0
        }

        if targetIndex == 0 { return first.e1rm }

        let lowerPoint = points[targetIndex - 1]
        let upperPoint = points[targetIndex]
        guard let lowerDate = parseDate(lowerPoint.date), let upperDate = parseDate(upperPoint.date) else { return upperPoint.e1rm }

        let totalDays = Double(calendar.dateComponents([.day], from: lowerDate, to: upperDate).day ?? 1)
        let elapsed = Double(calendar.dateComponents([.day], from: lowerDate, to: date).day ?? 0)
        if totalDays <= 0 { return upperPoint.e1rm }

        let ratio = max(0, min(1, elapsed / totalDays))
        return lowerPoint.e1rm + (upperPoint.e1rm - lowerPoint.e1rm) * ratio
    }

    private func parseDate(_ string: String) -> Date? {
        if let date = isoFormatter.date(from: string) {
            return date
        }

        return dateOnlyFormatter.date(from: string)
    }
}
