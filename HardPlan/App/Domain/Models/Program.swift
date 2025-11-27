//
//  Program.swift
//  HardPlan
//
//  Placeholder created for Phase 1 directory setup.
//  Implementation will be expanded in Step 1.2.

import Foundation

struct ProgressionState: Codable, Equatable {
    var exerciseId: String = ""
}

struct ScheduledExercise: Codable, Equatable {
    var exerciseId: String = ""
}

struct ScheduledSession: Codable, Equatable {
    var id: UUID = UUID()
}

struct ActiveProgram: Codable, Equatable {
    var id: UUID = UUID()
}
