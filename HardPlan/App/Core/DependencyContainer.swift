//
//  DependencyContainer.swift
//  HardPlan
//
//  Provides lightweight dependency registration and resolution for services
//  and repositories. Defaults to registering concrete implementations but
//  allows overrides for tests and previews.

import Foundation

final class DependencyContainer {
    static let shared = DependencyContainer()

    private var registry: [ObjectIdentifier: () -> Any] = [:]
    private let lock = NSRecursiveLock()

    init(registerDefaults: Bool = true) {
        if registerDefaults {
            registerDefaultDependencies()
        }
    }

    nonisolated func resolve<Service>() -> Service {
        let key = ObjectIdentifier(Service.self)

        lock.lock()
        defer { lock.unlock() }

        guard let factory = registry[key], let service = factory() as? Service else {
            fatalError("No dependency registered for \(Service.self)")
        }

        return service
    }

    nonisolated func register<Service>(_ factory: @escaping () -> Service) {
        let key = ObjectIdentifier(Service.self)

        lock.lock()
        registry[key] = factory
        lock.unlock()
    }

    nonisolated func register<Service>(_ instance: Service) {
        register { instance }
    }

    nonisolated func registerSingleton<Service>(_ factory: @escaping () -> Service) {
        let key = ObjectIdentifier(Service.self)
        var cachedInstance: Service?

        register {
            if let cachedInstance {
                return cachedInstance
            }

            let instance = factory()
            cachedInstance = instance
            return instance
        }
    }

    nonisolated func reset() {
        lock.lock()
        registry.removeAll()
        lock.unlock()
    }

    private func registerDefaultDependencies() {
        registerSingleton { JSONPersistenceController() }

        registerSingleton { ExerciseRepository(persistenceController: self.resolve()) as ExerciseRepositoryProtocol }
        registerSingleton { UserRepository(persistenceController: self.resolve()) as UserRepositoryProtocol }
        registerSingleton { WorkoutRepository(persistenceController: self.resolve()) as WorkoutRepositoryProtocol }

        registerSingleton { VolumeService(exerciseRepository: self.resolve()) as VolumeServiceProtocol }
        registerSingleton { ProgressionService() as ProgressionServiceProtocol }
        registerSingleton { AdherenceService(exerciseRepository: self.resolve()) as AdherenceServiceProtocol }
        registerSingleton { SubstitutionService() as SubstitutionServiceProtocol }
        registerSingleton { AnalyticsService() as AnalyticsServiceProtocol }
        registerSingleton { ProgramGenerator(exerciseRepository: self.resolve()) as ProgramGeneratorProtocol }
        registerSingleton { ExportService() as ExportServiceProtocol }
    }
}
