# Logic & Algorithm Specifications
## The Muscle & Strength Pyramid Training App

**Version:** 0.2 (Refined)
**Purpose:** Defines the mathematical logic, decision trees, and data structures for the "Progression Engine," "Volume Regulator," and "Auto-Regulation" systems.

---

### 1. Volume Calculation Logic (The "Overlap" Rule)
**Goal:** Accurately track "sets per muscle group" by accounting for compound movements hitting multiple areas. This ensures users stay within the 10-20 sets/week guideline without overtraining secondary movers.

#### 1.1 Muscle Group Mapping
Each `Exercise` in the database must have a `primary_muscle` and an array of `secondary_muscles` with associated coefficients (impact factors).

**Data Structure:**
```swift
struct MuscleImpact {
    let muscle: MuscleGroup
    let factor: Double // 1.0 = Direct Work, 0.5 = Indirect Work
}
```

**Standard Mappings (Examples):**
*   **Squat Pattern:**
    *   Primary: Quads (1.0)
    *   Secondary: Glutes (1.0), Adductors (0.5), Spinal Erectors (0.5)
*   **Bench Press Pattern:**
    *   Primary: Chest (1.0)
    *   Secondary: Front Delt (1.0), Triceps (0.75)
*   **Deadlift Pattern:**
    *   Primary: Hamstrings (1.0), Glutes (1.0), Spinal Erectors (1.0)
    *   Secondary: Quads (0.5), Traps (0.5), Forearms (0.5)
*   **Row Pattern:**
    *   Primary: Lats (1.0), Rhomboids (1.0)
    *   Secondary: Rear Delt (0.5), Biceps (0.5)

#### 1.2 Weekly Volume Aggregation Algorithm
**Trigger:** Run this calculation whenever the user generates a split or logs a workout.

**Logic:**
1.  Initialize `VolumeTotals` dictionary: `{ Quads: 0.0, Chest: 0.0, ... }`.
2.  Fetch all `CompletedSets` for the current Microcycle (Week).
3.  **For each Set:**
    *   Add `1.0` to the `primary_muscle` count.
    *   Add `factor` (e.g., 0.5) to each `secondary_muscle` count.
4.  **Validation:**
    *   If `VolumeTotals[Muscle] < 10`: Flag as **"Under-dosed"**.
    *   If `VolumeTotals[Muscle] > 20`: Flag as **"High Volume"** (Warning for Novices).

**Note:** For UI display, round `VolumeTotals` to the nearest integer to avoid user confusion (e.g., "12.5 sets" -> "12 sets"). The fractional logic remains internally for precise fatigue management.

#### 1.3 Specificity Check Algorithm (Level 4)
**Goal:** Ensure Strength users prioritize competition lifts.
**Logic:**
1.  Calculate `CompetitionVolume` (Sum of sets for Squat, Bench, Deadlift & variants).
2.  Calculate `TotalVolume` (Sum of all sets).
3.  Calculate `Ratio = CompetitionVolume / TotalVolume`.
4.  **Check:** If `Ratio < 0.50` AND `Goal == Strength` -> **Trigger Warning**: "Competition lift volume is too low (<50%)."

---

### 2. Progression Engine Logic
**Goal:** Determine the specific Load (lbs/kg) and Target Reps for the next session.

#### Utility Function: Rounding
All calculated loads must be rounded to the nearest available plate increment (usually 2.5kg or 5lbs).
`RoundToPlate(Value, Increment) = round(Value / Increment) * Increment`

#### 2.1 Novice Logic (Single Progression)
**Context:** Linear gains. Add weight, keep reps static.
**Inputs:** `LastSessionLog` (Load, RepsCompleted, TargetReps), `StallCounter`.

**Algorithm:**
1.  **Success Check:**
    *   **Definition of Failure:** Strictly defined as **Missed Reps** (Did not complete Target Reps). RPE is ignored for Novices here.
    *   If `RepsCompleted >= TargetReps`: **Success**.
    *   Else: **Fail**.
