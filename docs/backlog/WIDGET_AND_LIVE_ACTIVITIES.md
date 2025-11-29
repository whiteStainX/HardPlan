# Backlog: Widgets and Live Activities

**Goal:** Create a set of dynamic and configurable Home Screen widgets to provide users with at-a-glance information about their training progress and upcoming workouts.

**Overview:**
This feature will be implemented using **WidgetKit**. To display rich visualizations, we will reuse components from **Swift Charts**. A key challenge is data sharing between the main app and the widget extension, which will be solved by using an **App Group**. For advanced functionality, like letting the user choose which chart to display, we will use **AppIntents** to create a configurable widget.

---

## Phase 1: Foundation & Data Sharing

**Action:** Set up the technical foundation for communication between the main app and the new widget.

*   **Step 1.1: Create Widget Target**
    *   In Xcode, add a new "Widget Extension" target to the project. This will create the basic files and configuration for our widget.

*   **Step 1.2: Configure App Group**
    *   In the "Signing & Capabilities" tab for both the main app and the new widget target, add the "App Groups" capability. Create and assign a new group container (e.g., `group.com.yourcompany.hardplan`).

*   **Step 1.3: Create `SharedDataController.swift`**
    *   **Action:** Create a new service responsible for writing and reading data from the shared App Group container.
    *   **Logic:** This controller will have methods like `save(_ data: Codable, to filename: String)` and `load<T: Codable>(from filename: String) -> T?`. It will get the URL for the shared container and handle the file operations.

*   **Step 1.4: Integrate into `AppState`**
    *   **Action:** The main app needs to write fresh data to the shared container whenever it changes.
    *   **Logic:** In `AppState.swift`, inject the `SharedDataController`. In methods where data is modified (e.g., `completeWorkout`, `onboardUser`, `persistActiveProgram`), add a call to `sharedDataController.save(...)` to keep the shared data up-to-date for the widget.

---

## Phase 2: "Workout Today" Widget

**Action:** Build the first, simplest widget that shows the user's next scheduled workout.

*   **Step 2.1: Implement `WorkoutTimelineProvider.swift`**
    *   **Action:** Create a `TimelineProvider` for the "Workout Today" widget.
    *   **Logic:** This provider will read the `ActiveProgram` from the shared container using the `SharedDataController`. It will find the workout scheduled for the current day and create a `TimelineEntry` containing the session details. It can schedule reloads for the start of the next day.

*   **Step 2.2: Create Widget View**
    *   **Action:** Design the SwiftUI `View` for the widget.
    *   **UI:** Implement layouts for the three widget families (`.systemSmall`, `.systemMedium`, `.systemLarge`).
        *   **Small:** Might just show the session name (e.g., "Upper Body A").
        *   **Medium:** Could show the session name and the first 1-2 exercises.
        *   **Large:** Could show the session name and a list of all exercises for the day.

---

## Phase 3: Configurable Analytics Widget

**Action:** Build a more advanced, configurable widget for displaying analytics charts.

*   **Step 3.1: Implement `AnalyticsTimelineProvider.swift`**
    *   **Action:** Create a second `TimelineProvider` for the analytics widget.
    *   **Logic:** This provider will read `AnalyticsSnapshot` data from the shared container.

*   **Step 3.2: Implement Widget Configuration (AppIntents)**
    *   **Action:** Create an `AppIntent` that defines the user-configurable options.
    *   **Options:**
        1.  `ChartType`: An enum for "e1RM Trend" vs. "Volume Distribution".
        2.  `Lift`: An entity that represents a specific exercise (e.g., Squat, Bench), which will be used for the e1RM chart.
    *   The `TimelineProvider` will receive the user's selected configuration from the intent and provide the correct data.

*   **Step 3.3: Create Chart Widget View**
    *   **Action:** Design the SwiftUI view for the analytics widget.
    *   **UI:** Reuse (or create simplified versions of) the `E1RMChart` and `RPEHeatmap` views. The view will display the correct chart based on the user's configuration from the `AppIntent`.

---

## Phase 4: Live Activities (Future Enhancement)

**Action:** A natural extension of WidgetKit is to support Live Activities during a workout.

*   **Concept:** Use Apple's `ActivityKit` framework to display a Live Activity on the Lock Screen and in the Dynamic Island while a workout session is active.
*   **UI:** The Live Activity could show a timer for the workout duration, the current exercise, and the current set/rep count.
*   **Logic:** The main app would start the Live Activity when the user begins a workout and send updates as they progress through it.

---

## Backlog: Implement Apple-Required Launch Screen

**Goal:** Provide a static, branded launch screen to comply with Apple's Human Interface Guidelines, ensuring a smooth transition from tap to app launch.

**Overview:** The Launch Screen is the very first thing a user sees when they tap your app icon. It is displayed by the operating system *while* your app's process is loading into memory. It's a static placeholder and cannot run any code, play animations, or fetch data. Its purpose is to give the user instant feedback that the app is starting, preventing a perceived delay or "cold start."

**Implementation Steps:**

*   **Step 1.1: Design a Static Launch Image**
    *   **Action:** Create a simple, static image that reflects the app's branding. This image should typically feature your app's logo on a solid background color that matches your app's primary theme.
    *   **Guidelines:** Avoid text where possible, as it doesn't scale well across different devices and orientations. Focus on bold, simple graphics.

*   **Step 1.2: Configure `LaunchScreen.storyboard`**
    *   **Action:** Open or create the `LaunchScreen.storyboard` file (usually found in the project navigator).
    *   **UI:** Use an `UIImageView` to display your designed static launch image. Ensure this image is configured with constraints (e.g., aspect fit, centered) to look good on all device sizes and orientations. You can also set a background color here.

*   **Step 1.3: Verify Display**
    *   **Action:** Thoroughly test the launch screen on various iOS devices and simulators.
    *   **Verification:** Ensure it appears correctly (no black bars, correct scaling) and provides a seamless transition to your custom `SplashScreenView` (the animated "boot sequence"). The `LaunchScreen.storyboard` should appear instantly, then the `SplashScreenView` should fade in smoothly.