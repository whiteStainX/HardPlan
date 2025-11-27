# Technical Architecture & Design
## The Muscle & Strength Pyramid Training App

**Version:** 0.1
**Purpose:** Defines the high-level software architecture, ensuring clean separation of concerns, testability, and scalability for future algorithm additions.

---

### 1. Architectural Pattern: Service-Oriented MVVM with Central State

The application follows a layered architecture, prioritizing the isolation of "Pyramid Logic" from the UI and Data persistence. This ensures that the mathematical models (Volume, Progression, Adherence) can be developed and tested independently of the SwiftUI views.

#### High-Level Diagram

```
+----------------+       +---------------+       +---------------+
|   UI Layer     |----->|  ViewModels   |----->| Central AppState|
|   (SwiftUI)    |       +---------------+       +---------------+
+----------------+                                       |
                                                         |
                                                         |
          +-----------------+                      +----------------+
          |  Service Layer  |<---------------------| Data Repositories|
          | (Logic Engines) |                      +----------------+
          +-----------------+                              |
                   |                                       |
                   |                                       |
                   V                                       V
          +-----------------+                      +----------------+
          |  Domain Models  |<---------------------| Persistence    |
          |    (Structs)    |                      | (JSON)         |
          +-----------------+                      +----------------+
```

---

### 2. The Layers

#### A. Domain Layer (The "What")
*   **Role:** Defines the core data structures and types.
*   **Components:** Swift structs matching `DATA_SCHEMA.md`.
    *   `UserProfile`, `Exercise`, `WorkoutLog`, `ActiveProgram`.
    *   Enums: `MuscleGroup`, `BlockPhase`, `TrainingAge`.
*   **Dependency:** Pure Swift. No dependencies.

#### B. Service Layer (The "Brain" / Core Logic)
*   **Role:** Implements the business rules and algorithms defined in `ALGORITHM_SPEC.md`.
*   **Key Components:**
    *   **`ProgressionService`:** The primary engine. Uses the **Strategy Pattern** to switch between `NoviceStrategy`, `IntermediateStrategy`, and `DoubleProgressionStrategy`.
    *   **`VolumeService`:** Implements the "Overlap Rule" to calculate muscle group set counts.
    *   **`AdherenceService`:** Handles calendar logic, missed workout shifting, and volume reduction for combined sessions. When a user activates “Short on Time” (APS mode), the service retains all primary/competition sets, optionally trims or removes accessories based on priority tiers, adjusts the volume for the current session only, and records which sets were dropped.
    *   **`SubstitutionService`:**
        *   Input: current `Exercise`, goal (strength/hypertrophy), available equipment, user exclusions.
        *   Output: list of candidate substitutions with a **specificity score**.
        *   Strength goal: explicit rule that swapping away from competition lifts lowers specificity and should trigger a warning (which the UI can display).
        *   Filters exercises based on equipment, injury, and tier (Level 4).
    *   **`AnalyticsService`:**
        *   Reads from `ActiveProgram`, `WorkoutLog`, and `Exercise` data.
        *   Computes: e1RM time series, RPE distribution, block/phase timelines.
        *   Returns lightweight DTOs that the UI can render as charts.
    *   The service checks user-defined tempo overrides. If a majority of working sets in a hypertrophy block use very slow eccentrics (e.g., ≥ 5 seconds), it adds a warning flag to the session / block summary, suggesting more moderate tempos for practical volume.
*   **Testing:** This layer requires 100% Unit Test coverage.

#### C. Data Layer (The "Source of Truth")
*   **Role:** Manages persistence and data retrieval.
*   **Components:**
    *   **`JSONPersistenceController`:** Generic FileManager wrapper for reading/writing codable objects to documents directory.
    *   **`Repository` Protocols:** 
        *   `UserRepository`: `saveProfile()`, `loadProfile()`.
        *   `WorkoutRepository`: `saveLog()`, `getHistory()`.
    *   **`ExerciseRepository`:**
        *   Reads **built-in exercises** from bundled JSON (`exercise_db.json`).
        *   Reads / writes **user exercises** from a writable JSON file (`user_exercises.json`).
        *   Exposes a unified API (`allExercises()`, `createUserExercise(...)`, `updateUserExercise(...)`, `deleteUserExercise(id)`).
        *   Ensures that each `Exercise` instance has `isUserCreated: Bool`.
    *   **`ExportService`:**
        *   Reads the user’s `ActiveProgram`, `WorkoutLog`, and `UserProfile`.
        *   Generates a JSON and/or CSV export (e.g., one file per workout log type).
        *   Provides the export data to the UI for sharing / saving via the iOS share sheet.
