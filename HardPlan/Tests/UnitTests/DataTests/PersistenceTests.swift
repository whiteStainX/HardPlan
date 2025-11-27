//
//  PersistenceTests.swift
//  HardPlanTests
//
//  Created during Phase 1.6 to validate JSON persistence utilities.

import XCTest
@testable import HardPlan

final class PersistenceTests: XCTestCase {
    private var temporaryDirectory: URL!
    private var persistenceController: JSONPersistenceController!

    override func setUpWithError() throws {
        temporaryDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        persistenceController = JSONPersistenceController(directory: temporaryDirectory)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: temporaryDirectory)
        temporaryDirectory = nil
        persistenceController = nil
    }

    func testSaveAndLoadCodableObject() {
        struct Sample: Codable, Equatable { let value: String }

        let sample = Sample(value: "persisted")
        persistenceController.save(sample, to: "sample.json")

        let loaded: Sample? = persistenceController.load(from: "sample.json")
        XCTAssertEqual(loaded, sample)
    }

    func testDeleteRemovesStoredFile() {
        struct Sample: Codable { let value: String }

        let filename = "delete_me.json"
        let fileURL = temporaryDirectory.appendingPathComponent(filename)
        persistenceController.save(Sample(value: "to delete"), to: filename)
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))

        persistenceController.delete(filename: filename)
        XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path))
        let loaded: Sample? = persistenceController.load(from: filename)
        XCTAssertNil(loaded)
    }
}
