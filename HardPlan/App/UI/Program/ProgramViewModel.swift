import Foundation
import Combine
import SwiftUI

struct ProgramSessionDisplay: Identifiable, Hashable {
    let id: UUID
    let dayOfWeek: Int
    let dayLabel: String
    let sessionName: String
    let exercises: [ProgramExerciseDisplay]
}

struct ProgramExerciseDisplay: Identifiable, Hashable {
    let id: UUID
    let name: String
    let prescription: String
    let note: String?
}

struct ProgramWeekProjection: Identifiable, Hashable {
    let id: UUID = UUID()
    let weekIndex: Int
    let startDate: Date
    let phase: BlockPhase
    let projectedMetric: Double?
}

struct ProgramOverview {
    let weeks: [ProgramWeekProjection]
    let metricLabel: String?
    let goalLiftId: String?
    let targetValue: Double?
}

struct ProgramExerciseDraft: Identifiable, Hashable {
    var id: UUID = UUID()
    var exerciseId: String
    var name: String
    var targetSets: Int
    var targetReps: Int
    var targetLoad: Double
    var targetRPE: Double
    var note: String
    var order: Int

    init(from scheduled: ScheduledExercise, exerciseLookup: [Exercise]) {
        self.id = scheduled.id
        self.exerciseId = scheduled.exerciseId
        self.name = exerciseLookup.first(where: { $0.id == scheduled.exerciseId })?.name ?? "Exercise"
        self.targetSets = scheduled.targetSets
        self.targetReps = scheduled.targetReps
        self.targetLoad = scheduled.targetLoad
        self.targetRPE = scheduled.targetRPE
        self.note = scheduled.note
        self.order = scheduled.order
    }

    init(exercise: Exercise, targetSets: Int = 3, targetReps: Int = 8, targetLoad: Double = 0, targetRPE: Double = 7.5, note: String = "", order: Int = 0) {
        self.exerciseId = exercise.id
        self.name = exercise.name
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.targetLoad = targetLoad
        self.targetRPE = targetRPE
        self.note = note
        self.order = order
    }

    func asScheduledExercise() -> ScheduledExercise {
        ScheduledExercise(
            id: id,
            exerciseId: exerciseId,
            order: order,
            targetSets: targetSets,
            targetReps: targetReps,
            targetLoad: targetLoad,
            targetRPE: targetRPE,
            note: note
        )
    }
}

struct ProgramSessionDraft: Identifiable, Hashable {
    var id: UUID
    var dayOfWeek: Int
    var name: String
    var exercises: [ProgramExerciseDraft]

    init(session: ScheduledSession, exerciseLookup: [Exercise]) {
        self.id = session.id
        self.dayOfWeek = session.dayOfWeek
        self.name = session.name
        self.exercises = session.exercises
            .sorted { $0.order < $1.order }
            .map { ProgramExerciseDraft(from: $0, exerciseLookup: exerciseLookup) }
    }

    init(dayOfWeek: Int, name: String, exercises: [ProgramExerciseDraft]) {
        self.id = UUID()
        self.dayOfWeek = dayOfWeek
        self.name = name
        self.exercises = exercises
    }

    mutating func reorder(from source: IndexSet, to destination: Int) {
        exercises.move(fromOffsets: source, toOffset: destination)
        for index in exercises.indices {
            exercises[index].order = index
        }
    }

    func asScheduledSession() -> ScheduledSession {
        let scheduledExercises = exercises.enumerated().map { index, draft in
            var updated = draft
            updated.order = index
            return updated.asScheduledExercise()
        }

        return ScheduledSession(id: id, dayOfWeek: dayOfWeek, name: name, exercises: scheduledExercises)
    }
}

@MainActor
final class ProgramViewModel: ObservableObject {
    @Published var sessions: [ProgramSessionDisplay] = []
    @Published var validationIssues: [ProgramValidationIssue] = []
    @Published var ruleSummary: [ProgramRuleSummaryItem] = []
    @Published var overview: ProgramOverview?

    let calendar: Calendar
    let exerciseOptions: [Exercise]

