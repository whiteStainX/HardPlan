//
//  Exercise.swift
//  HardPlan
//
//  Placeholder created for Phase 1 directory setup.
//  Implementation will be expanded in Step 1.2.

import Foundation

struct MuscleImpact: Codable, Equatable {
    var muscle: MuscleGroup = .placeholder
    var factor: Double = 0
}

struct Exercise: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    var name: String = ""
}
