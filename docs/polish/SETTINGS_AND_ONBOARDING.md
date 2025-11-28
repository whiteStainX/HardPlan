# Polish Plan: Comprehensive Settings & Onboarding

**Goal:** Refactor the onboarding and settings flows to be comprehensive and interactive, allowing users to configure all `UserProfile` properties both during initial setup and later from a main settings screen.

**Overview:**
The core strategy is to create a set of small, focused, and reusable "editor" views for different groups of settings. These views will be used in two places:
1.  **Onboarding:** Presented sequentially in a multi-step wizard to gather initial user data.
2.  **Settings:** Linked from a main settings screen to allow users to edit their profile at any time.

This approach ensures a consistent UI and minimizes code duplication.

---

## Phase 1: Create Reusable Setting Views

**Action:** Build the individual UI components for editing different aspects of the `UserProfile`.

*   **Step 1.1: Create `TrainingFocusView.swift`**
    *   **File:** `HardPlan/App/UI/Settings/Editors/TrainingFocusView.swift`
    *   **UI:** Create a `Form` with:
        *   A `Picker` for the `goal` property (`Goal.strength` vs. `Goal.hypertrophy`).
        *   A multi-selector view for `weakPoints` (`[MuscleGroup]`). This view should allow selecting zero or more muscle groups.
    *   **Data:** The view should accept bindings (`@Binding`) for `goal` and `weakPoints`.

*   **Step 1.2: Create `UnitSettingsView.swift`**
    *   **File:** `HardPlan/App/UI/Settings/Editors/UnitSettingsView.swift`
    *   **UI:** Create a `Form` with:
        *   A `Picker` for the `unit` property (`UnitSystem.lbs` vs. `UnitSystem.kg`).
        *   A `Stepper` or `TextField` for `minPlateIncrement`. The UI should update based on the selected unit (e.g., suggesting 2.5 for lbs and 1.25 for kg).
    *   **Data:** The view should accept bindings for `unit` and `minPlateIncrement`.

*   **Step 1.3: Refactor Existing Views (If Necessary)**
    *   **Files:** `ExperienceView.swift`, `ScheduleView.swift`.
    *   **Action:** Analyze if the existing onboarding views can be reused as-is in the `Settings` screen. If not, refactor them to be more generic, for example, by accepting `@Binding`s for their state instead of relying solely on closures.

---

## Phase 2: Enhance Onboarding Flow

**Action:** Integrate the new reusable views into the onboarding wizard to create a comprehensive setup process.

*   **Step 2.1: Update `OnboardingViewModel.swift`**
    *   Add new `@Published` properties to hold the state for the new steps (e.g., `weakPoints`, `unit`, `minPlateIncrement`).
    *   Expand the `Step` enum to include new cases for the added views (e.g., `.focus`, `.units`). Update the `progress` computed property accordingly.

*   **Step 2.2: Update `OnboardingView.swift`**
    *   Modify the `switch` statement in the `body` to include the new views (`TrainingFocusView`, `UnitSettingsView`) in the correct sequence.
    *   Wire up the `onNext` and `onBack` actions for the new steps.

*   **Step 2.3: Update `buildProfile()` Method**
    *   Modify the `buildProfile()` method in `OnboardingViewModel` to pass all the newly collected data (e.g., `weakPoints`, `unit`) when creating the final `UserProfile` object.

---

## Phase 3: Upgrade Main `SettingsView`

**Action:** Transform the read-only `SettingsView` into an interactive hub for editing the user profile.

*   **Step 3.1: Refactor `SettingsView.swift` Layout**
    *   Change the `List` from displaying `LabeledContent` to displaying `NavigationLink`s.
    *   Group links into logical `Section`s (e.g., "Training", "Preferences").

*   **Step 3.2: Implement NavigationLinks**
    *   For each section, create a `NavigationLink` that navigates to its corresponding reusable editor view (from Phase 1).
    *   **Example:** `NavigationLink("Training Focus") { TrainingFocusView(...) }`

*   **Step 3.3: Implement Data Binding**
    *   Pass bindings from the `appState.userProfile` object to the editor views. This requires making `appState.userProfile` a non-optional binding or handling the optionality gracefully.
    *   **Example:** When a user navigates to `TrainingFocusView` from Settings, the view will be bound directly to `appState.userProfile.goal` and `appState.userProfile.weakPoints`. Any changes made in the editor view will automatically update the `AppState`, and should be persisted.

*   **Step 3.4: Implement Persistence on Change**
    *   Modify `AppState` so that whenever `userProfile` is updated from a settings editor view, the new profile is automatically saved to disk (e.g., using `.onChange(of: userProfile)` in `AppState` or in the view).