    private let exerciseRepository: ExerciseRepositoryProtocol
    private let validationService: ProgramValidationServiceProtocol
    private var activeProgram: ActiveProgram?
    private var user: UserProfile?
    private let isoFormatter: ISO8601DateFormatter
    private let dateOnlyFormatter: ISO8601DateFormatter

    init(
        exerciseRepository: ExerciseRepositoryProtocol = DependencyContainer.shared.resolve(),
        validationService: ProgramValidationServiceProtocol = DependencyContainer.shared.resolve(),
        calendar: Calendar = .current
    ) {
        self.exerciseRepository = exerciseRepository
        self.validationService = validationService
        self.calendar = calendar
        self.exerciseOptions = exerciseRepository.getAllExercises().sorted { $0.name < $1.name }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        self.isoFormatter = formatter
        let dateOnly = ISO8601DateFormatter()
        dateOnly.formatOptions = [.withFullDate]
        self.dateOnlyFormatter = dateOnly
    }

    func refresh(program: ActiveProgram?, user: UserProfile?, analytics: [AnalyticsSnapshot]) {
        activeProgram = program
        self.user = user
        guard let program else {
            sessions = []
            overview = nil
            return
        }

        let exerciseLookup = Dictionary(uniqueKeysWithValues: exerciseRepository
            .getAllExercises()
            .map { ($0.id, $0.name) })

        sessions = program.weeklySchedule
            .sorted { $0.dayOfWeek < $1.dayOfWeek }
            .map { session in
                let exercises = session.exercises
                    .sorted { $0.order < $1.order }
                    .map { scheduled in
                        ProgramExerciseDisplay(
                            id: scheduled.id,
                            name: exerciseLookup[scheduled.exerciseId] ?? "Exercise",
                            prescription: prescription(for: scheduled),
                            note: scheduled.note.isEmpty ? nil : scheduled.note
                        )
                    }

                return ProgramSessionDisplay(
                    id: session.id,
                    dayOfWeek: session.dayOfWeek,
                    dayLabel: dayLabel(for: session.dayOfWeek),
                    sessionName: session.name,
                    exercises: exercises
                )
            }

        overview = buildOverview(program: program, user: user, analytics: analytics)
    }

    func session(for weekday: Int) -> ProgramSessionDisplay? {
        sessions.first { $0.dayOfWeek == weekday }
    }

    func makeDraft(for weekday: Int) -> ProgramSessionDraft {
        guard let program = activeProgram else {
            return ProgramSessionDraft(dayOfWeek: weekday, name: "Session", exercises: [])
        }

        if let existing = program.weeklySchedule.first(where: { $0.dayOfWeek == weekday }) {
            return ProgramSessionDraft(session: existing, exerciseLookup: exerciseOptions)
        }

        return ProgramSessionDraft(dayOfWeek: weekday, name: "New Session", exercises: [])
    }

    func save(draft: ProgramSessionDraft, appState: AppState) -> ProgramValidationResult? {
        guard var program = activeProgram else { return nil }
        var updatedSessions = program.weeklySchedule

        let session = draft.asScheduledSession()
        if let index = updatedSessions.firstIndex(where: { $0.id == session.id }) {
            updatedSessions[index] = session
        } else if let indexForDay = updatedSessions.firstIndex(where: { $0.dayOfWeek == session.dayOfWeek }) {
            updatedSessions[indexForDay] = session
        } else {
            updatedSessions.append(session)
        }

        let result = appState.updateProgramSchedule(updatedSessions)
        refresh(program: appState.activeProgram, user: appState.userProfile, analytics: appState.analyticsSnapshots)
        evaluate(program: appState.activeProgram, user: appState.userProfile)
        return result
    }

    private func buildOverview(program: ActiveProgram, user: UserProfile?, analytics: [AnalyticsSnapshot]) -> ProgramOverview? {
        guard let startDate = parseDate(program.startDate) else { return nil }
        let goal = user?.goalSetting
        let projectionPoints = projectionPoints(for: goal, analytics: analytics)

        let weeks = (0..<8).compactMap { offset -> ProgramWeekProjection? in
            guard let date = calendar.date(byAdding: .weekOfYear, value: offset, to: startDate) else { return nil }
            let projectedValue = projectedValue(on: date, projection: projectionPoints)
            return ProgramWeekProjection(
                weekIndex: program.currentWeek + offset,
                startDate: date,
                phase: phase(for: program, offset: offset),
                projectedMetric: projectedValue
            )
        }

        return ProgramOverview(
            weeks: weeks,
            metricLabel: goal?.metric == .estimated1RM ? "Projected e1RM" : "Projected volume",
            goalLiftId: goal?.liftId,
            targetValue: goal?.metric == .estimated1RM ? goal?.targetValue : nil
        )
    }

