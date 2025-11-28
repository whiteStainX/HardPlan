//
//  SubstitutionServiceTests.swift
//  HardPlanTests
//
//  Validates substitution filtering and warning behavior.

import XCTest
@testable import HardPlan

final class SubstitutionServiceTests: XCTestCase {
    private let service = SubstitutionService()

    func testFiltersByMovementPattern() {
        let squat = Exercise(
            id: "squat",
            name: "Barbell Squat",
            pattern: .squat,
            type: .compound,
            equipment: .barbell,
            primaryMuscle: .quads,
            defaultTempo: "3-1-1",
            tier: .tier1,
            isCompetitionLift: true
        )

        let bench = Exercise(
            id: "bench",
            name: "Bench Press",
            pattern: .pushHorizontal,
            type: .compound,
            equipment: .barbell,
            primaryMuscle: .chest,
            defaultTempo: "2-1-1",
            tier: .tier1,
            isCompetitionLift: true
        )

        let user = UserProfile(name: "Tester", trainingAge: .novice, goal: .strength)

        let options = service.getOptions(for: squat, allExercises: [squat, bench], user: user)

        XCTAssertTrue(options.isEmpty, "Exercises with different movement patterns should be filtered out")
    }

    func testCompetitionLiftSwapAddsWarningForStrength() {
        let squat = Exercise(
            id: "squat",
            name: "Barbell Squat",
            pattern: .squat,
            type: .compound,
            equipment: .barbell,
            primaryMuscle: .quads,
            defaultTempo: "3-1-1",
            tier: .tier1,
            isCompetitionLift: true
        )

        let legPress = Exercise(
            id: "legpress",
            name: "Leg Press",
            pattern: .squat,
            type: .machine,
            equipment: .machine,
            primaryMuscle: .quads,
            defaultTempo: "2-1-1",
            tier: .tier2,
            isCompetitionLift: false
        )

        let user = UserProfile(name: "Tester", trainingAge: .novice, goal: .strength)

        let options = service.getOptions(for: squat, allExercises: [squat, legPress], user: user)

        XCTAssertEqual(options.count, 1)

        let option = options[0]
        XCTAssertEqual(option.id, legPress.id)
        XCTAssertEqual(option.exerciseName, legPress.name)
        XCTAssertEqual(option.specificityScore, 0.25)
        XCTAssertEqual(
            option.warning?.message,
            "You are replacing a competition lift with a non-competition variant. This may reduce specificity for strength. Are you sure?"
        )
        XCTAssertEqual(option.warning?.level, .warning)
    }
}
