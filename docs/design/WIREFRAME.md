# UI Wireframes (ASCII Art)
## The Muscle & Strength Pyramid Training App

This document drafts the basic layout and key elements of critical user interfaces using ASCII art.

---

### 1. Onboarding: Training Age & Schedule Configuration (Flow A)

This screen captures user baseline data.

```
+---------------------------------------------------+
|               ONBOARDING: THE SETUP               |
+---------------------------------------------------+
|                                                   |
|  "How fast do you progress on main lifts?"        |
|                                                   |
|  [ ] Novice (Every Session)                       |
|  [ ] Intermediate (Weekly/Monthly)                |
|  [X] Advanced (Multi-Month)                       |
|                                                   |
|---------------------------------------------------|
|                                                   |
|  "How many days/week can you realistically train?"|
|                                                   |
|  <-- 3 Days --- (X) ---- 6 Days -->               |
|       (Slider or Stepper)                         |
|                                                   |
|  [!] Warning: This frequency may not match...     |
|      (If Advanced + <3 days, or Novice + >5 days) |
|                                                   |
|---------------------------------------------------|
|                                                   |
|  [ ] Goal: Hypertrophy (Bodybuilding)             |
|  [X] Goal: Strength (Powerlifting)                |
|                                                   |
|  [ Next ]                                         |
|                                                   |
+---------------------------------------------------+
```

---

### 2. Dashboard: The Pyramid Hub (Post-Onboarding & Daily View)

This is the main screen, emphasizing Adherence and Volume.

```
+---------------------------------------------------+
|             THE PYRAMID APP: DASHBOARD            |
+---------------------------------------------------+
|                                                   |
|  < Today >                                        |
|                                                   |
|  +-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-+  |
|  |             ADHERENCE (Level 1)             |  |
|  |                                             |  |
|  |     [  80%  ]   (Weekly Sessions Complete)  |  |
|  |     [ring]                                  |  |
|  |                                             |  |
|  |---------------------------------------------|  |
|  |             VOLUME (Level 2)                |  |
|  |                                             |  |
|  | CHEST: [####------] 12/10-20 Sets           |  |
|  | QUADS: [###########] 20/10-20 Sets          |  |
|  | BICEP: [##X--------]  6/10-20 Sets (Under)  |  |
|  |                                             |  |
|  +-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-+  |
|                                                   |
|  -------------------------------------------------|
|                                                   |
|  🔥 TODAY'S WORKOUT: Upper Body Power             |
|  [ Start Session ]                                |
|                                                   |
+---------------------------------------------------+
```

---

### 3. Workout View: RPE Logger & Rest Timer (Flow B)

The core execution screen for logging sets.

```
+---------------------------------------------------+
|             WORKOUT: UPPER BODY POWER             |
+---------------------------------------------------+
|                                                   |
|  [ Short on Time (APS) Toggle: OFF ]  (Session-level toggle)
|  -------------------------------------------------|
|  Barbell Bench Press  (3 Sets x 5 Reps @ RPE 8)   |
|                                                   |
|  SET 1 of 3:                                      |
|    Load: [ 225 ] lbs                              |
|    Reps: [  5  ]                                  |
|    RPE:  [  8.0 ]                                 |
|                                                   |
|    RPE GUIDE: 10=0RIR, 9=1RIR, 8=2RIR...          |
|                                                   |
|    [ Complete Set ]                               |
|                                                   |
|---------------------------------------------------|
|                                                   |
|  REST TIMER:  [ 02:45 ]                           |
|               (Compound Lift Default: 3-5 min)    |
|                                                   |
|  [ Ready Now ]  [ Toggle APS Mode ]               |
|                                                   |
+---------------------------------------------------+
```
**Annotation for APS Toggle Behavior:**
- When "Short on Time (APS) Toggle" is OFF (default): Shows full planned exercises.
- When "Short on Time (APS) Toggle" is ON:
  - The app recalculates and displays a reduced set of exercises/sets (keeping primary, cutting/reducing accessories).
  - The toggle indicator remains visible (e.g., "Short on Time (APS) Toggle: ON").
  - The "Toggle APS Mode" button within the set execution becomes an intra-set pairing option, if applicable.

---

### 4. Post-Block Assessment / Analytics (Flow D & G)

A screen to assess progress and make decisions (e.g., Deload).

