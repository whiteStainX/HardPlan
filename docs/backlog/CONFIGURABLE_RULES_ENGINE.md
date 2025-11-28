# Backlog: Configurable Rules Engine

**Goal:** Refactor the hard-coded logic within services like `ProgramGenerator` and `ProgressionService` to be configurable. This will make the app more flexible and empower advanced users to customize their training parameters.

**Overview of the Hybrid Approach:**
This feature will be implemented using a two-part hybrid approach:
1.  **Configuration Files (JSON):** All hard-coded numerical parameters ("magic numbers") like target sets, rep ranges, and multipliers will be extracted from the code into an external `program_rules.json` file. This makes tuning the app's behavior possible without a recompile.
2.  **Pluggable Strategies (Protocols):** Complex logical flows, like how to progress week-to-week or how to structure a training split, will be defined in a set of "Strategy" protocols. This allows for entirely different training philosophies to be swapped out.

The user will interact with this via a new "Training Engine" section in the Settings screen.

---

## Phase 1: Externalize "Magic Numbers" to JSON

**Action:** Decouple all hard-coded numerical parameters from the services, moving them into a single, readable configuration file.

*   **Step 1.1: Create `program_rules.json`**
    *   **File:** Create `HardPlan/App/Resources/program_rules.json`.
    *   **Structure:** Define a JSON structure with logical sections. Example:
        ```json
        {
          "volume": { "novice_target_sets": 10, "intermediate_target_sets": 14 },
          "reps": { "strength_primary": 5, "hypertrophy_primary": 8 },
          "rpe": { "strength_target": 8.0, "hypertrophy_target": 7.5 }
        }
        ```

*   **Step 1.2: Create `Rulebook.swift`**
    *   **File:** `HardPlan/App/Domain/Models/Rulebook.swift`
    *   **Action:** Create a set of `Codable` structs that mirror the structure of `program_rules.json`.
    *   Create a `Rulebook` class responsible for loading and parsing the JSON file. This class will provide simple, typed access to all rule values (e.g., `rulebook.volume.noviceTargetSets`).

*   **Step 1.3: Create `RulebookProvider` Service**
    *   **File:** `HardPlan/App/Services/RulebookProvider.swift`
    *   **Action:** Create a service responsible for providing a single, shared `Rulebook` instance to the rest of the app. Register this provider in the `DependencyContainer`.

*   **Step 1.4: Refactor Services to Use the Rulebook**
    *   **Files:** `ProgramGenerator.swift`, `ProgressionService.swift`.
    *   **Action:** Inject the `RulebookProvider` into the `init` of any service that needs it.
    *   Replace all hard-coded numbers with values fetched from the `rulebook` (e.g., replace `return 14` with `return rulebook.volume.intermediateTargetSets`).

---

## Phase 2: Expand the Strategy Pattern

**Action:** Make complex logical flows, like program splits, swappable using protocols.

*   **Step 2.1: Introduce `SplitStrategyProtocol`**
    *   **File:** `HardPlan/App/Services/Program/Splits/SplitStrategy.swift`
    *   **Action:** Define a new `protocol SplitStrategyProtocol` with a method like `generateSessionPlans(for user: UserProfile, using rulebook: Rulebook) -> [SessionPlan]`.

*   **Step 2.2: Create Concrete Split Strategies**
    *   **Files:** `FullBodySplitStrategy.swift`, `UpperLowerSplitStrategy.swift`, etc.
    *   **Action:** Create concrete `struct`s that conform to `SplitStrategyProtocol`. The logic currently in `ProgramGenerator`'s `buildSessionPlans` method will be moved into these discrete strategy structs.

*   **Step 2.3: Refactor `ProgramGenerator` to Use `SplitStrategy`**
    *   **Action:** The `ProgramGenerator` will now be initialized with a `SplitStrategy`. Its `generateProgram` method will no longer decide which split to use; it will simply call `splitStrategy.generateSessionPlans(...)`.

---

## Phase 3: UI for Configuration

**Action:** Expose these new configuration options to the user in the Settings screen.

*   **Step 3.1: Create `TrainingEngineSettingsView.swift`**
    *   **File:** `HardPlan/App/UI/Settings/Editors/TrainingEngineSettingsView.swift`
    *   **UI:** A new settings view with:
        *   A `Picker` to select the active `ProgressionStrategy`.
        *   (Optional) A `Picker` to override the `SplitStrategy`.

*   **Step 3.2: Implement Advanced Rules Editor & Import/Export**
    *   **UI:** A "power user" view that displays the raw values from `program_rules.json` and allows them to be edited.
    *   **Logic:** Implement file import/export functionality for the `program_rules.json` file, allowing users to share their custom rule sets.

*   **Step 3.3: Update `SettingsView.swift`**
    *   **Action:** Add a `NavigationLink` to the new `TrainingEngineSettingsView` from the main `SettingsView`.
