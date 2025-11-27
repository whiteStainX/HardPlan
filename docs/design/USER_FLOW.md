# User Flow Diagrams
## The Muscle & Strength Pyramid Training App

These flows visualize the user's journey through the critical paths of the application, from initial setup to daily execution and long-term adjustment.

### 1. Flow A: Onboarding & Program Generation (The Setup)
**Goal:** Establish the user's baseline to generate a valid, sustainable program (Level 1 & 2).

1.  **Start Onboarding**
2.  **Goal Selection:**
    *   "What is your primary focus?"
    *   `[Selection: Strength (Powerlifting) | Hypertrophy (Bodybuilding)]`
3.  **Weak Point Selection (Hypertrophy Only):**
    *   "Do you have any lagging muscle groups you want to prioritize?"
    *   `[Selection: Calves | Biceps | Side Delts | etc. | None]`
    *   *System Action:* Flag selected muscle groups for priority ordering (Level 4).
4.  **Training Age Assessment (The Classifier):**
    *   "How fast do you currently make progress on main lifts?"
    *   `[Selection: Every Session (Novice) | Weekly/Monthly (Intermediate) | Multi-Month (Advanced)]`
    *   *System Action:* Set Progression Logic & Volume Baseline (e.g., Novice = 10-12 sets/wk).
5.  **Adherence Check (Schedule):**
    *   "How many days/week can you realistically train?" `(Slider: 2-6)`
    *   *Logic Check:* If (Advanced + <3 days) OR (Novice + >5 days) -> **Show Warning:** "This frequency may not match your training age/volume needs. Recommended: [X] days."
    *   *User Action:* Confirm or Adjust Days.
6.  **Split Generation:**
    *   *System Action:* Select template based on inputs (e.g., 4-Day Upper/Lower for Intermediate).
            *   **System Check:** Validate generated schedule meets 2+ times/week frequency rule for each muscle group/movement pattern.
Output: Generate "Week 1" Schedule.
7.  **End:** Navigate to Dashboard.

### 1. Flow A: Onboarding & Program Generation (The Setup)
**Goal:** Establish the user's baseline to generate a valid, sustainable program (Level 1 & 2).

1.  **Start Onboarding**
2.  **Goal Selection:**
    *   "What is your primary focus?"
    *   `[Selection: Strength (Powerlifting) | Hypertrophy (Bodybuilding)]`
3.  **Weak Point Selection (Hypertrophy Only):**
    *   "Do you have any lagging muscle groups you want to prioritize?"
    *   `[Selection: Calves | Biceps | Side Delts | etc. | None]`
    *   *System Action:* Flag selected muscle groups for priority ordering (Level 4).
4.  **Training Age Assessment (The Classifier):**
    *   "How fast do you currently make progress on main lifts?"
    *   `[Selection: Every Session (Novice) | Weekly/Monthly (Intermediate) | Multi-Month (Advanced)]`
    *   *System Action:* Set Progression Logic & Volume Baseline (e.g., Novice = 10-12 sets/wk).
5.  **Adherence Check (Schedule):**
    *   "How many days/week can you realistically train?" `(Slider: 2-6)`
    *   *Logic Check:* If (Advanced + <3 days) OR (Novice + >5 days) -> **Show Warning:** "This frequency may not match your training age/volume needs. Recommended: [X] days."
    *   *User Action:* Confirm or Adjust Days.
6.  **Split Generation:**
    *   *System Action:* Select template based on inputs (e.g., 4-Day Upper/Lower for Intermediate).
            *   **System Check:** Validate generated schedule meets 2+ times/week frequency rule for each muscle group/movement pattern.
Output: Generate "Week 1" Schedule.
7.  **End:** Navigate to Dashboard.

**Dashboard View Includes:**
*   *Pyramid Status:* Adherence Ring (Weekly sessions) + Volume Equator (Sets/Muscle).
*   *Next Workout Card:* "Day 1: Upper Body - Power".
*   *Trends:* Quick-view sparkline of e1RM for primary focus lift.
*   *Navigation:* Tap "Analytics" or "Program Overview" to go to dedicated screens.

