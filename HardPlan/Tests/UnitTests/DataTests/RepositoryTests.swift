//
//  RepositoryTests.swift
//  HardPlanTests
//
//  Created during Phase 1.6 to validate repository behavior.

import XCTest
@testable import HardPlan

final class RepositoryTests: XCTestCase {
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

    func testSaveAndLoadUserProfile() throws {
        let repository = UserRepository(persistenceController: persistenceController)
        let profile = UserProfile(
            id: "user-123",
            name: "Test User",
            trainingAge: .novice,
            goal: .strength,
            availableDays: [1, 3, 5],
            weakPoints: [.quads, .backLats],
            excludedExercises: ["bench_press_barbell"],
            unit: .kg,
            minPlateIncrement: 1.25,
            onboardingCompleted: true,
            progressionOverrides: ["squat_back_barbell": .novice],
            fundamentalsStatus: FundamentalsStatus(
                averageSleepHours: 7.5,
                proteinIntakeQuality: .good,
                stressLevel: .moderate,
                notes: "Consistent"
            )
        )

        repository.saveProfile(profile)
        let loadedProfile = repository.getProfile()

        XCTAssertEqual(loadedProfile, profile)
    }

    func testExerciseRepositoryMergesSources() throws {
        let builtInBundle = try createTemporaryBundleWithBuiltInExercises()
        let repository = ExerciseRepository(
            persistenceController: persistenceController,
            bundle: builtInBundle
        )

        let userExercise = Exercise(
            id: "user_created_row",
            name: "Chest Supported Row",
            pattern: .pullHorizontal,
            type: .machine,
            equipment: .machine,
            primaryMuscle: .backLats,
            secondaryMuscles: [
                MuscleImpact(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, muscle: .backTraps, factor: 0.5)
            ],
            defaultTempo: "2-1-1-0",
            tier: .tier2,
            isCompetitionLift: false,
            isUserCreated: true
        )

        repository.saveUserExercise(userExercise)

        let allExercises = repository.getAllExercises()
        XCTAssertEqual(allExercises.count, 2)
        XCTAssertTrue(allExercises.contains(where: { $0.id == "squat_back_barbell" }))
        XCTAssertTrue(allExercises.contains(where: { $0.id == userExercise.id && $0.isUserCreated }))
    }

    private func createTemporaryBundleWithBuiltInExercises() throws -> Bundle {
        let bundleURL = temporaryDirectory.appendingPathComponent("bundle")
        try FileManager.default.createDirectory(at: bundleURL, withIntermediateDirectories: true)

        let plistURL = bundleURL.appendingPathComponent("Info.plist")
        let plistContents = """
        <?xml version=\"1.0\" encoding=\"UTF-8\"?>
        <!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
        <plist version=\"1.0\">
        <dict>
            <key>CFBundleIdentifier</key>
            <string>com.hardplan.tests</string>
        </dict>
        </plist>
        """
        try plistContents.write(to: plistURL, atomically: true, encoding: .utf8)

        let exerciseJSONURL = bundleURL.appendingPathComponent("exercise_db.json")
        let exerciseJSON = """
        [
          {
            "id": "squat_back_barbell",
            "name": "Barbell Back Squat",
            "pattern": "Squat",
            "type": "Compound",
            "equipment": "Barbell",
            "primaryMuscle": "Quads",
            "secondaryMuscles": [
              { "id": "11111111-1111-1111-1111-111111111111", "muscle": "Glutes", "factor": 0.8 }
            ],
            "defaultTempo": "3-0-1-0",
            "tier": "Tier1",
            "isCompetitionLift": true,
            "isUserCreated": false
          }
        ]
        """
        try exerciseJSON.write(to: exerciseJSONURL, atomically: true, encoding: .utf8)

        guard let bundle = Bundle(url: bundleURL) else {
            throw XCTSkip("Failed to create temporary bundle for testing")
        }

        return bundle
    }
}
