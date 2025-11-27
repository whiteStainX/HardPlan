//
//  UserRepository.swift
//  HardPlan
//
//  Implements user profile persistence using JSONPersistenceController.

import Foundation

protocol UserRepositoryProtocol {
    func saveProfile(_ profile: UserProfile)
    func getProfile() -> UserProfile?
}

struct UserRepository: UserRepositoryProtocol {
    private let persistenceController: JSONPersistenceController
    private let filename = "user.json"

    init(persistenceController: JSONPersistenceController = JSONPersistenceController()) {
        self.persistenceController = persistenceController
    }

    func saveProfile(_ profile: UserProfile) {
        persistenceController.save(profile, to: filename)
    }

    func getProfile() -> UserProfile? {
        persistenceController.load(from: filename)
    }
}