---

### 7. Flow G: Analytics & Insights (Monitoring Progress)
**Goal:** Visualize progress, trends, and adherence to the Pyramid principles.

1.  **Entry Point:** User taps "Analytics" from Dashboard or "Program Overview" from Settings.
2.  **e1RM Trend View:**
    *   **Step:** System loads and displays `e1RMHistory` for primary compound lifts.
    *   User can select a lift to view its trend.
    *   Timeline shows `BlockPhaseSegments` (Accumulation, Intensification, Realization) for context.
3.  **RPE Distribution Panel:**
    *   **Step:** System loads `rpeDistribution` for the last 4-8 weeks.
    *   Displays a chart (e.g., bar chart) showing count/percentage of sets in RPE ranges (e.g., "6-7", "7.5-8.5", "9-10").
    *   **Guidance:** Provides short text interpretation (e.g., "Most of your work is in the RPE 7.5-8.5 range, which is suitable for hypertrophy with good proximity to failure.").
4.  **Macro-cycle Timeline:**
    *   **Step:** System displays a horizontal timeline of `ActiveProgram.blocks`.
    *   Blocks are labeled with `BlockPhase` and dates. Current block is highlighted.
    *   User can scroll/swipe to view past blocks.
    *   **Optional:** Tap a block for summary (duration, focus, avg volume).
5.  **Tempo Warning (Advisory):**
    *   **Step:** System checks for `TempoWarning` flags (from `ALGORITHM_SPEC.md`).
    *   If present, displays an informational message (e.g., "Most of your hypertrophy work this block used very slow eccentrics. Consider slightly faster eccentrics to keep volume practical.").

---

### 8. Flow H: Data Export
**Goal:** Allow users to export their training data for backup or analysis.

1.  **Entry Point:** User opens Settings/Profile, taps "Export Training Data".
2.  **System Action:**
    *   Gathers data: `UserProfile`, `ActiveProgram`, `WorkoutLogs` (including `CompletedSets`).
    *   Generates a JSON and/or CSV representation of the data.
3.  **Output:** System presents the iOS share sheet.
4.  **User Action:** User chooses to:
    *   Save to Files.
    *   Send to an app.
    *   Email it, etc.

### 2. Flow B: The Daily Workout (Execution)
**Goal:** Guide the user through a workout while capturing RPE and managing time (Level 2, 5, 6).

1.  **Start:** User selects "Today's Workout" from Dashboard.
    *   **Session Start Options:**
        *   Option: `Start normally`
        *   Option: `Short on Time (APS)`
            *   *System Action:* If "Short on Time (APS)" selected, call session adjustment logic to produce a reduced set of exercises/sets focusing on primary work. Set `WorkoutLog.mode = "shortOnTime"`.
2.  **Adherence Check (Pre-Workout):**
    *   *System Check:* Is this the scheduled day?
    *   **If Missed:** Trigger Missed Workout Flow (See Flow C).
    *   **If On Track:** Proceed to Warm-up.
3.  **Warm-up:**
    *   Display Dynamic Warm-up checklist.
    *   *User Action:* User marks "Complete".
4.  **Exercise Loop (Repeat for each exercise):**
    *   **Setup:** Display Target Load, Reps, and Notes (e.g., "Tempo: Standard").
        *   *While in APS mode:* UI displays "Short on Time" indicator; accessories might be fewer or absent.
    *   **Weak Point Logic (Bodybuilding Only):** If "Weak Point" selected (e.g., Calves), ensure this exercise is at the top of the list (Done during Generation).
    *   **Set Execution:**
        *   User performs set.
        *   *Input:* User logs Load, Reps, and RPE (1-10).
        *   *UI Element:* Display RPE Reference Guide (10=Failure, 0 RIR; 9=1 RIR, etc.) during input.
    *   **Rest Timer:**
        *   *Auto-Start:* Based on context (Compound: 3m+ | Isolation: 1.5m).
        *   *User Action:* Can tap "Ready Now" to stop early (Autoregulation).
    *   **Efficiency Toggle (APS):** User toggles "APS Mode" for the session -> System rearranges remaining eligible exercises (excludes full-body compound lifts like Squats/Deadlifts/heavy Lunges) into antagonistic pairs -> Timer updates to track transition time.
