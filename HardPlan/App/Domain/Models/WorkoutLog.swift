//
//  WorkoutLog.swift
//  HardPlan
//
//  Placeholder created for Phase 1 directory setup.
//  Implementation will be expanded in Step 1.2.

import Foundation

struct Tempo: Codable, Equatable {
    var eccentric: Int = 0
}

struct CompletedSet: Codable, Equatable {
    var load: Double = 0
}

struct CompletedExercise: Codable, Equatable {
    var exerciseId: String = ""
}

struct WorkoutLog: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var exercises: [CompletedExercise] = []
}
