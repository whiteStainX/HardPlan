# Phase 1: The Foundation (Domain & Data Layer)

**Goal:** Establish the "Source of Truth" and data persistence infrastructure.
**Output:** A compiling Swift project with core data models, JSON persistence, and unit tests.
**Dependencies:** None (Pure Swift/Foundation).

---

## Step 1.1: Project Initialization

**Action:** Create the physical directory structure for the project.

**Directory Tree:**
```text
/
├── HardPlan/
│   ├── HardPlanApp.swift (Entry point)
│   ├── Core/
│   │   ├── AppState.swift (Placeholder)
│   │   └── DependencyContainer.swift (Placeholder)
│   ├── Domain/
│   │   ├── Models/
│   │   │   ├── UserProfile.swift
│   │   │   ├── Exercise.swift
│   │   │   ├── Program.swift (ActiveProgram, ProgressionState)
│   │   │   ├── WorkoutLog.swift (CompletedSet, etc.)
│   │   │   └── Analytics.swift (Snapshots)
│   │   └── Enums/
│   │       ├── MuscleGroup.swift
│   │       ├── TrainingAge.swift
│   │       ├── BlockPhase.swift
│   │       └── Goal.swift
│   ├── Data/
│   │   ├── Persistence/
│   │   │   └── JSONPersistenceController.swift
│   │   ├── Repositories/
│   │   │   ├── ExerciseRepository.swift
│   │   │   ├── UserRepository.swift
│   │   │   └── WorkoutRepository.swift
│   │   └── Resources/
│   │       └── exercise_db.json
│   └── Services/ (Empty for now)
└── HardPlanTests/
    └── UnitTests/
        ├── DataTests/
        │   ├── PersistenceTests.swift
        │   └── RepositoryTests.swift
        └── DomainTests/
            └── DomainModelTests.swift
```

---

## Step 1.2: Domain Models (Structs)

**Action:** Implement Swift structs matching `design/DATA_SCHEMA.md`.
**Constraint:** All models must conform to `Codable`, `Identifiable`, and `Equatable`.

### 1.2.1 Enums
*   **File:** `App/Domain/Enums/MuscleGroup.swift`
    *   Enum: `MuscleGroup: String, Codable, CaseIterable`
    *   Cases: `quads`, `hamstrings`, `chest`, `backLats`, etc.
*   **File:** `App/Domain/Enums/TrainingAge.swift`
    *   Enum: `TrainingAge: String, Codable`
*   **File:** `App/Domain/Enums/BlockPhase.swift`
    *   Enum: `BlockPhase: String, Codable` (Include `.introductory`)

### 1.2.2 User Profile
*   **File:** `App/Domain/Models/UserProfile.swift`
    *   Struct: `UserProfile`
    *   Properties: `id`, `name`, `trainingAge`, `goal`, `availableDays`, `weakPoints`, `onboardingCompleted`, `fundamentalsStatus`, etc.

### 1.2.3 Exercise
*   **File:** `App/Domain/Models/Exercise.swift`
    *   Struct: `MuscleImpact` (muscle, factor)
    *   Struct: `Exercise`
    *   Properties: `id`, `name`, `pattern`, `type`, `equipment`, `primaryMuscle`, `secondaryMuscles`, `tier`, `isCompetitionLift`, `isUserCreated`.

### 1.2.4 Program & Progression
*   **File:** `App/Domain/Models/Program.swift`
    *   Struct: `ProgressionState` (exerciseId, currentLoad, consecutiveFails, recentRPEs...)
    *   Struct: `ScheduledExercise` (targetSets, targetReps, targetTempoOverride...)
    *   Struct: `ScheduledSession`
    *   Struct: `ActiveProgram` (currentBlockPhase, weeklySchedule, progressionData...)

### 1.2.5 Workout Logs
*   **File:** `App/Domain/Models/WorkoutLog.swift`
    *   Struct: `Tempo` (eccentric, pause, concentric...)
    *   Struct: `CompletedSet` (load, reps, rpe, tags, actualTempo...)
    *   Struct: `WorkoutLog` (mode: "normal" | "shortOnTime", exercises, sessionRPE...)

---

## Step 1.3: Persistence Layer

**Action:** Implement a generic JSON file manager.

*   **File:** `App/Data/Persistence/JSONPersistenceController.swift`
*   **Class:** `JSONPersistenceController`
*   **Responsibilities:**
    *   `save<T: Codable>(_ object: T, to filename: String)`
    *   `load<T: Codable>(from filename: String) -> T?`
    *   `delete(filename: String)`
    *   Use `FileManager.default.urls(for: .documentDirectory, ...)`
    *   Ensure thread safety (optional for Phase 1, but good practice).

---

## Step 1.4: Repositories

**Action:** Implement repositories to abstract data access.

### 1.4.1 User Repository
*   **File:** `App/Data/Repositories/UserRepository.swift`
*   **Protocol:** `UserRepositoryProtocol`
    *   `saveProfile(_ profile: UserProfile)`
    *   `getProfile() -> UserProfile?`
*   **Implementation:** `UserRepository` uses `JSONPersistenceController` to read/write "user.json".

### 1.4.2 Exercise Repository
*   **File:** `App/Data/Repositories/ExerciseRepository.swift`
*   **Protocol:** `ExerciseRepositoryProtocol`
    *   `getAllExercises() -> [Exercise]`
    *   `saveUserExercise(_ exercise: Exercise)`
*   **Implementation:**
    *   Loads built-in exercises from App Bundle (`exercise_db.json`).
    *   Loads user exercises from Documents (`user_exercises.json`).
    *   Merges lists on `getAllExercises()`.

---

## Step 1.5: Seed Data

**Action:** Create the initial database of exercises.

*   **File:** `App/Data/Resources/exercise_db.json`
*   **Content:** Valid JSON array of `Exercise` objects.
*   **Requirement:** Include at least:
    *   **Compounds:** Squat, Bench Press, Deadlift, Overhead Press, Barbell Row.
    *   **Accessories:** Leg Extension, Leg Curl, Lateral Raise, Tricep Pushdown, Bicep Curl.
    *   Ensure correct `MuscleGroup` and `MovementPattern` mappings.

---

## Step 1.6: Validation (Unit Tests)

**Action:** Verify the stack works.

*   **File:** `HardPlanTests/DataTests/RepositoryTests.swift`
*   **Test 1:** `testSaveAndLoadUserProfile()`
    *   Create a UserProfile.
    *   Save it.
    *   Load it back.
    *   Assert equality.
*   **Test 2:** `testExerciseRepositoryMergesSources()`
    *   Mock the bundle loader (or use real file).
    *   Save a "User Created" exercise.
    *   Call `getAllExercises()`.
    *   Assert result contains both built-in and user exercises.
