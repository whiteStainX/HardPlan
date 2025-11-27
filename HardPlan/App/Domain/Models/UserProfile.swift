//
//  UserProfile.swift
//  HardPlan
//
//  Implemented during Phase 1.2 to match DATA_SCHEMA specifications.

import Foundation

struct FundamentalsStatus: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var averageSleepHours: Double?
    var proteinIntakeQuality: ProteinIntakeQuality?
    var stressLevel: StressLevel?
    var notes: String?
}

enum ProteinIntakeQuality: String, Codable {
    case poor
    case ok
    case good
}

enum StressLevel: String, Codable {
    case low
    case moderate
    case high
}

enum UnitSystem: String, Codable {
    case lbs
    case kg
}

enum ProgressionOverride: String, Codable {
    case novice = "Novice"
    case intermediate = "Intermediate"
    case doubleProgression = "DoubleProgression"
}

struct UserProfile: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    var name: String

    var trainingAge: TrainingAge
    var goal: Goal
    var availableDays: [Int]

    var weakPoints: [MuscleGroup]
    var excludedExercises: [String]

    var unit: UnitSystem
    var minPlateIncrement: Double
    var onboardingCompleted: Bool

    var progressionOverrides: [String: ProgressionOverride]
    var fundamentalsStatus: FundamentalsStatus?

    init(
        id: String = UUID().uuidString,
        name: String,
        trainingAge: TrainingAge,
        goal: Goal,
        availableDays: [Int] = [],
        weakPoints: [MuscleGroup] = [],
        excludedExercises: [String] = [],
        unit: UnitSystem = .lbs,
        minPlateIncrement: Double = 2.5,
        onboardingCompleted: Bool = false,
        progressionOverrides: [String: ProgressionOverride] = [:],
        fundamentalsStatus: FundamentalsStatus? = nil
    ) {
        self.id = id
        self.name = name
        self.trainingAge = trainingAge
        self.goal = goal
        self.availableDays = availableDays
        self.weakPoints = weakPoints
        self.excludedExercises = excludedExercises
        self.unit = unit
        self.minPlateIncrement = minPlateIncrement
        self.onboardingCompleted = onboardingCompleted
        self.progressionOverrides = progressionOverrides
        self.fundamentalsStatus = fundamentalsStatus
    }
}
