//
//  WorkoutRepository.swift
//  HardPlan
//
//  Placeholder created for Phase 1 directory setup.
//  Implementation will be added in Step 1.4.

import Foundation

protocol WorkoutRepositoryProtocol {
    func saveLog(_ log: WorkoutLog)
    func getHistory() -> [WorkoutLog]
    func overwriteHistory(_ logs: [WorkoutLog])
    func deleteAll()
}

struct WorkoutRepository: WorkoutRepositoryProtocol {
    private let persistenceController: JSONPersistenceController
    private let filename = "workout_logs.json"

    init(persistenceController: JSONPersistenceController = JSONPersistenceController()) {
        self.persistenceController = persistenceController
    }

    func saveLog(_ log: WorkoutLog) {
        var history = getHistory()
        history.append(log)
        persistenceController.save(history, to: filename)
    }

    func getHistory() -> [WorkoutLog] {
        persistenceController.load(from: filename) ?? []
    }

    func overwriteHistory(_ logs: [WorkoutLog]) {
        persistenceController.save(logs, to: filename)
    }

    func deleteAll() {
        persistenceController.delete(filename: filename)
    }
}
