# Backlog: Core Data Migration Plan

**Goal:** Replace the JSON file-based persistence layer with Core Data to improve performance, scalability, and querying capabilities.

**Architectural Test:** This migration will serve as a test of the current architecture. A successful migration is one where the UI and Service layers require minimal to no changes, proving the effectiveness of the Repository pattern in abstracting the data layer.

---

## Phase 1: Core Data Stack Setup

**Action:** Create the foundational Core Data components.

*   **Step 1.1: Create the Data Model (`.xcdatamodeld`)**
    *   In Xcode, create a new "Data Model" file named `HardPlan.xcdatamodeld`.
    *   Define entities that mirror our existing domain models: `UserProfileEntity`, `WorkoutLogEntity`, `ExerciseEntity`, `ScheduledSessionEntity`, `CompletedExerciseEntity`, `CompletedSetEntity`.
    *   Define attributes for each entity (e.g., `name: String`, `dateCompleted: Date`). Use appropriate Core Data types.
    *   Define relationships:
        *   `WorkoutLogEntity` <->> `CompletedExerciseEntity` (to-many)
        *   `CompletedExerciseEntity` <->> `CompletedSetEntity` (to-many)
        *   `UserProfileEntity` <->> `WorkoutLogEntity` (to-many, optional)
    *   This is the most critical step for designing the database schema.

*   **Step 1.2: Create `CoreDataController.swift`**
    *   Create a new singleton class to manage the Core Data stack. This controller will replace `JSONPersistenceController`.
    *   It will initialize an `NSPersistentContainer` with the `HardPlan` data model.
    *   It will provide a shared instance and convenient access to the main `NSManagedObjectContext` (e.g., `container.viewContext`).

---

## Phase 2: Create Managed Object Subclasses

**Action:** Generate Swift classes for our Core Data entities and add helper methods to keep our domain logic separate from the persistence framework.

*   **Step 2.1: Generate `NSManagedObject` Subclasses**
    *   Use Xcode's "Editor > Create NSManagedObject Subclass..." feature to automatically generate the Swift classes for each entity defined in Phase 1.

*   **Step 2.2: Add Domain Model Conversion Helpers**
    *   For each generated subclass (e.g., `UserProfileEntity`), create an extension.
    *   In the extension, add two methods:
        1.  `func toDomainModel() -> UserProfile`: Converts the managed object into our plain Swift `UserProfile` struct.
        2.  `func update(from domainModel: UserProfile)`: Updates the attributes of the managed object from a plain Swift `UserProfile` struct.
    *   This pattern is crucial. It ensures the rest of our app continues to work with our simple domain models and remains completely unaware of Core Data.

---

## Phase 3: Update Repositories

**Action:** This is the core of the migration. We will swap the backend logic of each repository.

*   **Step 3.1: Refactor `UserRepository.swift`**
    *   Inject the `NSManagedObjectContext` from `CoreDataController` into its `init`.
    *   **`getProfile()`:**
        *   **Old:** Decode `user_profile.json`.
        *   **New:** Create an `NSFetchRequest` for `UserProfileEntity`. Execute the fetch request on the context. If an entity is found, call `toDomainModel()` on it and return the `UserProfile` struct.
    *   **`saveProfile(_:)`:**
        *   **Old:** Encode a `UserProfile` to `user_profile.json`.
        *   **New:** Fetch the existing `UserProfileEntity` or create a new one if it doesn't exist. Call `update(from: profile)` on the entity. Call `context.save()`.

*   **Step 3.2: Refactor `WorkoutRepository.swift` & `ExerciseRepository.swift`**
    *   Apply the exact same pattern as in Step 3.1: inject the context, and replace the JSON file operations with `NSFetchRequest` and `context.save()` operations, using the conversion helpers.

---

## Phase 4: Update Dependency Injection

**Action:** Tell the app to use the new Core Data-backed repositories.

*   **Step 4.1: Update `DependencyContainer.swift`**
    *   In the `registerRepositories` method, change the registrations for `UserRepositoryProtocol`, `WorkoutRepositoryProtocol`, etc.
    *   They should now resolve to the *same* repository classes (`UserRepository`, `WorkoutRepository`), but these classes will now be initialized with the `NSManagedObjectContext` instead of the `JSONPersistenceController`.

*   **Step 4.2: Verify `AppState.swift`**
    *   No changes should be needed in `AppState`. Because it depends on the repository *protocols*, and we haven't changed them, it will automatically receive the new Core Data-backed versions via dependency injection. This will be the ultimate test of the architecture.

---

## Phase 5: Data Migration for Existing Users (Optional but Recommended)

**Action:** Implement a one-time process to move existing user data from JSON files to Core Data.

*   **Step 5.1: Implement a "First Launch" Check**
    *   In `AppState.loadData()`, add logic to check if the Core Data store is empty but old JSON files (e.g., `user_profile.json`) exist.

*   **Step 5.2: Port Data**
    *   If the condition in 5.1 is met, trigger a one-time migration function.
    *   This function will read the data from the JSON files, convert it into our domain models (`UserProfile`, `[WorkoutLog]`), and then save it using the newly updated (Core Data-backed) repositories.

*   **Step 5.3: Clean Up**
    *   After a successful migration, the old JSON files can be deleted.