5.  **Finish Workout:** User taps "Complete Session".
6.  **Post-Processing:**
    *   *System Action:* Save logs to JSON.
    *   *System Action:* Trigger Progression Engine to calculate next session's numbers.
7.  **End:** Return to Dashboard.

---

### 3. Flow C: Adherence & Flexibility Handling
**Goal:** Manage life interruptions without breaking the program (Level 1).

#### Scenario 1: Missed Workout
*   **Trigger:** User opens app after missing a scheduled session date.
*   **Prompt:** "You missed your last session. How do you want to proceed?"
*   **Selection:**
    *   **Option A: Shift (Recommended):** Push entire schedule back 1 day. (No data loss).
    *   **Option B: Skip:** Mark session as "Skipped" (Only allowed for Accessory days).
    *   **Option C: Combine:** Merge key lifts into today's session.
*   **System Action:** If Combine -> Reduce Volume of secondary lifts by 30-50% to manage fatigue.

#### Scenario 2: Low Energy / Short on Time
*   **Trigger:** User toggles "Short on Time" button on Workout Overview screen.
*   **System Action (Optimization):**
    *   Convert eligible pairs to Antagonist Paired Sets (APS).
    *   Convert accessory slots to Drop Sets (if applicable).
*   **Goal:** Maintain Intensity/Volume but reduce duration.
*   **Output:** Refresh Workout View with new grouping/timer settings.

---

### 4. Flow D: The Progression Engine (The "Brain")
**Goal:** Determine the targets for the next session based on today's performance (Level 3).

#### Sub-flow D1: Novice (Single Progression)
1.  **Input:** Last Session Log (Exercise A).
2.  **Check:** Did user hit target reps?
    *   **Yes:** Next Load = Current Load + [Increment] (5-10lbs).
    *   **No (1st Fail):** Next Load = Current Load (Retry).
    *   **No (2nd Consecutive Fail):** Trigger Stall Logic.
3.  **Action:** Next Load = Current Load * 0.90 (10% Reset).
4.  **Notification:** "Reset applied. Focus on form and speed."

#### Sub-flow D2a: Intermediate (Wave Loading)
1.  **Input:** Current Week (1, 2, or 3).
2.  **Action:**
    *   **Week 1:** Target 8 reps (Base Load).
    *   **Week 2:** Target 7 reps (Base Load + 5lbs).
    *   **Week 3:** Target 6 reps (Base Load + 10lbs).
3.  **End of Block (Week 3 Completed):** Trigger Post-Block Assessment.

#### Sub-flow D2b: Intermediate (Double Progression (Accessory Lifts))
1.  **Input:** Last Session Log (Accessory Exercise A).
2.  **Check:** Did user hit top of prescribed rep range?
    *   **Yes:** Increase Load, reset to bottom of rep range.
    *   **No:** Keep Load, try to add reps next time within the range.

#### Sub-flow D3: Post-Block Assessment (Reactive Deload)
1.  **Trigger:** End of Intermediate Wave (Week 3) or Advanced Block (Week 4/5).
2.  **System Action:**
    *   Compute **e1RM trends** for main lifts over the last 8–12 weeks.
    *   Detect **plateau** if e1RM change is minimal (`±1-2%`).
3.  **User Input:** "Post-Block Checklist" Modal (expanded).
    *   Q1: "Sleep adequate (≥7h avg)?" (Y/N - based on `FundamentalsStatus`)
    *   Q2: "Protein intake adequate?" (Y/N - based on `FundamentalsStatus`)
    *   Q3: "Stress manageable?" (Y/N - based on `FundamentalsStatus`)
    *   Q4: "No major diet issues?" (Y/N - based on `FundamentalsStatus`)
    *   Q5: "Loads decreasing / Dreading gym / Aches and pains?" (Y/N - fatigue markers)
    *   Q6: "RPE accurate / Technique solid?" (Y/N - based on `ALGORITHM_SPEC.md` hints)
