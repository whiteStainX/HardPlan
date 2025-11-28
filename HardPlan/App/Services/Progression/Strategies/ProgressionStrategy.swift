//
//  ProgressionStrategy.swift
//  HardPlan
//
//  Defines the core interface for calculating next-session targets.

import Foundation

protocol ProgressionStrategy {
    func calculateNext(current: ProgressionState, log: WorkoutLog, exercise: Exercise) -> ProgressionState
}
