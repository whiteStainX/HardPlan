//
//  AddExerciseFormTests.swift
//  HardPlanTests
//
//  Verifies the logic of the NewExerciseForm helper struct.

import XCTest
@testable import HardPlan

// Note: To test this file, the `NewExerciseForm` struct in `ExerciseListView.swift`
// must be made `internal`, not `private`.

final class AddExerciseFormTests: XCTestCase {

    func testIsValid_withEmptyName_isFalse() {
        // GIVEN
        var sut = NewExerciseForm()
        
        // WHEN
        sut.name = "   " // Whitespace only
        
        // THEN
        XCTAssertFalse(sut.isValid, "Form should be invalid if the name is only whitespace.")
    }

    func testIsValid_withValidName_isTrue() {
        // GIVEN
        var sut = NewExerciseForm()
        
        // WHEN
        sut.name = "Valid Exercise"
        
        // THEN
        XCTAssertTrue(sut.isValid)
    }

    func testAsExercise_withValidForm_createsCorrectExercise() {
        // GIVEN
        let sut = NewExerciseForm(
            name: "  Cable Crossover  ",
            muscleGroup: .chest,
            type: .isolation,
            equipment: .cable
        )
        
        // WHEN
        let exercise = sut.asExercise()
        
        // THEN
        XCTAssertNotNil(exercise)
        XCTAssertEqual(exercise?.name, "Cable Crossover") // Should be trimmed
        XCTAssertEqual(exercise?.primaryMuscle, .chest)
        XCTAssertEqual(exercise?.type, .isolation)
        XCTAssertEqual(exercise?.equipment, .cable)
        XCTAssertTrue(exercise?.isUserCreated ?? false)
        XCTAssertEqual(exercise?.tier, .tier3, "User-created exercises should default to Tier 3")
    }

    func testAsExercise_withInvalidName_returnsNil() {
        // GIVEN
        let sut = NewExerciseForm(name: " ")
        
        // WHEN
        let exercise = sut.asExercise()
        
        // THEN
        XCTAssertNil(exercise)
    }
}
