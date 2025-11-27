# PRODUCT_REQUIREMENTS

### Product Requirements

**Version:** 0.1 (Draft)
**Platform:** iOS 16+ (SwiftUI)
**Target Device:** iPhone 16 Pro Max
**Storage:** Local (JSON File System)

##### Product Vision

To create a "self-correcting" training application that builds individualized resistance training programs based on the six levels of the Muscle & Strength Pyramid.
Unlike static template apps, this system will adjust based on:

- User goal and focus (Hypertrophy or Strength).
- User feedback (RPE) and stall/recovery patterns, promoting adherence and progressive overload.

##### Core Functional Requirements

###### A. User Onboarding (Adherence - Level 1)

This section ensures the program is Realistic, Enjoyable, and Flexible (REF).

- **Goal Selection:** User must choose between **Hypertrophy** (bodybuilding focus) or **Strength** (powerlifting focus).
- **Training Age Assessment:** The system must classify the user based on their expected rate of progress:
  - **Novice:** Expected to make progress workout-to-workout (linear gains).
  - **Intermediate:** Expected to make progress week-to-week (weekly/monthly gains).
  - **Advanced:** Expected to make progress month-to-month or block-to-block (multi-month block).
  - _Requirement:_ Initial volume must align with training age (Novice: 10–12 sets/wk; Intermediate: 13–15 sets/wk; Advanced: 16–20 sets/wk).
- **Schedule Configuration:** User selects available days (2-6).
  - The system must reject or warn the user if the selected frequency is infeasible for their required volume/training age (e.g., Advanced user attempting 2 days/week). The default recommended frequency is 2-5 days/week depending on training age to maintain quality.
- **Split Generation:** System generates a weekly schedule (Split) that satisfies Level 2 frequency guidelines (training each muscle group/movement **2+ times per week**).
- **Adherence Adjustment (Flexibility):**
  - **Missed Workout Handling:** If a user misses a session, prompt three options: **'Shift'** (Recommended: push the schedule back, picking up where they left off), **'Skip'** (Recommended only if the session was low-stress, accessory-focused, or a ‘power day’), or **'Combine'** (Merge essential volume into the next session, requiring prompt load reduction/RPE adjustment).
  - **Low Energy Toggle ('Short on Time'):** An option to automatically convert the current session to use high-efficiency techniques like Antagonist Paired Sets (APS) for suitable movements, or to minimize isolation volume. This minimizes the time commitment without sacrificing core training stimulus.

###### B. Workout Execution (VIF - Level 2)

This section defines how Volume, Intensity, and Frequency are managed within the app.

- **RPE Logging:** Users must log Load (lbs/kg), Reps, and **RPE (1-10 scale based on Repetitions in Reserve - RIR)** for every set.
  - _RPE Scale Display:_ The system must display the RPE scale: 10 (Failure, 0 RIR), 9 (1 RIR), 8 (2 RIR), 7 (3 RIR), 5-6 (4-6 RIR), 1-4 (Very light/light).
- **Rest Timer:** A smart timer that defaults based on context (exercise and intensity technique).
  - **Compound Lifts:** Defaults to 2.5–5 minutes (Guidance: Rest until ready).
  - **Isolation/Machine Lifts:** Defaults to 1.5–2 minutes.
  - _Autoregulation:_ Users must be able to manually stop the timer when ready, adhering to the principle of resting until ready for the next set.
- **Workout Library:** The system must include a comprehensive library of exercises (for split generation and progression tracking) and allow users to add new exercises.

###### C. Progression Engine (Level 3)

This section ensures structured progression and intelligent fatigue management.

- **Novice Logic (Single Progression):** Automated progression for compound lifts: If target reps are achieved with good form, load increases (e.g., 5-10 lbs/session). If failure occurs 2x consecutively, load must be decreased by 10% for one session, then return to the stalled load.
- **Intermediate Logic (Wave Loading / Linear Periodization):** Automated progression for compound lifts in 3-week cycles where load rises and repetitions drop (e.g., 3x8, 3x7, 3x6). Accessory movements use **Double Progression** (increasing reps within a range before increasing load).
- **Advanced Logic (Block Periodization):** System supports mesocycles (Accumulation blocks vs. Intensification blocks).
  - _Accumulation:_ Higher volume, moderate RPE (6-8), higher rep ranges (4-15 reps).
  - _Intensification:_ Lower volume, high RPE (8.5-10), lower rep ranges (2-10 reps).
  - _Realization/Taper:_ Required phase for testing or competition.
- **Introductory Cycles:** When starting a new block (especially transitioning from Intensity to Accumulation, or returning from a lay-off), the system automatically suppresses volume (e.g., 75% of target sets) and RPE (e.g., 1 point lower) for the first week to facilitate acclimation and prevent excessive soreness.
- **Plateau/Recovery Management:** The system triggers a "Post Block Assessment" to determine if a Deload or change in volume is needed. The checklist must include:
  - Are you plateaued? (Progress has stalled for 8-12 weeks).
  - Are fundamentals managed? (Sleep 8+ hrs? Energy surplus? Protein 0.7g/lb+? RPE estimated accurately? Technique solid?).
  - Are you recovering? (Dreading gym? Sleep quality worse? Loads/reps decreasing? Stress high? Aches/pains worse?).
