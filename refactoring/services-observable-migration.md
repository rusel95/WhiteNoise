# Feature: Services @Observable Migration

> **Context**: Three service classes (`TimerService`, `AudioSessionService`,
> `EntitlementsCoordinator`) still use the legacy `ObservableObject`/`@Published`
> pattern. The constitution (III) mandates modern Swift Concurrency patterns;
> the MVVM skill requires `@Observable` + `@State` for iOS 17+. The legacy
> wrappers (`@StateObject`, `@ObservedObject`, `@EnvironmentObject`) cause
> over-invalidation and are inconsistent with the ViewModels which already
> use `@Observable`.
> **Created**: 2026-03-06 | **Status**: Completed

---

## @Observable Migration

- [x] **M1: Migrate TimerService from ObservableObject to @Observable + Clock injection**
  - **Location**: `WhiteNoise/Services/TimerService.swift:31-34`
  - **Severity**: 🟡 High
  - **Problem**: `TimerService` uses `ObservableObject` with `@Published` properties
    (`mode`, `remainingTime`, `isActive`). It also uses hardcoded
    `Task.sleep(nanoseconds:)` at line 149, making timer logic untestable without
    real-time waits. Per the swift-concurrency skill Rule 7, time-dependent code
    must inject a `Clock` protocol.
  - **Fix**:
    1. Replace `ObservableObject` with `@Observable` macro
    2. Remove all `@Published` wrappers (plain stored properties)
    3. Mark callback properties with `@ObservationIgnored`
    4. Inject `any Clock<Duration>` (default `ContinuousClock()`) via init
    5. Replace `Task.sleep(nanoseconds: AppConstants.Timer.updateInterval)` with
       `clock.sleep(for: .seconds(1))`
    6. No consumer changes needed — `TimerServiceProtocol` hides the concrete type
  - **Verification**: Build succeeds, timer countdown works in app, timer pause/resume works

- [x] **M2: Migrate AudioSessionService from ObservableObject to @Observable**
  - **Location**: `WhiteNoise/Services/AudioSessionService.swift:24-25`
  - **Severity**: 🟢 Medium
  - **Problem**: `AudioSessionService` uses `ObservableObject` with one `@Published`
    property (`isInterrupted`). The `didSet` on `isInterrupted` calls
    `onInterruptionChanged?()` callback, which is the actual observation mechanism
    used by the ViewModel. The `@Published` wrapper provides no value since no view
    directly observes this service via `@ObservedObject`.
  - **Fix**:
    1. Replace `ObservableObject` with `@Observable` macro
    2. Remove `@Published` from `isInterrupted`
    3. Mark `onInterruptionChanged` and `cancellables` with `@ObservationIgnored`
    4. No consumer changes — protocol `AudioSessionManaging` hides concrete type
  - **Verification**: Build succeeds, audio interruption recovery works

- [x] **M3: Migrate EntitlementsCoordinator from ObservableObject to @Observable + update consumers**
  - **Location**: `WhiteNoise/Services/EntitlementsCoordinator.swift:14-17`,
    `WhiteNoise/WhiteNoiseApp.swift:52,58-59`,
    `WhiteNoise/Views/PaywallSheetView.swift:15`,
    `WhiteNoise/Views/SettingsView.swift:14`
  - **Severity**: 🟡 High
  - **Problem**: `EntitlementsCoordinator` uses `ObservableObject` with 3 `@Published`
    properties. Consumers use legacy wrappers: `@StateObject` in `RootView`,
    `@ObservedObject` in `PaywallSheetView`, `@EnvironmentObject` in `SettingsView`,
    `.environmentObject()` modifier in `RootView`. These are inconsistent with the
    `@Observable` pattern used by ViewModels and violate the anti-pattern C3
    (mixing frameworks).
  - **Fix**:
    1. `EntitlementsCoordinator`: `ObservableObject` -> `@Observable`, remove `@Published`
    2. `RootView`: `@StateObject` -> `@State`, `.environmentObject()` -> `.environment()`
    3. `RootView`: Add `@Bindable var entitlements = entitlements` in body for
       `$entitlements.isPaywallPresented` binding
    4. `PaywallSheetView`: `@ObservedObject var` -> `let` (no bindings needed)
    5. `SettingsView`: `@EnvironmentObject var entitlements` ->
       `@Environment(EntitlementsCoordinator.self) private var entitlements`
  - **Verification**: Build succeeds, paywall presentation works, settings reads entitlement status