    private func phase(for program: ActiveProgram, offset: Int) -> BlockPhase {
        let ordered: [BlockPhase] = [.introductory, .accumulation, .intensification, .realization, .deload]
        guard let currentIndex = ordered.firstIndex(of: program.currentBlockPhase) else { return program.currentBlockPhase }
        let index = (currentIndex + offset) % ordered.count
        return ordered[index]
    }

    private func projectionPoints(for goal: GoalSetting?, analytics: [AnalyticsSnapshot]) -> [E1RMPoint] {
        guard let goal, goal.metric == .estimated1RM else { return [] }
        return analytics.first(where: { $0.liftId == goal.liftId })?.projectedE1RMHistory ?? []
    }

    private func projectedValue(on date: Date, projection: [E1RMPoint]) -> Double? {
        guard !projection.isEmpty else { return nil }
        let sorted = projection.compactMap { point -> (Date, Double)? in
            guard let date = parseDate(point.date) else { return nil }
            return (date, point.e1rm)
        }.sorted { $0.0 < $1.0 }

        guard let first = sorted.first else { return nil }
        if date <= first.0 { return first.1 }
        for index in 0..<(sorted.count - 1) {
            let current = sorted[index]
            let next = sorted[index + 1]
            if date >= current.0 && date <= next.0 {
                let totalDays = Double(calendar.dateComponents([.day], from: current.0, to: next.0).day ?? 1)
                let elapsed = Double(calendar.dateComponents([.day], from: current.0, to: date).day ?? 0)
                let ratio = max(0, min(1, elapsed / totalDays))
                return current.1 + (next.1 - current.1) * ratio
            }
        }

        return sorted.last?.1
    }

    private func parseDate(_ string: String) -> Date? {
        isoFormatter.date(from: string) ?? dateOnlyFormatter.date(from: string)
    }

    func evaluate(program: ActiveProgram?, user: UserProfile?) {
        guard let program else {
            validationIssues = []
            ruleSummary = []
            return
        }

        let result = validationService.validate(program: program, user: user)
        validationIssues = result.issues
        ruleSummary = result.ruleSummary
    }

    func shortDayLabel(for weekday: Int) -> String {
        let symbols = calendar.shortWeekdaySymbols
        if weekday >= 1 && weekday <= symbols.count {
            return symbols[weekday - 1]
        }

        return "Day \(weekday)"
    }

    private func dayLabel(for weekday: Int) -> String {
        let symbols = calendar.weekdaySymbols
        if weekday >= 1 && weekday <= symbols.count {
            return symbols[weekday - 1]
        }

        return "Day \(weekday)"
    }

    private func prescription(for exercise: ScheduledExercise) -> String {
        var parts: [String] = []
        parts.append("\(exercise.targetSets)x\(exercise.targetReps)")

        if exercise.targetRPE > 0 {
            parts.append("RPE \(String(format: "%.1f", exercise.targetRPE))")
        }

        if let loadString = loadLabel(for: exercise.targetLoad) {
            parts.append(loadString)
        }

        if let tempoLabel = tempoLabel(for: exercise.targetTempoOverride) {
            parts.append(tempoLabel)
        }

        return parts.joined(separator: " • ")
    }

    private func loadLabel(for load: Double) -> String? {
        guard load > 0 else { return nil }

        if load.rounded() == load {
            return "\(Int(load)) lb"
        }

        return String(format: "%.1f lb", load)
    }

    private func tempoLabel(for tempo: Tempo?) -> String? {
        guard let tempo else { return nil }
        if let topPause = tempo.topPause {
            return "Tempo \(tempo.eccentric)-\(tempo.pause)-\(tempo.concentric)-\(topPause)"
        }

        return "Tempo \(tempo.eccentric)-\(tempo.pause)-\(tempo.concentric)"
    }
}
