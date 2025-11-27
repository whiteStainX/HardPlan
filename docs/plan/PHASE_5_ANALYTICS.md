# Phase 5: The Feedback Loop (Analytics & Polish)

**Goal:** Provide long-term value and visualization.
**Output:** Analytics screens, Post-Block Assessments, and Data Export.
**Dependencies:** Phase 4 (Core Loop).

---

## Step 5.1: Analytics Service & Snapshots

**Action:** Implement the aggregation logic for charts.

*   **File:** `App/Services/Analytics/AnalyticsService.swift` (Refined)
    *   `updateSnapshots(program: ActiveProgram, logs: [WorkoutLog])`
    *   Computes `e1RMHistory` for Tier 1 lifts.
    *   Computes `rpeDistribution` (Buckets: 6-7, 7-8, 8-9, 9-10).
    *   Caches results in `AppState` or `AnalyticsRepository`.

---

## Step 5.2: Visualizations (Swift Charts)

**Action:** Build the Chart views.

*   **File:** `App/UI/Analytics/Charts/E1RMChart.swift`
    *   Line Chart.
    *   X-Axis: Date. Y-Axis: Load.
    *   Annotations: Vertical lines for `BlockPhase` changes.
*   **File:** `App/UI/Analytics/Charts/RPEHeatmap.swift`
    *   Bar Chart (Histogram).
    *   Color coded (Green = Optimal, Red = Overshooting).

---

## Step 5.3: Post-Block Assessment Flow

**Action:** The "Check-in" between mesocycles.

*   **Trigger:** `ProgressionService` detects end of Block (e.g., Week 4 completed).
*   **UI:** `App/UI/Assessment/PostBlockAssessmentView.swift`
*   **Logic:**
    *   Step 1: Show e1RM Trend (Stalled vs Progressing).
    *   Step 2: Questionnaire (Sleep, Stress, Aches).
    *   Step 3: Decision (Deload vs Next Block).
*   **Outcome:**
    *   Updates `ActiveProgram.currentBlockPhase`.
    *   Generates next week's schedule (Deload volume or New Block settings).

---

## Step 5.4: Data Export

**Action:** Allow users to own their data.

*   **File:** `App/Services/Export/ExportService.swift`
    *   `generateJSON()` -> Data
    *   `generateCSV()` -> String
*   **UI:** `SettingsView` update.
    *   "Export" button presents `ShareSheet`.

---

## Step 5.5: User-Created Exercises

**Action:** UI for adding custom movements.

*   **UI:** `App/UI/Exercises/ExerciseListView.swift`
    *   "Add (+)" button.
    *   Form: Name, Muscle Group, Type, Equipment.
    *   Save to `ExerciseRepository`.

---

## Step 5.6: Final Polish

*   **Action:** Review and refine.
    *   **Tempo Warnings:** Add visual alert in `WorkoutSessionView` if tempo is too slow in Hypertrophy block.
    *   **Empty States:** Handle empty graphs/logs gracefully.
    *   **Dark Mode:** Verify all colors.

---

## Step 5.7: Final Validation

**Action:** The "Golden Path" test.
*   Simulate 4 weeks of training (using seed scripts or manual entry).
*   Verify "Post Block Assessment" triggers.
*   Complete Assessment -> Verify Deload week is generated.
*   Export Data -> Verify JSON structure.
