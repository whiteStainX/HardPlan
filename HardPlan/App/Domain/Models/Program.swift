//
//  Program.swift
//  HardPlan
//
//  Implemented during Phase 1.2 to match DATA_SCHEMA specifications.

import Foundation

struct ProgressionState: Identifiable, Codable, Equatable {
    var id: String { exerciseId }
    var exerciseId: String

    var currentLoad: Double
    var consecutiveFails: Int
    var resetCount: Int
    var recentRPEs: [Double]

    var baseLoad: Double
    var currentRepTarget: Int

    init(
        exerciseId: String,
        currentLoad: Double = 0,
        consecutiveFails: Int = 0,
        resetCount: Int = 0,
        recentRPEs: [Double] = [],
        baseLoad: Double = 0,
        currentRepTarget: Int = 0
    ) {
        self.exerciseId = exerciseId
        self.currentLoad = currentLoad
        self.consecutiveFails = consecutiveFails
        self.resetCount = resetCount
        self.recentRPEs = recentRPEs
        self.baseLoad = baseLoad
        self.currentRepTarget = currentRepTarget
    }
}

struct ScheduledExercise: Identifiable, Codable, Equatable, Hashable {
    var id: UUID = UUID()
    var exerciseId: String
    var order: Int

    var targetSets: Int
    var targetReps: Int
    var targetLoad: Double
    var targetRPE: Double
    var targetTempoOverride: Tempo?

    var note: String
    var isWeakPointPriority: Bool

    init(
        id: UUID = UUID(),
        exerciseId: String,
        order: Int,
        targetSets: Int,
        targetReps: Int,
        targetLoad: Double,
        targetRPE: Double,
        targetTempoOverride: Tempo? = nil,
        note: String = "",
        isWeakPointPriority: Bool = false
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.order = order
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.targetLoad = targetLoad
        self.targetRPE = targetRPE
        self.targetTempoOverride = targetTempoOverride
        self.note = note
        self.isWeakPointPriority = isWeakPointPriority
    }
}

struct ScheduledSession: Identifiable, Codable, Equatable, Hashable {
    var id: UUID = UUID()
    var dayOfWeek: Int
    var name: String
    var exercises: [ScheduledExercise]

    init(id: UUID = UUID(), dayOfWeek: Int, name: String, exercises: [ScheduledExercise] = []) {
        self.id = id
        self.dayOfWeek = dayOfWeek
        self.name = name
        self.exercises = exercises
    }
}

struct ActiveProgram: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    var startDate: String

    var currentBlockPhase: BlockPhase
    var currentWeek: Int
    var consecutiveBlocksWithoutDeload: Int

    var weeklySchedule: [ScheduledSession]
    var progressionData: [String: ProgressionState]

    init(
        id: String = UUID().uuidString,
        startDate: String,
        currentBlockPhase: BlockPhase,
        currentWeek: Int = 1,
        consecutiveBlocksWithoutDeload: Int = 0,
        weeklySchedule: [ScheduledSession] = [],
        progressionData: [String: ProgressionState] = [:]
    ) {
        self.id = id
        self.startDate = startDate
        self.currentBlockPhase = currentBlockPhase
        self.currentWeek = currentWeek
        self.consecutiveBlocksWithoutDeload = consecutiveBlocksWithoutDeload
        self.weeklySchedule = weeklySchedule
        self.progressionData = progressionData
    }
}
