//
//  ProgramGeneratorTests.swift
//  HardPlanTests
//
//  Verifies the logic of the program generation service.

import XCTest
@testable import HardPlan

final class ProgramGeneratorTests: XCTestCase {

    private func createMockRepository() -> ExerciseRepositoryProtocol {
        let exercises = [
            // Tier 1
            Exercise(id: "squat", name: "Squat", pattern: .squat, type: .compound, equipment: .barbell, primaryMuscle: .quads, tier: .tier1),
            Exercise(id: "bench", name: "Bench", pattern: .pushHorizontal, type: .compound, equipment: .barbell, primaryMuscle: .chest, tier: .tier1),
            Exercise(id: "deadlift", name: "Deadlift", pattern: .hinge, type: .compound, equipment: .barbell, primaryMuscle: .hamstrings, tier: .tier1),
            // Tier 2
            Exercise(id: "pullup", name: "Pull-up", pattern: .pullVertical, type: .compound, equipment: .bodyweight, primaryMuscle: .backLats, tier: .tier2),
            Exercise(id: "ohp", name: "Overhead Press", pattern: .pushVertical, type: .compound, equipment: .barbell, primaryMuscle: .deltsFront, tier: .tier2),
            // Tier 3
            Exercise(id: "latraise", name: "Lateral Raise", pattern: .isolation, type: .isolation, equipment: .dumbbell, primaryMuscle: .deltsSide, tier: .tier3),
            Exercise(id: "bicepcurl", name: "Bicep Curl", pattern: .isolation, type: .isolation, equipment: .dumbbell, primaryMuscle: .biceps, tier: .tier3)
        ]
        return MockProgramGenExerciseRepository(exercises: exercises)
    }

    func testGeneratesThreeDayFullBodySplitForNovice() {
        // GIVEN
        let user = UserProfile(name: "Test Novice", trainingAge: .novice, goal: .hypertrophy, availableDays: [1, 3, 5])
        let generator = ProgramGenerator(exerciseRepository: createMockRepository())

        // WHEN
        let program = generator.generateProgram(for: user)

        // THEN
        XCTAssertEqual(program.weeklySchedule.count, 3)
        XCTAssertTrue(program.weeklySchedule.contains(where: { $0.name.contains("Full Body") }))

        // Verify total sets for a primary muscle (Chest) is around the novice target (10)
        let chestExercises = program.weeklySchedule.flatMap { $0.exercises }.filter { $0.exerciseId == "bench" }
        let totalChestSets = chestExercises.reduce(0) { $0 + $1.targetSets }
        XCTAssertEqual(Double(totalChestSets), 10.0, accuracy: 2.0)
    }

    func testGeneratesFourDayUpperLowerSplit() {
        // GIVEN
        let user = UserProfile(name: "Test Intermediate", trainingAge: .intermediate, goal: .strength, availableDays: [1, 2, 4, 5])
        let generator = ProgramGenerator(exerciseRepository: createMockRepository())

        // WHEN
        let program = generator.generateProgram(for: user)

        // THEN
        XCTAssertEqual(program.weeklySchedule.count, 4)
        XCTAssertTrue(program.weeklySchedule.contains(where: { $0.name.contains("Upper") }))
        XCTAssertTrue(program.weeklySchedule.contains(where: { $0.name.contains("Lower") }))
    }

    func testPrioritizesWeakPointsInAccessoryList() {
        // GIVEN
        var user = UserProfile(name: "Test Weak Points", trainingAge: .intermediate, goal: .hypertrophy, availableDays: [1, 2, 4, 5])
        user.weakPoints = [.biceps]
        
        let generator = ProgramGenerator(exerciseRepository: createMockRepository())

        // WHEN
        let program = generator.generateProgram(for: user)

        // THEN
        guard let upperSession = program.weeklySchedule.first(where: { $0.name.contains("Upper") }) else {
            XCTFail("Could not find an Upper body session to test weak point prioritization.")
            return
        }

        // Find the index of the bicep curl and another accessory
        guard let bicepIndex = upperSession.exercises.firstIndex(where: { $0.exerciseId == "bicepcurl" }) else {
            XCTFail("Bicep curl not found in upper body session.")
            return
        }

        guard let lateralRaiseIndex = upperSession.exercises.firstIndex(where: { $0.exerciseId == "latraise" }) else {
            XCTFail("Lateral raise not found in upper body session.")
            return
        }
        
        // Assert that the weak point (bicep) exercise appears before the other accessory
        XCTAssertLessThan(bicepIndex, lateralRaiseIndex)
    }
}

private final class MockProgramGenExerciseRepository: ExerciseRepositoryProtocol {
    private let exercises: [Exercise]

    init(exercises: [Exercise]) {
        self.exercises = exercises
    }

    func getAllExercises() -> [Exercise] {
        return exercises
    }

    func saveUserExercise(_ exercise: Exercise) {
        // No-op
    }
}