2.  **Success Branch:**
    *   `NextLoad = CurrentLoad + Increment`
        *   Upper Body Increment: 2.5 - 5 lbs
        *   Lower Body Increment: 5 - 10 lbs
    *   `StallCounter = 0`
3.  **Failure Branch:**
    *   **Fail #1:**
        *   `NextLoad = CurrentLoad` (Retry)
        *   `StallCounter = 1`
    *   **Fail #2 (Consecutive):**
        *   **Action:** RESET.
        *   `NextLoad = RoundToPlate(CurrentLoad * 0.90)` (Reduce by 10%)
        *   `StallCounter = 0`
        *   **Flag:** If `ResetCount > 3` for this exercise, suggest switching to Intermediate Logic.

**Long Hiatus Logic:**
*   If `DaysSinceLastLog > 14`:
    *   **Action:** Force a "Reset". `NextLoad = CurrentLoad * 0.80` (20% reduction) to safely rebuild work capacity.

#### 2.2 Intermediate Logic (Wave Loading)
**Context:** Linear Periodization. 4-Week Microcycles (Waves).
**Inputs:** `CurrentWeek` (1-4), `BaseLoad` (The starting load for the block).

**Wave Patterns:**
*   **Strength Focus:**
    *   Week 1: Target 8 Reps @ BaseLoad
    *   Week 2: Target 7 Reps @ BaseLoad + 5lbs
    *   Week 3: Target 6 Reps @ BaseLoad + 10lbs
*   **Hypertrophy Focus:**
    *   Week 1: Target 12 Reps @ BaseLoad
    *   Week 2: Target 10 Reps @ BaseLoad + 5lbs
    *   Week 3: Target 8 Reps @ BaseLoad + 10lbs

**Week 4 (Deload/Decision) Logic:**
1.  **Trigger:** Post-Block Assessment.
2.  **Mandatory Deload Check:**
    *   If `ConsecutiveBlocksWithoutDeload >= 3`:
        *   **Action:** Force **Deload Week** regardless of assessment score.
3.  **Run Assessment Checklist** (Sleep, Stress, Aches).
    *   **Score 0-1 (Recovered):**
        *   *Action:* Increase `BaseLoad` by 5-10lbs.
        *   *Next:* Start Week 1 of **Next Wave** immediately (Skip Deload).
    *   **Score 2+ (Fatigued):**
        *   *Action:* Schedule **Deload Week**.
        *   *Deload Settings:* 2 sets per exercise @ Week 1 Load (Light intensity).
        *   *Next:* After Deload, start Week 1 of Next Wave with `BaseLoad` + 5lbs.

#### 2.3 Accessory Logic (Double Progression)
**Context:** Used for Isolation lifts where load increases are hard (e.g., Lateral Raise).
**Inputs:** `RepRange` (e.g., 12-15), `CurrentLoad`, `RepsCompleted`.

**Algorithm:**
1.  **Check:** Did user hit the **top** of the rep range (e.g., 15) for **all** sets?
    *   **Yes:**
        *   **Check Jump:** Is `CurrentLoad + SmallestIncrement` feasible? (e.g., next dumbbell is +5lbs, which is >10% jump).
            *   *If Jump is too big:* **Extend Rep Range** (e.g., New Target: 20 reps) instead of increasing load.
            *   *If Jump is safe:*
                *   `NextLoad = CurrentLoad + SmallestIncrement` (e.g., 2.5lbs).
                *   `NextTargetReps = Bottom of range` (e.g., 12).
    *   **No:**
        *   `NextLoad = CurrentLoad`.
        *   `NextTargetReps = RepsCompleted + 1` (Aim to add 1 rep per set).

#### 2.4 e1RM Calculation
**Goal:** Estimate 1-Rep Max for main lifts to track long-term progression.

