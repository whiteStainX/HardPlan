# Bug Log

## Issue: Blank Screen on App Launch

**Symptoms:**
*   App launches to a blank white screen (no UI visible).
*   Xcode console shows only `✅ HardPlanApp: Initialized.`, but not `✅ AppState: Initialized.`.
*   Debugging with background colors on root views (e.g., `ContentView`) shows that the view itself is not being displayed at all.

**Root Cause:**
A deadlock occurred during the initialization of `AppState`'s dependencies within the `DependencyContainer`.
Specifically:
1.  `AppState`'s `init` method resolves its dependencies (repositories) from `DependencyContainer.shared`.
2.  `DependencyContainer.shared`'s `registerDefaultDependencies()` method registers all services. These registrations are factory closures.
3.  When a repository (e.g., `UserRepository`) is requested via `DependencyContainer.shared.resolve()`, the `resolve()` method acquires an `NSLock`.
4.  Inside the factory closure for `UserRepository`, `self.resolve()` is called again to get its `JSONPersistenceController` dependency.
5.  This second `resolve()` call attempts to acquire the *same `NSLock`* that the first `resolve()` call is already holding.
6.  `NSLock` is not re-entrant, so the second call blocks indefinitely, leading to a deadlock and a silent crash during `AppState` initialization.

**Resolution:**
The `NSLock` in `DependencyContainer` was replaced with `NSRecursiveLock`. `NSRecursiveLock` allows the same thread to acquire the lock multiple times without causing a deadlock, which is necessary when a dependency's factory itself calls `resolve()` again to get sub-dependencies.

**Steps to Debug and Fix:**
1.  Added `print` statements to `HardPlanApp.init()` and `AppState.init()` to confirm execution flow.
2.  Temporarily modified `DependencyContainer.init()` to skip `registerDefaultDependencies()` and `AppState.init()` to use mock dependencies. This confirmed the crash was in `registerDefaultDependencies()`.
3.  Isolated `registerDefaultDependencies()` to only register `JSONPersistenceController` and repositories.
4.  Identified the deadlock by realizing `self.resolve()` calls within factory closures were attempting to re-acquire the `NSLock`.
5.  Replaced `NSLock` with `NSRecursiveLock` and re-enabled all registrations.
6.  Restored `ContentView` to its correct logic, and confirmed app launch.

---
