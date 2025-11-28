//
//  Substitution.swift
//  HardPlan
//
//  Defines substitution DTOs for exercise swapping logic.

import Foundation

struct SubstitutionWarning: Identifiable, Codable, Equatable {
    enum Level: String, Codable {
        case info
        case warning
    }

    var id: UUID = UUID()
    let level: Level
    let message: String

    init(id: UUID = UUID(), level: Level, message: String) {
        self.id = id
        self.level = level
        self.message = message
    }
}

struct SubstitutionOption: Identifiable, Codable, Equatable {
    let id: String
    let exerciseName: String
    let specificityScore: Double
    let warning: SubstitutionWarning?
}
