# Master Development Plan
## The Muscle & Strength Pyramid Training App

**Status:** Planning
**Platform:** iOS 16+ (SwiftUI)
**Architecture:** Service-Oriented MVVM with Central AppState

This document outlines the high-level phases for building the application. Each phase is designed to be a self-contained milestone with specific deliverables and validation steps, ensuring a robust and testable codebase.

---

### Phase 1: The Foundation (Domain & Data Layer)
**Goal:** Establish the "Source of Truth" and data persistence infrastructure.
**Focus:** Pure Swift, Data Modeling, JSON Persistence.

*   **Step 1.1:** Project Initialization (Directory Structure, Git Setup).
*   **Step 1.2:** Domain Modeling (Implement `DATA_SCHEMA.md` structs: `UserProfile`, `Exercise`, etc.).
*   **Step 1.3:** Persistence Layer (Generic `JSONPersistenceController`).
*   **Step 1.4:** Repositories (`ExerciseRepository`, `UserRepository`).
*   **Step 1.5:** Seed Data Generation (Create `exercise_db.json`).
*   **Validation:** Unit tests verifying saving/loading of User Profiles and reading Exercises from the bundle.

### Phase 2: The Engine (Service Layer)
**Goal:** Implement the Logic "Brain" completely decoupled from the UI.
**Focus:** Algorithms, Strategy Pattern, 100% Unit Test Coverage.

*   **Step 2.1:** `VolumeService` (Implement the Overlap Rule & Muscle Mapping).
*   **Step 2.2:** `ProgressionService` (The core engine).
    *   Implement `NoviceStrategy`.
    *   Implement `IntermediateStrategy` (Waves).
    *   Implement `AccessoryStrategy` (Double Progression).
*   **Step 2.3:** `AdherenceService` (Date logic, Missed Workout handling).
*   **Step 2.4:** `SubstitutionService` (Specificity scoring & filtering).
*   **Validation:** Extensive Unit Test suite feeding input states and asserting correct target outputs (loads/reps) according to `ALGORITHM_SPEC.md`.

### Phase 3: The Skeleton (State & Navigation)
**Goal:** Connect Logic to State and build the primary UI navigation.
**Focus:** AppState, SwiftUI Navigation, Onboarding Flow.

*   **Step 3.1:** `AppState` (The Central Store).
*   **Step 3.2:** Main Tab/Navigation Architecture.
*   **Step 3.3:** Onboarding Flow (UI + ViewModel).
    *   Training Age, Goal, Schedule configuration.
    *   Program Generation logic integration.
*   **Validation:** User can launch app, complete onboarding, and the app persists their profile and generated program split.

### Phase 4: The Core Loop (Execution & Logging)
**Goal:** Enable the daily training experience.
**Focus:** Dashboard, Workout View, Live Timer, Logging.

*   **Step 4.1:** Dashboard View (Adherence Ring, Volume Equator, Next Workout Card).
*   **Step 4.2:** Workout Session View.
    *   Exercise List.
    *   Set Logger (Load/Reps/RPE).
    *   Rest Timer & APS Toggle.
*   **Step 4.3:** Post-Workout Logic (Saving logs, Updating Progression State).
*   **Validation:** User can start today's session, log all sets, complete the workout, and see the Dashboard update with new adherence stats.

### Phase 5: The Feedback Loop (Analytics & Polish)
**Goal:** Provide long-term value and visualization.
**Focus:** Charts, Assessments, Export, Refinement.

*   **Step 5.1:** Analytics Service & Snapshots.
*   **Step 5.2:** Charts & Visuals (Swift Charts for e1RM, Volume).
*   **Step 5.3:** Post-Block Assessment Flow (Deload Logic).
*   **Step 5.4:** Data Export (JSON/CSV).
*   **Step 5.5:** User-Defined Exercises & Settings.
*   **Validation:** User can complete a block, trigger an assessment, view their long-term trends, and export data.

---

### Execution Strategy
*   **Modular:** Each phase builds on the previous one.
*   **Test-First:** Logic in Phase 2 is tested before UI in Phase 4 is built.
*   **Tools:** Xcode for Preview, CLI for generation, GitHub for version control.
