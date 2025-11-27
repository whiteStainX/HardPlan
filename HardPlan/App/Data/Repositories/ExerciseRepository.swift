//
//  ExerciseRepository.swift
//  HardPlan
//
//  Provides access to built-in and user-created exercises.

import Foundation

protocol ExerciseRepositoryProtocol {
    func getAllExercises() -> [Exercise]
    func saveUserExercise(_ exercise: Exercise)
}

struct ExerciseRepository: ExerciseRepositoryProtocol {
    private let persistenceController: JSONPersistenceController
    private let bundle: Bundle
    private let userExercisesFilename = "user_exercises.json"
    private let builtInResourceName = "exercise_db"

    init(
        persistenceController: JSONPersistenceController = JSONPersistenceController(),
        bundle: Bundle = .main
    ) {
        self.persistenceController = persistenceController
        self.bundle = bundle
    }

    func getAllExercises() -> [Exercise] {
        let builtInExercises = loadBuiltInExercises()
        let userExercises: [Exercise] = persistenceController.load(from: userExercisesFilename) ?? []
        return builtInExercises + userExercises
    }

    func saveUserExercise(_ exercise: Exercise) {
        var storedExercises: [Exercise] = persistenceController.load(from: userExercisesFilename) ?? []
        storedExercises.append(exercise)
        persistenceController.save(storedExercises, to: userExercisesFilename)
    }

    private func loadBuiltInExercises() -> [Exercise] {
        guard let url = bundle.url(forResource: builtInResourceName, withExtension: "json") else {
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([Exercise].self, from: data)
        } catch {
            print("ExerciseRepository built-in load error: \(error)")
            return []
        }
    }
}
