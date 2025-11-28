//
//  AdherenceService.swift
//  HardPlan
//
//  Handles schedule adherence, shifting, and session combinations.

import Foundation

protocol AdherenceServiceProtocol {
    func checkScheduleStatus(lastLogDate: Date, currentDate: Date) -> AdherenceStatus
    func shiftSchedule(program: ActiveProgram) -> ActiveProgram
    func combineSessions(missed: ScheduledSession, current: ScheduledSession) -> ScheduledSession
    func trimSession(for session: ScheduledSession) -> ScheduledSession
}

struct AdherenceService: AdherenceServiceProtocol {
    private let exerciseRepository: ExerciseRepositoryProtocol
    private let calendar: Calendar
    private let dateFormatter: DateFormatter
    private let gapThresholdDays = 4
    private let accessorySetCap = 25

    init(
        exerciseRepository: ExerciseRepositoryProtocol = ExerciseRepository(),
        calendar: Calendar = .current
    ) {
        self.exerciseRepository = exerciseRepository
        self.calendar = calendar

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        self.dateFormatter = formatter
    }

    func checkScheduleStatus(lastLogDate: Date, currentDate: Date) -> AdherenceStatus {
        let daysSinceLast = daysBetween(lastLogDate, and: currentDate)
        if daysSinceLast > gapThresholdDays {
            return .returningFromBreak(daysSinceLastLog: daysSinceLast, loadModifier: 0.9)
        }

        return .onTrack
    }

    func shiftSchedule(program: ActiveProgram) -> ActiveProgram {
        var shiftedProgram = program

        if let startDate = dateFormatter.date(from: program.startDate),
           let updatedDate = calendar.date(byAdding: .day, value: 1, to: startDate) {
            shiftedProgram.startDate = dateFormatter.string(from: updatedDate)
        }

        shiftedProgram.weeklySchedule = shiftSessions(program.weeklySchedule)
        return shiftedProgram
    }

    func combineSessions(missed: ScheduledSession, current: ScheduledSession) -> ScheduledSession {
        let exerciseLookup = Dictionary(uniqueKeysWithValues: exerciseRepository.getAllExercises().map { ($0.id, $0) })
        let combinedList = current.exercises + missed.exercises

        let primaryExercises = combinedList.filter { isPrimary($0, lookup: exerciseLookup) }
        let accessoryExercises = combinedList.filter { !isPrimary($0, lookup: exerciseLookup) }

        var combinedExercises: [ScheduledExercise] = []
        var totalSets = 0

        for exercise in primaryExercises {
            var updatedExercise = exercise
            updatedExercise.order = combinedExercises.count + 1
            combinedExercises.append(updatedExercise)
            totalSets += updatedExercise.targetSets
        }

        for accessory in accessoryExercises {
            var reducedAccessory = accessory
            reducedAccessory.targetSets = max(1, accessory.targetSets - 1)

            if totalSets + reducedAccessory.targetSets >= accessorySetCap {
                continue
            }

            reducedAccessory.order = combinedExercises.count + 1
            combinedExercises.append(reducedAccessory)
            totalSets += reducedAccessory.targetSets
        }

        return ScheduledSession(
            dayOfWeek: current.dayOfWeek,
            name: "Combined: \(missed.name) + \(current.name)",
            exercises: combinedExercises
        )
    }

    func trimSession(for session: ScheduledSession) -> ScheduledSession {
        let exerciseLookup = Dictionary(uniqueKeysWithValues: exerciseRepository.getAllExercises().map { ($0.id, $0) })

        var trimmed: [ScheduledExercise] = []
        var accessoryCount = 0

        for exercise in session.exercises.sorted(by: { $0.order < $1.order }) {
            guard let details = exerciseLookup[exercise.exerciseId] else { continue }

            if details.isCompetitionLift || details.type == .compound {
                trimmed.append(exercise)
                continue
            }

            guard accessoryCount < 2 else { continue }

            var reducedAccessory = exercise
            reducedAccessory.targetSets = max(1, exercise.targetSets - 1)
            accessoryCount += 1
            trimmed.append(reducedAccessory)
        }

        for index in trimmed.indices {
            trimmed[index].order = index + 1
        }

        return ScheduledSession(
            id: session.id,
            dayOfWeek: session.dayOfWeek,
            name: "\(session.name) (APS)",
            exercises: trimmed
        )
    }

    private func shiftSessions(_ sessions: [ScheduledSession]) -> [ScheduledSession] {
        let shifted = sessions.map { session -> ScheduledSession in
            var updated = session
            updated.dayOfWeek = ((session.dayOfWeek % 7) + 1)
            return updated
        }

        return shifted.sorted { $0.dayOfWeek < $1.dayOfWeek }
    }

    private func isPrimary(_ scheduledExercise: ScheduledExercise, lookup: [String: Exercise]) -> Bool {
        guard let exercise = lookup[scheduledExercise.exerciseId] else {
            return false
        }

        return exercise.isCompetitionLift || exercise.type == .compound
    }

    private func daysBetween(_ start: Date, and end: Date) -> Int {
        let startDay = calendar.startOfDay(for: start)
        let endDay = calendar.startOfDay(for: end)
        return calendar.dateComponents([.day], from: startDay, to: endDay).day ?? 0
    }
}