1.  **Formula (Epley):**
    ```
    e1RM = weight * (1 + reps / 30.0)
    ```
    Where `weight` is the bar load and `reps` is the number of completed reps for a top set.
2.  **Eligible Sets:**
    *   For each main lift per session, take **the top working set**:
        *   The highest `load` with `RPE` between 7.0 and 9.5 (inclusive).
    *   **Ignore:** Warmup sets, very low RPE sets (< 7.0), clearly failed sets (e.g., `repsCompleted < targetReps` AND `RPE == 10`).
3.  **Aggregation:**
    *   For each eligible set, compute an `e1RMPoint` with:
        *   `date` (session date from `WorkoutLog`)
        *   `e1rm` (computed value)
        *   `liftId` / `exerciseId` of the main lift.
    *   Store this in a time series (e.g., `AnalyticsSnapshot.e1RMHistory`).
4.  **Use in Algorithms:**
    *   **Plateau Detection:** Relies on this `e1RM` time series.
    *   **Dashboard:** Used for trend visualization and block phase context.

---

### 3. Auto-Regulation Logic (RPE Adjustments)
Goal: Adjust daily load based on readiness (Intra-Workout) and validate progression (Inter-Workout).

#### 3.1 Intra-Workout (Next Set Adjustment)
Inputs: TargetRPE (e.g., 8.0), ActualRPE (User Input), CurrentLoad.

Algorithm:
1.  Calculate `Difference = ActualRPE - TargetRPE`.
2.  Rules:
    *   If `Difference > 1.0` (Overshot, e.g., RPE 9 vs 8):
        *   Action: Decrease Load by 2-5% for next set.
    *   If `Difference < -1.0` (Undershot, e.g., RPE 6 vs 8):
        *   Action (Advanced Only): Increase Load by 2-5% for next set.
        *   Action (Novice/Int): Log note for next session; Keep Load for safety.
    *   Else: Keep Load.

#### 3.2 Inter-Workout (Next Session Validation)
Rule: Even if Rep Targets are hit, if ActualRPE was consistently 10 (Failure) when TargetRPE was < 9, do not increase load for the next session. Force a repeat of the current load to ensure mastery.

---

### 4. Tempo Sanity Check
**Goal:** Provide advisory warnings for tempos that may reduce effective training impulse or volume.

1.  **Inputs:**
    *   `targetTempo` (from `ScheduledExercise` or user overrides, parsed into `eccentric`, `pause`, `concentric`, `topPause` durations).
    *   `blockType` (`Accumulation`, `Intensification`, `Realization`).
    *   `goal` (`Strength` vs `Hypertrophy`).
2.  **Rules:**
    *   For **Hypertrophy** blocks:
        *   If the majority of working sets (e.g., `> 50%` of sets in a week) use an `eccentricTempo` of `5 seconds or longer`, mark this as **“excessively slow”**.
    *   For **Strength** blocks:
        *   If `eccentrics` are slower than `4–5 seconds` on `> 50%` of sets, it may also be flagged as potentially reducing bar speed and power.
3.  **Output:**
    *   When such patterns are detected, return a `TempoWarning` object:
        ```swift
        struct TempoWarning {
            enum Level: String, Codable { case info, warning }
            let level: Level
            let message: String // e.g., "Most of your hypertrophy work is using very slow tempos. Consider slightly faster eccentrics to keep volume practical."
        }
        ```
4.  **Effect:**
    *   This does **not** automatically change the program; it is **advisory only**, surfaced in UI (e.g., Block Summary/Analytics).

---

### 5. Adherence Logic (Missed Workouts)
Goal: Handle schedule interruptions gracefully (Level 1).
Inputs: LastLogDate, CurrentDate.

Algorithm:
1.  `DaysSinceLast = CurrentDate - LastLogDate`.
2.  `GapThreshold = 4 days`.
3.  **Re-acclimation Check:**
    *   If `DaysSinceLast > GapThreshold`:
        *   *Trigger:* "Welcome Back" logic.
        *   *Action:* Apply temporary **-10% Load Modifier** for the first session back.

