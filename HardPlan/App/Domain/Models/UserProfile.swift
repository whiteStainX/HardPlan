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

    /// Preferred first day of the week. Follows the Gregorian weekday index (1 = Sunday).
    var firstDayOfWeek: Int = Calendar.current.firstWeekday

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
        firstDayOfWeek: Int = Calendar.current.firstWeekday,
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
        self.firstDayOfWeek = firstDayOfWeek
        self.progressionOverrides = progressionOverrides
        self.fundamentalsStatus = fundamentalsStatus
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, trainingAge, goal, availableDays, weakPoints, excludedExercises
        case unit, minPlateIncrement, onboardingCompleted, firstDayOfWeek, progressionOverrides, fundamentalsStatus
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        name = try container.decode(String.self, forKey: .name)
        trainingAge = try container.decode(TrainingAge.self, forKey: .trainingAge)
        goal = try container.decode(Goal.self, forKey: .goal)
        availableDays = try container.decodeIfPresent([Int].self, forKey: .availableDays) ?? []
        weakPoints = try container.decodeIfPresent([MuscleGroup].self, forKey: .weakPoints) ?? []
        excludedExercises = try container.decodeIfPresent([String].self, forKey: .excludedExercises) ?? []
        unit = try container.decodeIfPresent(UnitSystem.self, forKey: .unit) ?? .lbs
        minPlateIncrement = try container.decodeIfPresent(Double.self, forKey: .minPlateIncrement) ?? 2.5
        onboardingCompleted = try container.decodeIfPresent(Bool.self, forKey: .onboardingCompleted) ?? false
        firstDayOfWeek = try container.decodeIfPresent(Int.self, forKey: .firstDayOfWeek) ?? Calendar.current.firstWeekday
        progressionOverrides = try container.decodeIfPresent([String: ProgressionOverride].self, forKey: .progressionOverrides) ?? [:]
        fundamentalsStatus = try container.decodeIfPresent(FundamentalsStatus.self, forKey: .fundamentalsStatus)
    }
}
