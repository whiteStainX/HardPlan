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
}

struct ProgressionService: ProgressionServiceProtocol {
    private let defaultRepRange: ClosedRange<Int>
    private let dateProvider: () -> Date

    init(defaultRepRange: ClosedRange<Int> = 8...12, dateProvider: @escaping () -> Date = Date.init) {
        self.defaultRepRange = defaultRepRange
        self.dateProvider = dateProvider
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
}