4.  **Logic & Decision:**
    *   **IF** `plateauDetected` **AND** `severalFundamentalsPoor` (e.g., 2+ fundamentals are 'No'):
        *   **Recommendation:** "Focus on improving sleep/nutrition/stress before drastic program changes. Programming adjustments will be minor."
    *   **ELSE IF** `plateauDetected` **AND** `fundamentalsMostlyFine`:
        *   **Recommendation:** "Consider adjusting volume or moving to a slightly different block configuration (e.g., different rep ranges, more speed work for Strength; exercise variation for Hypertrophy)."
    *   **ELSE IF** `fatigueMarkersHigh` (e.g., Q5 Score 2+):
        *   **Recommendation:** "Deload Recommended. Focus on recovery this week."
    *   **ELSE:**
        *   **Recommendation:** "Progression continues. Next block will be X."
5.  **User Confirmation:** User confirms decision (e.g., "Proceed with Deload", "Continue to Next Block").
6.  **System Action:** Generate "Week X" (Deload or Next Block).
    *   **Volume:** 50% of normal sets (for Deload).
    *   **Intensity:** Maintain Load, reduce Reps/RPE (for Deload).
7.  **Mandatory Check:** Is this the 3rd consecutive block without a deload?
    *   **Yes:** Force Deload Week regardless of assessment score.

---

### 5. Flow E: Advanced Block Periodization (Macro-Cycle)
**Goal:** Manage long-term phases for Advanced users (Level 3).

1.  **Start Block:** System checks User Profile -> CurrentBlock status.
2.  **Phase 1: Accumulation (Hypertrophy/Work Capacity):**
    *   **Settings:** Sets = 16-20, Reps = 8-15, RPE = 6-8.
    *   **Duration:** 4-6 Weeks.
    *   **Progression:** Increase Sets/Volume first, then Load.
    *   **Transition:** Trigger Introductory Cycle logic if moving from Intensification.
    *   **Action:** Week 1 (Introductory) Volume = 75% of target sets/load and Target RPE -1 to acclimate.
3.  **Phase 2: Intensification (Strength):**
    *   **Settings:** Sets = 12-15, Reps = 3-6, RPE = 8-9.5.
    *   **Duration:** 3-4 Weeks.
    *   **Progression:** Increase Load aggressively, Drop Volume.
4.  **Phase 3: Realization (Taper/Test):**
    *   **Settings:** Volume = 50%, Intensity = Maintenance.
5.  **End:** User inputs New 1RM or AMRAP results -> System recalculates Training Maxes.

---

### 6. Flow F: The Substitution Logic (Level 4)
**Goal:** Allow flexibility without breaking specificity.

1.  **Trigger:** User taps "Swap" on an exercise (e.g., Back Squat).
2.  **System Action:** Call `SubstitutionService` with `currentExercise` ID, `userGoal` (strength/hypertrophy), `availableEquipment`, and `userExcludedExercises`.
3.  **System Output:** Service returns a list of `SubstitutionOption` objects (including `exerciseId`, `displayName`, `specificityScore`, and optional `warning`).
4.  **Display Options:** Present candidate exercises to the user, potentially sorted by `specificityScore`.
5.  **User Selection:** User selects a candidate substitution.
6.  **Decision Node (Strength Goal Warning):**
    *   **IF** `userGoal` = Strength **AND** `originalExercise.isCompetitionLift` = true **AND** `selectedOption.warning` is present (low specificity):
        *   **Display Warning:** Show a prominent warning message (e.g., "You are replacing a competition lift with a non-competition variant. This may reduce specificity for strength. Are you sure?").
        *   **User Action:** Confirm or Cancel.
            *   **Confirm:** Proceed with substitution.
            *   **Cancel:** Keep original exercise; return to workout setup.
    *   **ELSE (Hypertrophy Goal or High Specificity Strength Swap):**
        *   Proceed with substitution. No strong warning needed.
7.  **System Action:** Update the current `ScheduledExercise` to the selected `exerciseId`.