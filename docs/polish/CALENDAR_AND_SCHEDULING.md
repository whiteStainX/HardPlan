# Polish Plan: Calendar and Interactive Scheduling

**Goal:** Implement a flexible calendar interface for scheduling and viewing workouts, allowing users to intuitively assign workout blocks to specific days via drag-and-drop, and providing visual historical data.

**Overview:**
This plan aims to replace static list-based scheduling with an interactive calendar. The core idea is to first generate a set of weekly workout "blocks" and then allow the user to drag and drop these blocks onto specific days of the week, giving them full control over their weekly training sequence. The calendar will also serve as a visual history and analytics tool.

---

## Phase 1: Basic Calendar Display (`ProgramView`)

**Action:** Replace the simple list view in `ProgramView` with a calendar displaying the generated `ActiveProgram.weeklySchedule`.

*   **Step 1.1: Create `WeeklyCalendarView.swift`**
    *   **File:** `HardPlan/App/UI/Components/WeeklyCalendarView.swift`
    *   **UI:** Create a reusable SwiftUI `View` that displays a grid-like layout for a single week (7 days). It should be configurable to start on any day of the week.
    *   **Data:** It should accept data (e.g., `[ScheduledSession]`) to display on each day.

*   **Step 1.2: Integrate into `ProgramView.swift`**
    *   **File:** `HardPlan/App/UI/Program/ProgramView.swift`
    *   **Action:** Replace the `ScrollView` and `ForEach` loop that currently lists sessions with an instance of `WeeklyCalendarView`.
    *   **Logic:** The `ProgramView` (or a `ProgramViewModel`) will pass the `appState.activeProgram.weeklySchedule` to the `WeeklyCalendarView`. Each day cell should show the `session.name` for that day.
    *   **Navigation:** Keep the `NavigationLink` functionality so tapping a session on the calendar navigates to `ProgramSessionDetailView`.

---

## Phase 2: Interactive Scheduling & Sequencing (`ScheduleView`)

**Action:** Upgrade the `ScheduleView` (used in onboarding and settings) to enable drag-and-drop assignment of workout blocks to specific days.

*   **Step 2.1: Enhance `ProgramGeneratorProtocol` & `ProgramGenerator.swift`**
    *   **Action:** Add a method (e.g., `generateWeeklyBlocks(for user: UserProfile) -> [WorkoutBlock]`) that returns the *unassigned* workout blocks for the week (e.g., "Upper A", "Lower A").
    *   **File:** `HardPlan/App/Services/Program/ProgramGenerator.swift`

*   **Step 2.2: Refactor `ScheduleView.swift`**
    *   **File:** `HardPlan/App/UI/Onboarding/ScheduleView.swift`
    *   **UI:** Replace the slider with:
        *   A `LazyVGrid` or similar layout to display the available workout blocks (from `ProgramGenerator`) as draggable items (e.g., "pills").
        *   An interactive `WeeklyCalendarView` that acts as a drop target for these blocks.
    *   **Logic:** Implement SwiftUI's `onDrag` and `onDrop` modifiers to allow users to assign blocks to days. The view model should maintain the state of assigned blocks.

*   **Step 2.3: Update `OnboardingViewModel.swift`**
    *   **Action:** Update the ViewModel's state to manage the assigned workouts for each day (e.g., `[Int: ScheduledSession]`).
    *   **Logic:** Modify the `buildProfile()` method to construct the `weeklySchedule` based on the user's drag-and-drop assignments, using the results of `ProgramGenerator.generateWeeklyBlocks`.

---

## Phase 3: Historical Data & Adherence Display

**Action:** Enhance the calendar view to visualize past workout data and adherence.

*   **Step 3.1: Extend `WeeklyCalendarView.swift`**
    *   **Action:** Modify the calendar component to also accept `workoutLogs` data.
    *   **UI:** For past days, color-code cells to indicate completed, missed, or skipped workouts.

*   **Step 3.2: Integrate into `ProgramView.swift`**
    *   **Logic:** Pass `appState.workoutLogs` to the `WeeklyCalendarView`.

---

## Phase 4: "First Day of Week" Setting

**Action:** Allow users to configure their preferred start day for the week.

*   **Step 4.1: Update `UserProfile.swift`**
    *   **Action:** Add a new property (e.g., `firstDayOfWeek: Int` where 1=Sunday, 2=Monday).

*   **Step 4.2: Create `LocaleSettingsView.swift`**
    *   **File:** `HardPlan/App/UI/Settings/Editors/LocaleSettingsView.swift`
    *   **UI:** A new reusable settings editor with a `Picker` to select the `firstDayOfWeek`.

*   **Step 4.3: Integrate into `SettingsView.swift`**
    *   **Action:** Add a `NavigationLink` to `LocaleSettingsView` in the main `SettingsView`.

*   **Step 4.4: Update Calendar & Services**
    *   **Action:** Ensure `WeeklyCalendarView` and all services that perform weekly calculations (e.g., `VolumeService`, `AnalyticsService`) use a `Calendar` instance configured with `userProfile.firstDayOfWeek`.

---
