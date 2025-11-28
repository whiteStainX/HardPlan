//
//  ExportService.swift
//  HardPlan
//
//  Provides lightweight data export for user profile, program state,
//  and workout history. Implemented in Phase 3.5 to enable basic
//  data ownership from the Settings screen.

import Foundation

protocol ExportServiceProtocol {
    func exportBundle(
        profile: UserProfile?,
        activeProgram: ActiveProgram?,
        workoutLogs: [WorkoutLog],
        exercises: [Exercise]
    ) -> ExportBundle?

    func generateJSON(
        profile: UserProfile?,
        activeProgram: ActiveProgram?,
        workoutLogs: [WorkoutLog],
        exercises: [Exercise]
    ) -> Data?

    func generateCSV(
        workoutLogs: [WorkoutLog],
        exercises: [Exercise],
        activeProgram: ActiveProgram?
    ) -> String
}

struct ExportBundle {
    let jsonData: Data
    let csvString: String

    var jsonSizeDescription: String {
        ByteCountFormatter.string(fromByteCount: Int64(jsonData.count), countStyle: .file)
    }

    var csvRowCount: Int {
        let rows = csvString.split(whereSeparator: \.isNewline)
        return max(rows.count - 1, 0) // subtract header
    }
}

private struct ExportPayload: Codable {
    let userProfile: UserProfile?
    let activeProgram: ActiveProgram?
    let workoutLogs: [WorkoutLog]
    let exercises: [Exercise]
}

final class ExportService: ExportServiceProtocol {
    private let encoder: JSONEncoder
    private let numberFormatter: NumberFormatter

    init(encoder: JSONEncoder = JSONEncoder()) {
        self.encoder = encoder
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.locale = Locale(identifier: "en_US_POSIX")
        self.numberFormatter = formatter
    }

    func exportBundle(
        profile: UserProfile?,
        activeProgram: ActiveProgram?,
        workoutLogs: [WorkoutLog],
        exercises: [Exercise]
    ) -> ExportBundle? {
        guard let jsonData = generateJSON(
            profile: profile,
            activeProgram: activeProgram,
            workoutLogs: workoutLogs,
            exercises: exercises
        ) else {
            return nil
        }

        let csvString = generateCSV(
            workoutLogs: workoutLogs,
            exercises: exercises,
            activeProgram: activeProgram
        )
        return ExportBundle(jsonData: jsonData, csvString: csvString)
    }

    func generateJSON(
        profile: UserProfile?,
        activeProgram: ActiveProgram?,
        workoutLogs: [WorkoutLog],
        exercises: [Exercise]
    ) -> Data? {
        let payload = ExportPayload(
            userProfile: profile,
            activeProgram: activeProgram,
            workoutLogs: workoutLogs,
            exercises: exercises
        )

        return try? encoder.encode(payload)
    }

    func generateCSV(
        workoutLogs: [WorkoutLog],
        exercises: [Exercise],
        activeProgram: ActiveProgram?
    ) -> String {
        let exerciseLookup = Dictionary(uniqueKeysWithValues: exercises.map { ($0.id, $0) })
        var lines: [String] = [
            [
                "Date Completed",
                "Date Scheduled",
                "Workout ID",
                "Program ID",
                "Block Phase",
                "Block Week",
                "Mode",
                "Status",
                "Exercise ID",
                "Exercise Name",
                "Primary Muscle",
                "Set Number",
                "Target Reps",
                "Target Load",
                "Actual Reps",
                "Actual Load",
                "RPE",
                "Tags",
                "Was Swapped",
                "Original Exercise ID",
                "Session RPE",
                "Wellness Score",
                "Checklist Score",
                "Workout Notes"
            ].joined(separator: ",")
        ]

        for log in workoutLogs {
            if log.exercises.isEmpty {
                lines.append(summaryRow(for: log, activeProgram: activeProgram))
                continue
            }

            for exerciseLog in log.exercises {
                let exercise = exerciseLookup[exerciseLog.exerciseId]
                let primaryMuscle = exercise?.primaryMuscle.rawValue ?? ""
                let exerciseName = exercise?.name ?? "Unknown Exercise"

                if exerciseLog.sets.isEmpty {
                    var fields: [String] = baseFields(log: log, activeProgram: activeProgram)
                    fields.append(contentsOf: [
                        exerciseLog.exerciseId,
                        exerciseName,
                        primaryMuscle,
                        "", "", "", "", "", "", // Empty set details
                        exerciseLog.wasSwapped ? "true" : "false",
                        exerciseLog.originalExerciseId ?? "",
                        numberFormatter.string(from: NSNumber(value: log.sessionRPE)) ?? "",
                        String(log.wellnessScore),
                        log.checklistScore.map(String.init) ?? "",
                        log.notes
                    ])
                    lines.append(fields.map { escapeCSV($0) }.joined(separator: ","))
                    continue
                }

                for set in exerciseLog.sets {
                    var fields: [String] = baseFields(log: log, activeProgram: activeProgram)
                    fields.append(contentsOf: [
                        exerciseLog.exerciseId,
                        exerciseName,
                        primaryMuscle,
                        String(set.setNumber),
                        String(set.targetReps),
                        formattedNumber(set.targetLoad),
                        String(set.reps),
                        formattedNumber(set.load),
                        formattedNumber(set.rpe),
                        set.tags.map { $0.rawValue }.joined(separator: ";"),
                        exerciseLog.wasSwapped ? "true" : "false",
                        exerciseLog.originalExerciseId ?? "",
                        numberFormatter.string(from: NSNumber(value: log.sessionRPE)) ?? "",
                        String(log.wellnessScore),
                        log.checklistScore.map(String.init) ?? "",
                        log.notes
                    ])
                    lines.append(fields.map { escapeCSV($0) }.joined(separator: ","))
                }
            }
        }

        return lines.joined(separator: "\n")
    }

    private func escapeCSV(_ value: String) -> String {
        guard value.contains(",") || value.contains("\n") || value.contains("\"") else {
            return value
        }

        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }

    private func formattedNumber(_ value: Double) -> String {
        numberFormatter.string(from: NSNumber(value: value)) ?? String(value)
    }

    private func baseFields(log: WorkoutLog, activeProgram: ActiveProgram?) -> [String] {
        [
            log.dateCompleted,
            log.dateScheduled,
            log.id,
            log.programId,
            activeProgram?.currentBlockPhase.rawValue ?? "",
            activeProgram.map { String($0.currentWeek) } ?? "",
            log.mode.rawValue,
            log.status.rawValue
        ]
    }

    private func summaryRow(for log: WorkoutLog, activeProgram: ActiveProgram?) -> String {
        var fields: [String] = baseFields(log: log, activeProgram: activeProgram)
        fields.append(contentsOf: Array(repeating: "", count: 12))
        fields.append(contentsOf: [
            numberFormatter.string(from: NSNumber(value: log.sessionRPE)) ?? "",
            String(log.wellnessScore),
            log.checklistScore.map(String.init) ?? "",
            log.notes
        ])

        return fields.map { escapeCSV($0) }.joined(separator: ",")
    }
}
