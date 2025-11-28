# Phase 2: The Engine (Service Layer)

**Goal:** Implement the Logic "Brain" completely decoupled from the UI.
**Output:** A suite of Service classes and a robust Unit Test suite verifying algorithm correctness.
**Dependencies:** Phase 1 (Domain Models).

---

## Step 2.1: Volume Service (The Regulator)

**Action:** Implement the "Overlap Rule" for calculating weekly volume.

*   **File:** `App/Services/Volume/VolumeService.swift`
*   **Protocol:** `VolumeServiceProtocol`
    *   `calculateWeeklyVolume(logs: [WorkoutLog]) -> [MuscleGroup: Double]`
*   **Logic:**
    *   Iterate through all `CompletedSet`s in the logs.
    *   Fetch the `Exercise` definition for each set.
    *   Add `1.0` set to the `primaryMuscle`.
    *   Add `factor` (0.5) to each `secondaryMuscle`.
    *   Return the aggregated dictionary.
*   **Tests:** `HardPlanTests/UnitTests/ServiceTests/VolumeServiceTests.swift`
    *   Create mock logs (e.g., 3 sets of Squats).
    *   Assert: Quads = 3.0, Glutes = 3.0, Adductors = 1.5.

---

## Step 2.2: Progression Service (The Core Engine)

**Action:** Implement the Strategy Pattern for determining next session's targets.

### 2.2.1 Strategies
*   **File:** `App/Services/Progression/Strategies/ProgressionStrategy.swift` (Protocol)
    *   `func calculateNext(current: ProgressionState, log: WorkoutLog, exercise: Exercise) -> ProgressionState`
*   **File:** `.../NoviceStrategy.swift`
    *   Implement Single Progression (Pass -> Increase, Fail -> Retry/Reset).
    *   Implement "Long Hiatus" reset logic (>14 days).
*   **File:** `.../IntermediateStrategy.swift`
    *   Implement Wave Loading (8 -> 7 -> 6 reps).
    *   Implement Block Transitions (Deload checks).
*   **File:** `.../DoubleProgressionStrategy.swift`
    *   Implement Accessory logic (Hit top range -> Increase Load & Drop Reps).

### 2.2.2 The Service Wrapper
*   **File:** `App/Services/Progression/ProgressionService.swift`
*   **Logic:**
    *   Acts as a factory/router.
    *   Based on `UserProfile.trainingAge` or `progressionOverrides`, select the correct Strategy.
    *   Call `strategy.calculateNext(...)`.
    *   Return the updated `ProgressionState`.

*   **Tests:** `HardPlanTests/UnitTests/ServiceTests/ProgressionTests/`
    *   `NoviceTests.swift`: Test Success (+5lbs), Fail (Retry), Stall (Reset).
    *   `IntermediateTests.swift`: Test Wave progression (Week 1->2->3).

---

## Step 2.3: Adherence Service (The Calendar)

**Action:** Handle missed workouts and schedule adjustments.

*   **File:** `App/Services/Adherence/AdherenceService.swift`
*   **Protocol:** `AdherenceServiceProtocol`
    *   `checkScheduleStatus(lastLogDate: Date, currentDate: Date) -> AdherenceStatus`
    *   `shiftSchedule(program: ActiveProgram) -> ActiveProgram`
    *   `combineSessions(missed: ScheduledSession, current: ScheduledSession) -> ScheduledSession`
*   **Logic:**
    *   **Shift:** Increment `program.startDate` or shift `weeklySchedule` indices.
    *   **Combine:** Merge exercises. Apply logic: Keep Compounds, cap Accessories (Total Sets < 25).
*   **Tests:**
    *   Test that shifting pushes the schedule without losing data.
    *   Test that combining correctly reduces accessory volume.

---

## Step 2.4: Substitution Service (Level 4)

**Action:** Smart filtering of exercises.

*   **File:** `App/Services/Substitution/SubstitutionService.swift`
*   **Protocol:** `SubstitutionServiceProtocol`
    *   `getOptions(for original: Exercise, allExercises: [Exercise], user: UserProfile) -> [SubstitutionOption]`
*   **Logic:**
    *   Filter `allExercises` by:
        *   `MovementPattern` match (Must match).
        *   `Equipment` availability (Optional check).
        *   `UserProfile.excludedExercises` (Remove blocked).
    *   Calculate `SpecificityScore` (0.0 - 1.0).
    *   Add Warnings (e.g., if swapping Competition Lift for Machine).
*   **Tests:**
    *   Test that Squat cannot be swapped for Bench Press.
    *   Test that swapping Barbell Squat -> Leg Press triggers a "Low Specificity" warning for Strength users.

---

## Step 2.5: Analytics Service (The Observer)

**Action:** Compute derived metrics for charts.

*   **File:** `App/Services/Analytics/AnalyticsService.swift`
*   **Logic:**
    *   `calculateE1RM(load: Double, reps: Int) -> Double` (Epley Formula).
    *   `generateHistory(logs: [WorkoutLog], exerciseId: String) -> [E1RMPoint]`.
    *   `analyzeTempo(logs: [WorkoutLog]) -> TempoWarning?`.

---

## Step 2.6: Dependency Container

**Action:** Setup Dependency Injection.

*   **File:** `App/Core/DependencyContainer.swift`
*   **Logic:**
    *   Register all services (`VolumeService`, `ProgressionService`, etc.) as singletons or factories.
    *   Allow swapping for Mocks in Tests/Previews.