```
+---------------------------------------------------+
|         POST-BLOCK ASSESSMENT / ANALYTICS         |
|                                                   |
|             [ Tempo Warning Info Box ]            |
|     (e.g., "Slow eccentrics used in hypertrophy.  |
|      Consider slightly faster for practical volume")
|---------------------------------------------------|
|  Progression: Bench Press e1RM Trends             |
|  -----------------------------------------------  |
|  ^                                                |
|  |   Week 1      Week 2      Week 3      Week 4   |
|  |    (Acc)       (Int)       (Int)       (Del)  |
|  |                                                |
|  |        X---X                                   |
|  |           /                                    |
|  |          /                                     |
|  |    X----                                        |
|  +----------------------------------------------->|
|                                                   |
|---------------------------------------------------|
|  RPE Overview (Last 4 Weeks)                      |
|  -----------------------------------------------  |
|  ^                                                |
|  |   |||                                          |
|  |   ||| |||                                      |
|  |   ||| ||| |||                                  |
|  +----------------------------------------------->|
|    RPE 6-7  RPE 7.5-8.5 RPE 9-10                  |
|  "Most of your work was in the 7.5-8.5 RPE range,  |
|   suitable for hypertrophy."                      |
|                                                   |
|---------------------------------------------------|
|  Post-Block Checklist:                            |
|  [X] Sleep adequate (>=7h avg)?                   |
|  [ ] Protein intake adequate?                     |
|  [X] Stress manageable?                           |
|  [ ] Technique solid / RPE accurate?              |
|                                                   |
|  Score: 2 (Fatigued)                              |
|  Recommendation: DELOAD THIS WEEK                 |
|                                                   |
|  [ Proceed to Deload ]                            |
|                                                   |
+---------------------------------------------------+
```

---

### 5. Swap Exercise Sheet (Flow F)
This modal allows users to select a substitute exercise, with specificity insights.

```
+---------------------------------------------------+
|               SWAP EXERCISE SHEET                 |
+---------------------------------------------------+
|  Swap Exercise         [ X ] (Close)              |
|  Current: Barbell Back Squat                      |
|---------------------------------------------------|
|  Filters:                                         |
|  Movement: [Squat      ] (Locked)                 |
|  Equipment: [Any      v] (Barbell | Dumbbell |...) |
|---------------------------------------------------|
|                                                   |
|  [!] Replacing a competition lift. This may reduce|
|      specificity for strength.                    |
|                                                   |
|  +---------------------------------------------+  |
|  | Barbell Front Squat          High Specificity|  |
|  |   Barbell                                     |  |
|  +---------------------------------------------+  |
|  | Safety Bar Squat             High Specificity|  |
|  |   Barbell (Comp Lift)                         |  |
|  +---------------------------------------------+  |
|  | Hack Squat                   Medium Specificity|  |
|  |   Machine                                     |  |
|  +---------------------------------------------+  |
|  | Leg Press                    Low Specificity   |  |
|  |   Machine                                     |  |
|  +---------------------------------------------+  |
|                                                   |
+---------------------------------------------------+
```

---

### 6. Macro-cycle Timeline Screen (Flow G)
This screen visualizes the user's long-term program structure.

```
+---------------------------------------------------+
|          MACRO-CYCLE TIMELINE (OVERVIEW)          |
+---------------------------------------------------+
|                                                   |
|  [ < Prev Year ]                 [ Next Year > ]  |
|                                                   |
|  +---------------------------------------------+  |
|  | JAN   FEB   MAR   APR   MAY   JUN   JUL   AUG |  |
|  |-----|-----|-----|-----|-----|-----|-----|-----|  |
|  | Acc | Int | Rea | Acc | Del | Int | Rea | Acc |  |
|  +---------------------------------------------+  |
|                                                   |
|  -------------------------------------------------|
|                                                   |
|  Current Block: Accumulation (July 1 - Aug 15)    |
|  Focus: Higher Volume, Work Capacity              |
|  [ Edit Block ]                                   |
|                                                   |
|  +---------------------------------------------+  |
|  | Block: Intensification (Apr - Jun)          |  |
|  |   Focus: Peak Strength                      |  |
|  |   Duration: 6 Weeks                         |  |
|  +---------------------------------------------+  |
|                                                   |
+---------------------------------------------------+
```

---

### 7. Settings / Profile Screen (Data Export)
This screen provides access to user settings and data management.

```
+---------------------------------------------------+
|             SETTINGS / PROFILE SCREEN             |
+---------------------------------------------------+
|  < Back        Settings / Profile                 |
|---------------------------------------------------|
|  User Account:                                    |
|  [ Name: John Doe   > ]                           |
|  [ Goal: Strength   > ]                           |
|  [ Unit: lbs        > ]                           |
|---------------------------------------------------|
|  Data Management:                                 |
|  [ Export Training Data > ]                       |
|  "Export as JSON/CSV for backup or analysis."     |
|  [ Delete All Data    > ]                         |
|---------------------------------------------------|
|                                                   |
+---------------------------------------------------+
```