*   **Decision:** Abstraction via Repositories allows future migration to CoreData or SwiftData without breaking the Logic Layer.

#### D. State Management (The "Glue")
*   **Role:** Holds the "live" application state in memory and reacts to changes.
*   **Component:** `AppState` (Singleton/EnvironmentObject).
    *   Holds `@Published var currentUser: UserProfile?`
    *   Holds `@Published var activeProgram: ActiveProgram?`
    *   `AppState` tracks a **current session mode** (`normal` vs `shortOnTime`) which is passed to the relevant service when generating the active session.
    *   `AppState` may cache computed analytics (e.g., e1RM trends, RPE distributions) in per-lift `AnalyticsSnapshot` structures. These are refreshed when new workouts are saved or when the user completes a block.
    *   Injected into the SwiftUI Environment. ViewModels read from here.

##### Store-like AppState
`AppState` acts as an application store. It exposes methods that represent user actions (e.g., `startWorkout(sessionId)`, `completeSet(setId, actualReps, actualLoad, rpe)`, `skipWorkout(sessionId)`). These methods delegate to the Service layer to compute the new targets / schedule and then update the state (`activeProgram`, `workoutLogs`, `analyticsSnapshots`, etc.).

SwiftUI views do not contain training logic; they only:
- observe `AppState` for reactive state,
- invoke these AppState methods in response to user interaction.

#### E. UI Layer (The "Face")
*   **Role:** Visualization and Interaction.
*   **Pattern:** MVVM (Model-View-ViewModel).
    *   **Views:** Dumb SwiftUI components (e.g., `RingChart`, `ExerciseRow`).
    *   **ViewModels:** specialized objects for screens (e.g., `OnboardingViewModel`, `WorkoutSessionViewModel`) that call Services and update the AppState.

---

### 3. Key Design Decisions

#### 3.1 Centralized State (`AppState`)
*   **Rationale:** A change in one part of the app (e.g., logging a workout) affects multiple other parts immediately (Adherence Score updates, Schedule shifts, Volume Equator changes). A central `AppState` acts as the single source of truth, preventing sync bugs between disconnected ViewModels.

#### 3.2 Strategy Pattern for Logic
*   **Rationale:** The app needs to support different progression logic (Novice vs. Intermediate) and may add more in the future (e.g., Undulating Periodization).
*   **Implementation:**
    ```swift
    protocol ProgressionStrategy {
        func calculateNextTarget(current: ProgressionState, log: WorkoutLog) -> ProgressionState
    }
    
    class NoviceStrategy: ProgressionStrategy { ... }
    class IntermediateStrategy: ProgressionStrategy { ... }
    ```
*   **Benefit:** We can unit test `NoviceStrategy` in isolation without setting up a full UI.

#### 3.3 Protocol-Oriented Services
*   **Rationale:** To allow for "Mocking" in tests and previews.
*   **Implementation:** ViewModels will depend on `Protocol` types (e.g., `ProgressionServiceProtocol`), not concrete classes. This allows us to inject a `MockProgressionService` for SwiftUI Previews.

---

### 4. Directory Structure

```
/App
  /Domain          (Structs & Enums)
  /Data            (Repositories & JSON Managers)
  /Services        (The Logic Engines)
    /Progression
    /Volume
    /Adherence
  /Core            (AppState & Dependency Injection)
  /UI              (SwiftUI Views & ViewModels)
    /Onboarding
    /Dashboard
    /Workout
    /Components    (Shared UI elements like Rings/Charts)
```