**Missed Session Handler:**
*   **Shift Schedule:** `NextSessionIndex = LastSessionIndex + 1`. (Dates shift, order preserved).
*   **Combine Sessions:**
    1.  Identify `PrimaryLifts` (Compounds) vs `SecondaryLifts` (Isolation) from missed + current session.
    2.  **Merge:** Include all PrimaryLifts.
    3.  Include SecondaryLifts **only if** `TotalSets < 25`. (Safety Cap: Max 1.5x normal volume).
    4.  **Reduction:** Reduce sets of all SecondaryLifts by 1.

#### 5.1 Short-on-Time / APS Mode
**Goal:** Enable users to reduce session duration while protecting primary training stimulus.

1.  **Activation:**
    *   APS / short-on-time mode can be toggled by the user **before starting a session** or at the beginning of it.
2.  **Selection of Sets (Trimming Algorithm):**
    *   **Keep:** All `primary sets` (competition lifts and key compounds) must be retained.
    *   **Trim Accessories:**
        *   Assign each accessory an implicit `priority` based on:
            *   `MovementPattern` importance (e.g., multi-joint > single-joint).
            *   `Exercise.tier` (e.g., Tier 2 before Tier 3).
            *   Relation to `goal` (e.g., hypertrophy-specific isolation in a hypertrophy block).
            *   `WeakPoint` status (prioritize weak point exercises).
        *   **Strategy:**
            1.  First, drop accessories with the lowest `priority`.
            2.  If still too long, reduce the number of sets (e.g., `targetSets - 1`) for mid-priority accessories.
    *   **Target Duration:** Aim to cut the session down to roughly half the typical duration while protecting primary work. (e.g., from 90 mins to 45 mins).
3.  **Recording in Logs:**
    *   When APS mode is active for a session, the `WorkoutLog.mode` is set to `"shortOnTime"`.
    *   Dropped scheduled sets are simply **not instantiated** as `CompletedSet` entries in the `WorkoutLog`.
    *   Analytics should recognize the reduced volume for that session (`WorkoutLog.mode == "shortOnTime"`) to avoid misinterpreting.

---

### 6. Advanced Block Periodization Logic
Goal: Manage macro-cycles (Accumulation vs. Intensification vs. Realization).

#### Phase 1: Accumulation (Volume Focus)
*   **Settings:** Sets: 4-5, Reps: 8-15, RPE: 6-8.
*   **Progression:** Prioritize adding **Sets** or **Reps**.
*   **Transition (Introductory Week):**
    *   *Trigger:* Start of Accumulation block.
    *   *Action:* `VolumeModifier = 0.75`, `RPE_Modifier = -1.0`.

#### Phase 2: Intensification (Strength Focus)
*   **Settings:** Sets: 3-4, Reps: 3-6, RPE: 7-9.
*   **Progression:** Prioritize adding **Load**.

#### Phase 3: Realization (Taper/Test)
*   **Settings:**
    *   **Volume:** 50% of Intensification volume (Drop sets).
    *   **Intensity:** Maintain High Load (90%+ 1RM) but Low Reps (Singles/Doubles) to keep RPE < 7.
*   **Goal:** Dissipate fatigue while maintaining neuromuscular adaptation before a test/comp.

---

### 7. Post-block Assessment – Fundamentals & Plateau
**Goal:** Provide actionable insights based on e1RM trends and fundamental lifestyle factors.

1.  **Plateau Detection:**
    *   For each main lift:
        *   Look at the **e1RM trend** over the last **8–12 weeks** (two or more blocks).
        *   If `latest_e1RM` is within `±1-2%` of `e1RM_8_12_weeks_ago`, mark this lift as **stalled**.
