
# The Muscle & Strength Pyramid Training App

This project is a "self-correcting" training application for iOS that builds individualized resistance training programs based on the six levels of the Muscle & Strength Pyramid. Unlike static template apps, this system will adjust based on user goals, feedback (RPE), and performance to promote long-term adherence and progressive overload.

## Core Features

The application is designed around the 6 levels of the Muscle & Strength Pyramid:

1.  **Adherence:** Realistic, enjoyable, and flexible scheduling with intelligent handling for missed workouts and a "Short on Time" mode.
2.  **Volume, Intensity, Frequency (VIF):** Manages training variables with RPE-based logging, smart rest timers, and a comprehensive exercise library.
3.  **Progression:** Implements distinct, automated progression models for Novice, Intermediate, and Advanced athletes, including linear progression, wave loading, and block periodization.
4.  **Exercise Selection:** A smart substitution engine maintains specificity, while allowing for exercise variety and weak-point prioritization.
5.  **Rest & Efficiency:** Features context-aware rest timers and advanced techniques like Antagonist Paired Sets (APS).
6.  **Tempo & Technique:** Prioritizes effective training impulse with standard tempos and optional advanced notation for specific technical work.

## Analytics & Visualization

-   **Pyramid Dashboard:** A home screen that provides an at-a-glance view of weekly adherence and volume per muscle group.
-   **Progression Trends:** Tracks estimated 1-Rep Max (e1RM) over time for primary lifts.
-   **Intensity Distribution:** Visualizes training intensity via RPE heatmaps to ensure the user is training at the appropriate difficulty.
-   **Macro-Cycle Overview:** A timeline showing the long-term plan, including Accumulation, Intensification, and Taper blocks.

## Technical Architecture

The application is built using a service-oriented **MVVM (Model-View-ViewModel)** pattern with a centralized `AppState` acting as a single source of truth. This clean, layered architecture isolates the complex training logic from the UI, ensuring the core "engine" is independently testable and scalable.

-   **UI Layer:** SwiftUI
-   **State Management:** A central `AppState` object, injected as an EnvironmentObject.
-   **Service Layer:** Contains the core logic "engines" for Progression, Volume, Adherence, and Analytics.
-   **Data Layer:** Manages data persistence through repositories, abstracting the storage mechanism.
-   **Persistence:** On-device JSON files for full offline capability and user privacy.

## Development Plan

The project is structured into five distinct development phases:

1.  **Phase 1: The Foundation:** Establish the domain models and data persistence layer.
2.  **Phase 2: The Engine:** Implement the core algorithmic services, fully unit-tested.
3.  **Phase 3: The Skeleton:** Build the app's navigation, state management, and onboarding flow.
4.  **Phase 4: The Core Loop:** Develop the daily workout execution and logging experience.
5.  **Phase 5: The Feedback Loop:** Create analytics, visualizations, and the post-block assessment flow.
