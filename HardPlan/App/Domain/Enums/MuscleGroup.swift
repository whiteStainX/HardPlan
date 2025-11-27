//
//  MuscleGroup.swift
//  HardPlan
//
//  Generated during Phase 1.2 to match DATA_SCHEMA specifications.

import Foundation

enum MuscleGroup: String, Codable, CaseIterable {
    case quads = "Quads"
    case hamstrings = "Hamstrings"
    case glutes = "Glutes"
    case calves = "Calves"
    case chest = "Chest"
    case backLats = "Back_Lats"
    case backTraps = "Back_Traps"
    case backLower = "Back_Lower"
    case deltsFront = "Delts_Front"
    case deltsSide = "Delts_Side"
    case deltsRear = "Delts_Rear"
    case biceps = "Biceps"
    case triceps = "Triceps"
    case abs = "Abs"
}
