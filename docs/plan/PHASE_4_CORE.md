# Phase 4: The Core Loop (Execution & Logging)

**Goal:** Enable the daily training experience.
**Output:** Fully functional Dashboard and Workout Logging screens.
**Dependencies:** Phase 3 (Skeleton).

---

## Step 4.1: Dashboard (The Hub)

**Action:** Visualize Adherence and Volume.

*   **File:** `App/UI/Dashboard/DashboardView.swift`
*   **ViewModel:** `DashboardViewModel`
    *   Reads `AppState.activeProgram` and `workoutLogs`.
    *   Computes `weeklyAdherence` (e.g., 3/4 sessions).
    *   Computes `volumeStatus` (using `VolumeService`).
*   **Components:**
    *   `AdherenceRingView`: Circular progress bar.
    *   `VolumeEquatorView`: Bar chart (Swift Charts) showing Sets vs Target (10-20).
    *   `NextSessionCard`: Shows "Today's Workout" with a "Start" button.

---

## Step 4.2: Workout Session (The Logger)

**Action:** The complex screen for executing a workout.

*   **File:** `App/UI/Workout/WorkoutSessionView.swift`
*   **ViewModel:** `WorkoutSessionViewModel`
    *   Init with `ScheduledSession`.
    *   Manages `localWorkoutLog` (in-progress data).
    *   Handles "APS Toggle" -> calls `AdherenceService.trimSession(...)`.
*   **Sub-Views:**
    *   `ExercisePageView`: Paged tab view for focusing on one lift at a time? Or a Scrolling List? **Decision: Scrolling List** (easier to overview).
    *   `SetRowView`:
        *   Inputs: `Load` (TextField), `Reps` (TextField), `RPE` (Picker/Slider).
        *   Validation: "Complete" button disabled until valid.
        *   Logic: Auto-fills `Target` values from `ScheduledSet`.
    *   `RestTimerView`: Floating bottom bar or inline section.
        *   Auto-starts on Set Completion.

---

## Step 4.3: Smart Logic Integration

**Action:** Connect UI actions to Phase 2 Services.

*   **Substitution:**
    *   Add "Swap" button to `ExerciseHeader`.
    *   Present `SubstitutionSheet`.
    *   On selection: Update `WorkoutSessionViewModel.currentExercises`.
*   **Auto-Regulation:**
    *   On "Complete Set", call `AutoRegulationService` (if we separated it) or check Logic.
    *   If `RPE` mismatch > 1, show optional Toast: "Load reduced for next set".
*   **Short on Time (APS):**
    *   Toggle Button in Toolbar.
    *   Action: Filter `displayedExercises` using `AdherenceService`.

---

## Step 4.4: Post-Workout Flow

**Action:** Saving and Progressing.

*   **File:** `App/UI/Workout/WorkoutSummaryView.swift`
*   **Logic:**
    *   Displayed after "Finish Workout".
    *   Show Summary: Duration, Volume, Records broken.
    *   **Save Action:**
        *   Call `AppState.completeWorkout(log)`.
        *   Triggers `ProgressionService.calculateNextTarget(...)`.
        *   Updates `ActiveProgram` schedule for next week.

---

## Step 4.5: Validation

**Action:** Full Integration Test.

*   **Scenario:**
    1.  Tap "Start Workout" on Dashboard.
    2.  Log Squat: 3 sets x 5 reps @ 225lbs, RPE 8.
    3.  Log Bench: Swap to Dumbbell Press -> Log.
    4.  Finish.
    5.  Check Dashboard: Adherence Ring updates.
    6.  Check Program: Next Squat session shows increased weight (+5lbs) due to Novice Logic success.