2.  **Fundamentals Checklist:**
    *   Use recent `sessionRPE`, `wellnessScore`, and `FundamentalsStatus` (from UserProfile or a periodic input) to assess:
        *   **Sleep:** Average `sleepHours` ≥ 7 hours?
        *   **Protein:** `proteinIntakeQuality` (e.g., "ok" or "good")?
        *   **Stress:** `stressLevel` not "high" most of the time?
        *   **Diet:** Not in severe deficit unintentionally?
    *   For each fundamental that looks poor, add an item to a **“Fundamentals to fix” list**.
3.  **Technique & RPE Accuracy Hints:**
    *   From `WorkoutLog` data for last 4 weeks:
        *   If `actualRPE` is often 9–10 while `loadProgression` is minimal → **Hint:** "Suspect aggressive loading and poor RPE discipline."
        *   If `RepsCompleted` frequently fail *before* `TargetRPE` (e.g., RPE 7-8 when target was 9) → **Hint:** "Suspect under-estimation of RPE or technique issues."
    *   *Effect:* These are **advisory hints** for the user, not triggers for automatic program changes.
4.  **Decision Outcomes:**
    *   If **plateau detected** (e1RM flat) **AND** several fundamentals are poor:
        *   **Recommendation:** "Focus first on fundamentals (sleep, nutrition, stress) before making drastic programming changes."
    *   If **plateau detected** **AND** fundamentals mostly fine:
        *   **Recommendation (Strength):** "Consider different rep ranges, slightly higher volume, or another phase emphasizing a different quality (e.g., speed work)."
        *   **Recommendation (Hypertrophy):** "Consider adjusting exercise selection or volume within the recommended range."

---

### 8. Substitution Engine Logic
**Goal:** Allow users to swap exercises while maintaining training efficacy and providing specific guidance.

1.  **Specificity Score Calculation:**
    *   For each candidate substitution, compute a `specificityScore` (0.0 - 1.0) based on:
        *   **Movement Pattern Match:** `+0.5` if `candidate.pattern == original.pattern`.
        *   **Equipment Match:** `+0.2` if `candidate.equipment == original.equipment`.
        *   **Competition Lift Match:** `+0.3` if `candidate.isCompetitionLift == original.isCompetitionLift`.
        *   **(Conceptual scoring - subject to refinement during implementation).**
    *   `specificityScore` is capped at `1.0`.
2.  **Strength Goal Rules:**
    *   For **Strength** focused programs (`UserProfile.goal == "Strength"`):
        *   If `original.isCompetitionLift == true` AND `candidate.isCompetitionLift == false` (e.g., Barbell Squat -> Leg Press):
            *   **Reduce specificity significantly** (e.g., `specificityScore = specificityScore * 0.5`).
            *   Return a **warning**:
                ```swift
                SubstitutionWarning(level: .warning, message: "You are replacing a competition lift with a non-competition variant. This may reduce specificity for strength. Are you sure?")
                ```
    *   If `original.isCompetitionLift == false` but `candidate.isCompetitionLift == true` (e.g., Leg Press -> Barbell Squat):
        *   **Increase specificity**. No warning.
3.  **Hypertrophy Goal Rules:**
    *   For **Hypertrophy** focused programs (`UserProfile.goal == "Hypertrophy"`):
        *   Specificity is more flexible. Equipment changes are allowed more freely as long as the `MovementPattern` and `targetMuscles` are reasonable.
        *   No strong warnings needed unless the replacement is very dissimilar (e.g., Squat -> Calf Raise, which should be filtered out by pattern anyway).
4.  **Output for UI:**
    *   The `SubstitutionEngine` returns a list of `SubstitutionOption` objects:
        ```swift
        struct SubstitutionOption: Identifiable, Codable {
            let id: String // ExerciseID of candidate
            let exerciseName: String
            let specificityScore: Double // 0.0 – 1.0
            let warning: SubstitutionWarning?
        }
        struct SubstitutionWarning {
            enum Level: String, Codable { case info, warning }
            let level: Level
            let message: String
        }
        ```
    *   The UI uses `specificityScore` for sorting/display and `warning` for user prompts.