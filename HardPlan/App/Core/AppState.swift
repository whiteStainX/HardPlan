//
//  AppState.swift
//  HardPlan
//
//  Central store holding live application data. Hydrates from repositories
//  and exposes actions for onboarding and debugging resets.

import Combine
import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published var userProfile: UserProfile?
    @Published var activeProgram: ActiveProgram?
    @Published var workoutLogs: [WorkoutLog]

    private let userRepository: UserRepositoryProtocol
    private let workoutRepository: WorkoutRepositoryProtocol
    private let persistenceController: JSONPersistenceController
    private let programGenerator: ProgramGeneratorProtocol

    private let activeProgramFilename = "active_program.json"

    init(
        userRepository: UserRepositoryProtocol = DependencyContainer.shared.resolve(),
        workoutRepository: WorkoutRepositoryProtocol = DependencyContainer.shared.resolve(),
        persistenceController: JSONPersistenceController = DependencyContainer.shared.resolve(),
        programGenerator: ProgramGeneratorProtocol = DependencyContainer.shared.resolve()
    ) {
        self.userRepository = userRepository
        self.workoutRepository = workoutRepository
        self.persistenceController = persistenceController
        self.programGenerator = programGenerator
        self.workoutLogs = []
    }

    func loadData() {
        userProfile = userRepository.getProfile()
        activeProgram = loadActiveProgram()
        workoutLogs = workoutRepository.getHistory()
    }

    func onboardUser(profile: UserProfile) {
        var storedProfile = profile
        storedProfile.onboardingCompleted = true

        userRepository.saveProfile(storedProfile)
        userProfile = storedProfile

        if activeProgram == nil {
            activeProgram = programGenerator.generateProgram(for: storedProfile)
            persistActiveProgram()
        }
    }

    func resetApp() {
        userRepository.deleteProfile()
        workoutRepository.deleteAll()
        persistenceController.delete(filename: activeProgramFilename)

        userProfile = nil
        activeProgram = nil
        workoutLogs = []
    }

    func appendWorkoutLog(_ log: WorkoutLog) {
        workoutLogs.append(log)
        workoutRepository.saveLog(log)
    }

    func persistActiveProgram() {
        guard let activeProgram else { return }
        persistenceController.save(activeProgram, to: activeProgramFilename)
    }

    private func loadActiveProgram() -> ActiveProgram? {
        persistenceController.load(from: activeProgramFilename)
    }
}
