import Foundation

struct ProgramValidationIssue: Identifiable, Equatable {
    enum Severity {
        case warning
        case error
    }

    let id = UUID()
    let message: String
    let affectedDays: [Int]
    let severity: Severity
}

struct ProgramCorrection: Identifiable {
    let id = UUID()
    let description: String
    let apply: (ActiveProgram) -> ActiveProgram
}

struct ProgramValidationResult {
    let issues: [ProgramValidationIssue]

    var blockingIssues: [ProgramValidationIssue] {
        issues.filter { $0.severity == .error }
    }
}

protocol ProgramValidationServiceProtocol {
    func validate(program: ActiveProgram) -> ProgramValidationResult
    func suggestedCorrections(for program: ActiveProgram) -> [ProgramCorrection]
}

final class ProgramValidationService: ProgramValidationServiceProtocol {
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func validate(program: ActiveProgram) -> ProgramValidationResult {
        let schedule = program.weeklySchedule
        var issues: [ProgramValidationIssue] = []

        let groupedByDay = Dictionary(grouping: schedule, by: \.dayOfWeek)
        let duplicateDays = groupedByDay.filter { $0.value.count > 1 }.keys.sorted()
        if !duplicateDays.isEmpty {
            issues.append(
                ProgramValidationIssue(
                    message: "Multiple sessions assigned to the same day: " + duplicateDays.map(dayLabel).joined(separator: ", "),
                    affectedDays: duplicateDays,
                    severity: .error
                )
            )
        }

        let sessionCount = schedule.count
        if sessionCount < 2 {
            issues.append(
                ProgramValidationIssue(
                    message: "Only \(sessionCount) training day\(sessionCount == 1 ? "" : "s"). Aim for at least 2 per week for progress.",
                    affectedDays: Array(1...7),
                    severity: .warning
                )
            )
        }

        if sessionCount > 6 {
            issues.append(
                ProgramValidationIssue(
                    message: "\(sessionCount) training days detected. Consider scheduling at least one full rest day.",
                    affectedDays: Array(1...7),
                    severity: .warning
                )
            )
        }

        let overloadedDays = schedule.filter { $0.exercises.count > 8 }.map(\.dayOfWeek)
        if !overloadedDays.isEmpty {
            issues.append(
                ProgramValidationIssue(
                    message: "Some days have more than 8 exercises; consider splitting or trimming volume.",
                    affectedDays: overloadedDays,
                    severity: .warning
                )
            )
        }

        let missingDays = Set(1...7).subtracting(groupedByDay.keys).sorted()
        if missingDays.count >= 3 {
            issues.append(
                ProgramValidationIssue(
                    message: "Several days are unscheduled (" + missingDays.map(dayLabel).joined(separator: ", ") + "). Ensure weekly balance.",
                    affectedDays: missingDays,
                    severity: .warning
                )
            )
        }

        return ProgramValidationResult(issues: issues)
    }

    func suggestedCorrections(for program: ActiveProgram) -> [ProgramCorrection] {
        let schedule = program.weeklySchedule
        let existingDays = Set(schedule.map(\.dayOfWeek))
        let openDays = Array(Set(1...7).subtracting(existingDays)).sorted()

        var corrections: [ProgramCorrection] = []

        if let duplicateDay = mostCommonDay(in: schedule), let newDay = openDays.first {
            corrections.append(
                ProgramCorrection(
                    description: "Move one session from \(dayLabel(duplicateDay)) to \(dayLabel(newDay)) to avoid duplicates.",
                    apply: { program in
                        guard var movingSession = schedule.first(where: { $0.dayOfWeek == duplicateDay }) else { return program }
                        var updated = program
                        movingSession.dayOfWeek = newDay
                        if let index = updated.weeklySchedule.firstIndex(where: { $0.id == movingSession.id }) {
                            updated.weeklySchedule[index] = movingSession
                        }
                        return updated
                    }
                )
            )
        }

        if openDays.count >= 2, let heavyDay = schedule.max(by: { $0.exercises.count < $1.exercises.count }) {
            corrections.append(
                ProgramCorrection(
                    description: "Split \(heavyDay.name) across an open rest day to reduce overload.",
                    apply: { program in
                        guard let firstOpen = openDays.first, let idx = program.weeklySchedule.firstIndex(of: heavyDay) else {
                            return program
                        }
                        var updated = program
                        var original = heavyDay
                        let splitExercises = original.exercises.suffix(original.exercises.count / 2)
                        original.exercises.removeLast(splitExercises.count)
                        var newSession = ScheduledSession(dayOfWeek: firstOpen, name: "Balanced Session", exercises: Array(splitExercises))
                        if newSession.name.isEmpty { newSession.name = heavyDay.name }
                        updated.weeklySchedule[idx] = original
                        updated.weeklySchedule.append(newSession)
                        return updated
                    }
                )
            )
        }

        return corrections
    }

    private func dayLabel(_ weekday: Int) -> String {
        let symbols = calendar.weekdaySymbols
        guard weekday >= 1, weekday <= symbols.count else { return "Day \(weekday)" }
        return symbols[weekday - 1]
    }

    private func mostCommonDay(in schedule: [ScheduledSession]) -> Int? {
        let counts = Dictionary(grouping: schedule, by: \.dayOfWeek).mapValues { $0.count }
        return counts.max(by: { $0.value < $1.value })?.key
    }
}
