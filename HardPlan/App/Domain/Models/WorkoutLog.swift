//
//  WorkoutLog.swift
//  HardPlan
//
//  Implemented during Phase 1.2 to match DATA_SCHEMA specifications.

import Foundation

struct Tempo: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var eccentric: Int
    var pause: Int
    var concentric: Int
    var topPause: Int?

    init(id: UUID = UUID(), eccentric: Int, pause: Int, concentric: Int, topPause: Int? = nil) {
        self.id = id
        self.eccentric = eccentric
        self.pause = pause
        self.concentric = concentric
        self.topPause = topPause
    }
}

enum SetTag: String, Codable {
    case warmup = "Warmup"
    case aps = "APS"
    case dropSet = "DropSet"
    case restPause = "RestPause"
}

struct CompletedSet: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var setNumber: Int

    var targetLoad: Double
    var targetReps: Int

    var load: Double
    var reps: Int
    var rpe: Double
    var tags: [SetTag]
    var actualTempo: Tempo?

    init(
        id: UUID = UUID(),
        setNumber: Int,
        targetLoad: Double,
        targetReps: Int,
        load: Double,
        reps: Int,
        rpe: Double,
        tags: [SetTag] = [],
        actualTempo: Tempo? = nil
    ) {
        self.id = id
        self.setNumber = setNumber
        self.targetLoad = targetLoad
        self.targetReps = targetReps
        self.load = load
        self.reps = reps
        self.rpe = rpe
        self.tags = tags
        self.actualTempo = actualTempo
    }
}

struct CompletedExercise: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var exerciseId: String
    var sets: [CompletedSet]
    var wasSwapped: Bool
    var originalExerciseId: String?

    init(
        id: UUID = UUID(),
        exerciseId: String,
        sets: [CompletedSet] = [],
        wasSwapped: Bool = false,
        originalExerciseId: String? = nil
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.sets = sets
        self.wasSwapped = wasSwapped
        self.originalExerciseId = originalExerciseId
    }
}

enum WorkoutStatus: String, Codable {
    case completed = "Completed"
    case skipped = "Skipped"
    case combined = "Combined"
}

enum WorkoutMode: String, Codable {
    case normal
    case shortOnTime
}

struct WorkoutLog: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    var programId: String

    var dateScheduled: String
    var dateCompleted: String
    var durationMinutes: Int

    var status: WorkoutStatus
    var mode: WorkoutMode
    var notes: String

    var exercises: [CompletedExercise]

    var sessionRPE: Double
    var wellnessScore: Int
    var checklistScore: Int?

    init(
        id: String = UUID().uuidString,
        programId: String,
        dateScheduled: String,
        dateCompleted: String,
        durationMinutes: Int,
        status: WorkoutStatus,
        mode: WorkoutMode,
        notes: String = "",
        exercises: [CompletedExercise] = [],
        sessionRPE: Double,
        wellnessScore: Int,
        checklistScore: Int? = nil
    ) {
        self.id = id
        self.programId = programId
        self.dateScheduled = dateScheduled
        self.dateCompleted = dateCompleted
        self.durationMinutes = durationMinutes
        self.status = status
        self.mode = mode
        self.notes = notes
        self.exercises = exercises
        self.sessionRPE = sessionRPE
        self.wellnessScore = wellnessScore
        self.checklistScore = checklistScore
    }
}
