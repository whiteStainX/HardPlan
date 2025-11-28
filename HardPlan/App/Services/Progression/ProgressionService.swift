//
//  ProgressionService.swift
//  HardPlan
//
//  Routes progression calculations through the appropriate strategy.

import Foundation

protocol ProgressionServiceProtocol {
    func calculateNextState(
        current: ProgressionState,
        log: WorkoutLog,
        exercise: Exercise,
        user: UserProfile,
        program: ActiveProgram,
        repRange: ClosedRange<Int>?
    ) -> ProgressionState

    func shouldTriggerPostBlockAssessment(program: ActiveProgram, logs: [WorkoutLog]) -> Bool
}

struct ProgressionService: ProgressionServiceProtocol {
    private let defaultRepRange: ClosedRange<Int>
    private let dateProvider: () -> Date
    private let isoFormatter: ISO8601DateFormatter
    private let dateOnlyFormatter: ISO8601DateFormatter

    init(defaultRepRange: ClosedRange<Int> = 8...12, dateProvider: @escaping () -> Date = Date.init) {
        self.defaultRepRange = defaultRepRange
        self.dateProvider = dateProvider

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        self.isoFormatter = isoFormatter

        let dateOnlyFormatter = ISO8601DateFormatter()
        dateOnlyFormatter.formatOptions = [.withFullDate]
        self.dateOnlyFormatter = dateOnlyFormatter
    }

    func calculateNextState(
        current: ProgressionState,
        log: WorkoutLog,
        exercise: Exercise,
        user: UserProfile,
        program: ActiveProgram,
        repRange: ClosedRange<Int>? = nil
    ) -> ProgressionState {
        let strategy = selectStrategy(for: exercise, user: user, program: program, repRange: repRange)
        return strategy.calculateNext(current: current, log: log, exercise: exercise)
    }

    func shouldTriggerPostBlockAssessment(program: ActiveProgram, logs: [WorkoutLog]) -> Bool {
        guard let startDate = parseDate(program.startDate) else { return false }
        guard let latestLogDate = logs.compactMap({ parseDate($0.dateCompleted) }).max() else { return false }

        let calendar = Calendar(identifier: .gregorian)
        let weekDelta = calendar.dateComponents([.weekOfYear], from: startDate, to: latestLogDate).weekOfYear ?? 0
        let completedWeeks = max(program.currentWeek, weekDelta + 1)

        return completedWeeks >= 4 && program.currentBlockPhase != .deload
    }

    private func selectStrategy(
        for exercise: Exercise,
        user: UserProfile,
        program: ActiveProgram,
        repRange: ClosedRange<Int>?
    ) -> ProgressionStrategy {
        if let override = user.progressionOverrides[exercise.id] {
            return strategy(for: override, exercise: exercise, user: user, program: program, repRange: repRange)
        }

        if exercise.type == .isolation {
            return DoubleProgressionStrategy(
                repRange: repRange ?? defaultRepRange,
                minPlateIncrement: user.minPlateIncrement
            )
        }

        switch user.trainingAge {
        case .novice:
            return NoviceStrategy(minPlateIncrement: user.minPlateIncrement, dateProvider: dateProvider)
        case .intermediate, .advanced:
            return IntermediateStrategy(
                goal: user.goal,
                currentWeek: program.currentWeek,
                minPlateIncrement: user.minPlateIncrement,
                consecutiveBlocksWithoutDeload: program.consecutiveBlocksWithoutDeload
            )
        }
    }

    private func strategy(
        for override: ProgressionOverride,
        exercise: Exercise,
        user: UserProfile,
        program: ActiveProgram,
        repRange: ClosedRange<Int>?
    ) -> ProgressionStrategy {
        switch override {
        case .novice:
            return NoviceStrategy(minPlateIncrement: user.minPlateIncrement, dateProvider: dateProvider)
        case .intermediate:
            return IntermediateStrategy(
                goal: user.goal,
                currentWeek: program.currentWeek,
                minPlateIncrement: user.minPlateIncrement,
                consecutiveBlocksWithoutDeload: program.consecutiveBlocksWithoutDeload
            )
        case .doubleProgression:
            return DoubleProgressionStrategy(
                repRange: repRange ?? defaultRepRange,
                minPlateIncrement: user.minPlateIncrement
            )
        }
    }

    private func parseDate(_ string: String) -> Date? {
        if let date = isoFormatter.date(from: string) {
            return date
        }

        return dateOnlyFormatter.date(from: string)
    }
}