- **Automated Deload Recommendation:** If two or more "recovering" checks are negative, the system recommends a deload week (approx. 50% volume of a normal training week, maintaining high intensity/load but reducing RPE/reps). A deload must be mandated every third mesocycle regardless of assessment.

###### D. Exercise Selection & Execution (Exercise - Level 4)

This section focuses on specificity, variety, and addressing weak points.

- **Smart Substitution Engine:** Users can swap exercises based on biomechanics or injury limitations, provided the correct movement pattern and volume requirements are maintained.
  - _Specificity Warning (Strength Track):_ Swapping competition lifts for non-specific variants (e.g., Back Squat for Leg Press) triggers a warning that may compromise neuromuscular strength adaptations, although it is accepted if due to injury or necessity.
  - _Hypertrophy Guideline (Variety):_ The system encourages variety (e.g., using different exercise variations mesocycle-to-mesocycle) to ensure balanced development and prevent specific hypertrophy limitations.
- **Weak Point Selector (Bodybuilding Track):** Users can identify lagging muscle groups (e.g., "Calves"). The system automatically prioritizes these isolation exercises earlier in the session, provided the fatigue generated does not significantly hinder subsequent performance of main compound lifts.
- **Specificity Check (Volume Ratio):** The system monitors volume distribution for adherence to goal-specific guidelines.
  - **Strength:** Ensures **50–75%** of total training volume is derived from competition lifts (Squat/Bench/Deadlift and direct variants); alerts if accessory volume becomes excessive.
  - **Hypertrophy:** Ensures **balance** of **1–2 Compound** movements vs. **1–3 Isolation** movements per major muscle group.
- **Exercise Ordering:** Enforce logic where Compound/Multi-joint exercises are sequenced before Isolation/Single-joint exercises for the same muscle group, optimizing performance on the most fatiguing lifts.

###### E. Rest & Efficiency Tools (Rest Periods - Level 5)

This section covers advanced efficiency techniques.

- **Context-Aware Rest Timer:** (See B. Rest Timer). The primary guidance is "Rest until ready," with the timer serving as a guideline/minimum boundary.
- **Efficiency Modes (APS):** Users can toggle **Antagonist Paired Sets** (APS) for time-saving. The UI groups the antagonistic exercises (e.g., Bench Press with Rows, Leg Extensions with Leg Curls) and adjusts the rest timer to track the "transition" vs. "true rest".
  - _Constraint:_ APS must be restricted to upper body compounds and isolation movements; the system must prevent APS use with full-body exercises (e.g., Squats, Deadlifts, heavy Lunges) due to excessive fatigue carryover.
- **Intensity Technique Logger:** Support for logging Drop Sets (tracking multiple loads per set) and Rest-Pause Sets for accessory movements.
  - _Constraint:_ These techniques generate high fatigue and must be restricted to non-barbell, accessory movements to save time and mitigate injury risk/systemic fatigue.

###### F. Tempo & Technique (Lifting Tempo - Level 6)

This section ensures technique prioritizes impulse over unnecessary time under tension.

- **Default "Standard" Tempo:** The system defaults all exercises to "Standard Tempo" (Controlled eccentric, forceful concentric) without requiring user input, enforcing the principle of prioritizing load/volume over counting seconds.
- **Advanced Tempo Notation:** For specific phases (e.g., Pause Squats or Technique work), the system supports 4-digit Tempo Codes (Eccentric-Pause-Concentric-Pause, e.g., "3-1-x-0") as an optional field in the program builder. 'X' denotes maximal intentional acceleration/forceful concentric.
- **Impulse Optimization Warning:** If a user manually programs excessively slow tempos (e.g., >4s eccentric) for hypertrophy blocks, the system flags a warning that this may reduce total volume/impulse and compromise growth .

#### G. Analytics & Visualization (Monitoring)

To ensure the user understands their position in the hierarchy and their progress over time.

- **The "Pyramid" Dashboard:** A visual representation of the user's current adherence to the hierarchy:
  - **Adherence Ring:** A weekly ring showing sessions completed vs. scheduled (e.g., 3/4 completed).
  - **Volume Equator:** A bar chart showing "Sets per Muscle Group" for the current week against the recommended range (10–20 sets). Bars turn red if under-dosed (<10) or potentially over-trained (>20).
- **Progression Trends (Level 3):**
  - **e1RM Tracking:** Line graphs for primary compound lifts showing "Estimated 1RM" calculated from sub-maximal sets (Load x Reps x RPE formula).
  - **Progress Labels:** Automated tags on the graph identifying phase changes (e.g., "Start of Accumulation Block", "Deload Week") to correlate program changes with strength spikes/dips.
- **Intensity Distribution (Level 2):**
  - **RPE Heatmap:** A visual breakdown of the last 4 weeks showing the distribution of difficulty (e.g., "80% of sets were RPE 7-9"). Helps identify if the user is "sandbagging" (too easy) or "overshooting" (too hard).
- **Macro-Cycle Overview (Advanced Only):**
  - A timeline view showing the current block (Accumulation) and upcoming blocks (Intensification -> Taper), giving the user a "Bird's Eye View" of their long-term plan.

### 1.3 Non-Functional Requirements

- **Privacy:** All workout and log data remains exclusively on-device.
- **Offline Capable:** Full functionality (logging, program viewing, timer, progress tracking) must operate without an internet connection.
- **Data Portability:** Ability for the user to export all training logs and programmed cycles as structured JSON/CSV files.
