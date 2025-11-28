//
//  Exercise.swift
//  HardPlan
//
//  Implemented during Phase 1.2 to match DATA_SCHEMA specifications.

import Foundation

enum MovementPattern: String, Codable, CaseIterable {
    case squat = "Squat"
    case hinge = "Hinge"
    case lunge = "Lunge"
    case pushHorizontal = "Push_Horizontal"
    case pushVertical = "Push_Vertical"
    case pullHorizontal = "Pull_Horizontal"
    case pullVertical = "Pull_Vertical"
    case isolation = "Isolation"
}

enum ExerciseType: String, Codable, CaseIterable {
    case compound = "Compound"
    case isolation = "Isolation"
    case machine = "Machine"
}

enum EquipmentType: String, Codable, CaseIterable {
    case barbell = "Barbell"
    case dumbbell = "Dumbbell"
    case machine = "Machine"
    case cable = "Cable"
    case bodyweight = "Bodyweight"
}

enum ExerciseTier: String, Codable {
    case tier1 = "Tier1"
    case tier2 = "Tier2"
    case tier3 = "Tier3"
}

struct MuscleImpact: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var muscle: MuscleGroup
    var factor: Double
}

struct Exercise: Identifiable, Codable, Equatable {
    var id: String
    var name: String

    var pattern: MovementPattern
    var type: ExerciseType
    var equipment: EquipmentType

    var primaryMuscle: MuscleGroup
    var secondaryMuscles: [MuscleImpact]

    var defaultTempo: String

    var tier: ExerciseTier
    var isCompetitionLift: Bool
    var isUserCreated: Bool

    init(
        id: String = UUID().uuidString,
        name: String,
        pattern: MovementPattern,
        type: ExerciseType,
        equipment: EquipmentType,
        primaryMuscle: MuscleGroup,
        secondaryMuscles: [MuscleImpact] = [],
        defaultTempo: String = "",
        tier: ExerciseTier = .tier2,
        isCompetitionLift: Bool = false,
        isUserCreated: Bool = false
    ) {
        self.id = id
        self.name = name
        self.pattern = pattern
        self.type = type
        self.equipment = equipment
        self.primaryMuscle = primaryMuscle
        self.secondaryMuscles = secondaryMuscles
        self.defaultTempo = defaultTempo
        self.tier = tier
        self.isCompetitionLift = isCompetitionLift
        self.isUserCreated = isUserCreated
    }
}
