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
        workoutLogs: [WorkoutLog]
    ) -> ExportBundle?

    func generateJSON(
        profile: UserProfile?,
        activeProgram: ActiveProgram?,
        workoutLogs: [WorkoutLog]
    ) -> Data?

    func generateCSV(workoutLogs: [WorkoutLog]) -> String
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
}

final class ExportService: ExportServiceProtocol {
    private let encoder: JSONEncoder

    init(encoder: JSONEncoder = JSONEncoder()) {
        self.encoder = encoder
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    func exportBundle(
        profile: UserProfile?,
        activeProgram: ActiveProgram?,
        workoutLogs: [WorkoutLog]
    ) -> ExportBundle? {
        guard let jsonData = generateJSON(profile: profile, activeProgram: activeProgram, workoutLogs: workoutLogs) else {
            return nil
        }

        let csvString = generateCSV(workoutLogs: workoutLogs)
        return ExportBundle(jsonData: jsonData, csvString: csvString)
    }

    func generateJSON(
        profile: UserProfile?,
        activeProgram: ActiveProgram?,
        workoutLogs: [WorkoutLog]
    ) -> Data? {
        let payload = ExportPayload(
            userProfile: profile,
            activeProgram: activeProgram,
            workoutLogs: workoutLogs
        )

        return try? encoder.encode(payload)
    }

    func generateCSV(workoutLogs: [WorkoutLog]) -> String {
        var lines: [String] = [
            "Workout ID,Program ID,Date Completed,Status,Mode,Duration Minutes,Session RPE,Wellness Score,Notes"
        ]

        for log in workoutLogs {
            let fields: [String] = [
                log.id,
                log.programId,
                log.dateCompleted,
                log.status.rawValue,
                log.mode.rawValue,
                String(log.durationMinutes),
                String(log.sessionRPE),
                String(log.wellnessScore),
                log.notes
            ]

            lines.append(fields.map { escapeCSV($0) }.joined(separator: ","))
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
}
