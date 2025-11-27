# Phase 3: The Skeleton (State & Navigation)

**Goal:** Connect Logic to State and build the primary UI navigation.
**Output:** A functional "Shell" of the app where users can onboard and navigate empty tabs.
**Dependencies:** Phase 2 (Services).

---

## Step 3.1: The Central Store (AppState)

**Action:** Implement the ObservableObject that holds the app's "Live" data.

*   **File:** `App/Core/AppState.swift`
*   **Class:** `AppState: ObservableObject`
*   **Properties:**
    *   `@Published var userProfile: UserProfile?`
    *   `@Published var activeProgram: ActiveProgram?`
    *   `@Published var workoutLogs: [WorkoutLog]`
*   **Dependencies:** Injects `UserRepository`, `WorkoutRepository`, etc.
*   **Methods (Actions):**
    *   `loadData()`: Calls repositories to hydrate state.
    *   `onboardUser(profile: UserProfile)`: Saves profile, triggers program generation.
    *   `resetApp()`: Clears data (for debugging/settings).

---

## Step 3.2: Program Generator (The Bridge)

**Action:** A dedicated service to create the `ActiveProgram` from the `UserProfile`.

*   **File:** `App/Services/Program/ProgramGenerator.swift`
*   **Logic:**
    *   Input: `UserProfile` (Training Age, Goal, Days).
    *   Output: `ActiveProgram`.
    *   **Split Logic:**
        *   If 3 Days: Full Body Split.
        *   If 4 Days: Upper/Lower Split.
        *   If 5/6 Days: PPL or Hybrid.
    *   **Volume Logic:**
        *   Novice: 10 sets/muscle.
        *   Intermediate: 14 sets/muscle.
    *   **Exercise Selection:**
        *   Pick Tier 1 compounds for main slots.
        *   Pick Tier 2/3 for accessory slots.
        *   Reorder "Weak Points" to the top of accessory lists.

---

## Step 3.3: UI Architecture (Navigation)

**Action:** Set up the root view hierarchy.

*   **File:** `App/HardPlanApp.swift`
    *   Check `AppState.userProfile`.
    *   If `nil` -> Show `OnboardingView`.
    *   If exists -> Show `MainTabView`.
*   **File:** `App/UI/MainTabView.swift`
    *   Tabs:
        1.  **Dashboard** (Home icon)
        2.  **Program** (Calendar/List icon)
        3.  **Analytics** (Chart icon)
        4.  **Settings** (Gear icon)

---

## Step 3.4: Onboarding Flow

**Action:** Build the multi-screen setup wizard.

*   **Files:** `App/UI/Onboarding/`
    *   `OnboardingViewModel.swift`: Handles inputs, calls `AppState.onboardUser`.
    *   `WelcomeView.swift`: Introduction.
    *   `GoalSelectionView.swift`: Hypertrophy vs Strength.
    *   `ExperienceView.swift`: Training Age (Novice/Int/Adv).
    *   `ScheduleView.swift`: Days per week slider (with Warnings).
    *   `GeneratingView.swift`: Fake loading spinner while `ProgramGenerator` runs.

---

## Step 3.5: Settings & Data Management

**Action:** Allow users to view profile and reset data.

*   **Files:** `App/UI/Settings/`
    *   `SettingsView.swift`
    *   **Features:**
        *   View User Profile (Read-only for now).
        *   "Export Data" button (Calls `ExportService`).
        *   "Reset App" button (Destructive).

---

## Step 3.6: Validation

**Action:** Manual verification of the Flow.

*   **Scenario:**
    1.  Launch fresh app -> See Onboarding.
    2.  Select "Strength", "Novice", "3 Days".
    3.  Finish -> See Dashboard (Empty state).
    4.  Kill App -> Relaunch -> See Dashboard (Persistence works).
