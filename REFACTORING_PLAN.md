# WhiteNoise — Refactoring Plan

> Generated: 2026-02-18
> Methodology: SwiftUI MVVM Architecture (iOS 17+) — Analyze & Refactor workflow
> Status: **Audit complete — no implementation started**

---

## Progress

| Phase | Total | Done | Remaining |
|-------|-------|------|-----------|
| Phase 1: Critical Fixes | 2 | 0 | 2 |
| Phase 2: @Observable Migration | 5 | 0 | 5 |
| Phase 3: ViewState & Architecture | 4 | 0 | 4 |
| Phase 4: File Splits & Cleanup | 4 | 0 | 4 |
| **Total** | **15** | **0** | **15** |

---

## Phase 1: Critical Fixes

These are compile errors or broken functionality. Fix first.

### 1.1 — Broken macOS type reference

- [ ] **Fix `WhiteNoisesViewModel.TimerMode` → `TimerService.TimerMode`**
- **Location**: `WhiteNoise/Views/WhiteNoisesView.swift:145` (`#if os(macOS)` branch)
- **Severity**: 🔴 Critical (compile error on macOS)
- **Problem**: The `#if os(macOS)` code block references `WhiteNoisesViewModel.TimerMode.allCases`, but `TimerMode` is defined on `TimerService`, not `WhiteNoisesViewModel`. This means the macOS build target will fail to compile. While the app currently ships iOS-only, this is a latent bug that blocks any macOS Catalyst or visionOS expansion.
- **Fix**: Replace `WhiteNoisesViewModel.TimerMode.allCases` with `TimerService.TimerMode.allCases`. Verify the rest of the macOS branch compiles correctly with `TimerService.TimerMode`.

### 1.2 — Broken unit test

- [ ] **Fix `TimerServiceTests` accessing non-existent property**
- **Location**: `WhiteNoiseUnitTests/TimerServiceTests.swift` (references `svc.remainingSecondsValue`)
- **Severity**: 🔴 Critical (test target won't compile)
- **Problem**: `TimerServiceTests.testStartPauseResumeStop()` accesses `svc.remainingSecondsValue`, but `TimerService` only has `private var remainingSeconds: Int`. The test cannot compile, meaning the entire unit test target is broken and CI cannot run any tests.
- **Fix**: Either expose `remainingSeconds` as `private(set) var remainingSecondsValue` on `TimerService`, or adjust the test to verify behaviour through the public `remainingTime: String` property instead. The latter is preferred — test through the public interface.

---

## Phase 2: @Observable Migration

Migrate from `ObservableObject` + `@Published` to `@Observable` macro. This is the biggest single improvement — it eliminates over-rendering and aligns with the iOS 17+ observation framework.

**Prerequisite**: Phase 1 must be complete so that tests can verify no regressions.

### 2.1 — Migrate `SoundViewModel` to @Observable

- [ ] **Replace `ObservableObject` with `@Observable` on `SoundViewModel`**
- **Location**: `WhiteNoise/ViewModels/SoundViewModel.swift:49`
- **Severity**: 🟡 High (performance, over-rendering)
- **Problem**: `SoundViewModel` conforms to `ObservableObject` with 6+ `@Published` properties (`volume`, `selectedSoundVariant`, `sliderWidth`, `sliderHeight`, `lastDragValue`, `isVolumeInteractive`). Every time any one of these changes, all views observing this ViewModel re-evaluate their entire body — even if they only read `volume`. With 15+ sounds on screen, this causes unnecessary re-renders on every drag gesture.
- **Fix**:
  1. Replace `class SoundViewModel: ObservableObject` with `@Observable @MainActor final class SoundViewModel`
  2. Remove all `@Published` annotations — plain `var` is auto-tracked
  3. Remove `import SwiftUI` (see task 3.1) — move `withAnimation` calls to the View layer
  4. In `SoundView.swift`: replace `@ObservedObject var viewModel` with `let viewModel: SoundViewModel` (or `@Bindable` if `$` bindings are needed)
  5. In `ContentView.swift` / `WhiteNoisesView.swift`: no change needed (SoundViewModels are created by WhiteNoisesViewModel and passed down)
  6. Run tests to verify no regressions
- **Max PR size**: 150 lines

### 2.2 — Migrate `WhiteNoisesViewModel` to @Observable

- [ ] **Replace `ObservableObject` with `@Observable` on `WhiteNoisesViewModel`**
- **Location**: `WhiteNoise/ViewModels/WhiteNoisesViewModel.swift:38`
- **Severity**: 🟡 High (performance, over-rendering)
- **Problem**: `WhiteNoisesViewModel` is `ObservableObject` with `@Published` properties (`soundsViewModels`, `isPlaying`, `remainingTimerTime`). Changes to any property trigger full re-evaluation of all observing views. The `remainingTimerTime` updates every second during timer countdown, causing the entire `WhiteNoisesView` (including all sound cards) to re-render every second.
- **Fix**:
  1. Replace `class WhiteNoisesViewModel: ObservableObject` with `@Observable @MainActor final class WhiteNoisesViewModel`
  2. Remove all `@Published` annotations
  3. In `ContentView.swift`: replace `@StateObject var viewModel = WhiteNoisesViewModel()` with `@State private var viewModel = WhiteNoisesViewModel()`
  4. In `WhiteNoisesView.swift`: replace `@ObservedObject var viewModel` with `let viewModel: WhiteNoisesViewModel` (or `@Bindable` if `$` bindings to ViewModel properties are used)
  5. Verify Combine `sink` subscriptions (timer, audio session) still work — `@Observable` properties are not Combine publishers, so `$property.sink` patterns must be replaced with `withObservationTracking` or callback-based approaches
  6. Run tests to verify no regressions
- **Max PR size**: 150 lines
- **Dependencies**: Task 2.1 should be done first (simpler, validates the migration pattern)

### 2.3 — Migrate `TimerService` to @Observable

- [ ] **Replace `ObservableObject` with `@Observable` on `TimerService`**
- **Location**: `WhiteNoise/Services/TimerService.swift:29`
- **Severity**: 🟡 High (consistency, over-rendering)
- **Problem**: `TimerService` is `ObservableObject` with `@Published var mode`, `@Published var remainingTime`, `@Published private(set) var isActive`. `WhiteNoisesViewModel` subscribes to these via Combine `$property.sink` to propagate timer state changes to the UI. This Combine wiring adds complexity and must be replaced during migration.
- **Fix**:
  1. Replace with `@Observable @MainActor final class TimerService`
  2. Remove `@Published` — use plain `var` / `private(set) var`
  3. Replace Combine `$property.sink` subscriptions in `WhiteNoisesViewModel` with a callback/delegate pattern or direct property reads
  4. Verify timer lifecycle (start/pause/resume/stop) still works correctly
- **Max PR size**: 150 lines
- **Dependencies**: Task 2.2 (WhiteNoisesViewModel migration defines how Combine sinks are replaced)

### 2.4 — Migrate `AudioSessionService` to @Observable

- [ ] **Replace `ObservableObject` with `@Observable` on `AudioSessionService`**
- **Location**: `WhiteNoise/Services/AudioSessionService.swift:23`
- **Severity**: 🟡 High (consistency)
- **Problem**: `AudioSessionService` uses `@Published private(set) var isInterrupted` which `WhiteNoisesViewModel` subscribes to via Combine `$isInterrupted.sink`. The interruption handling (auto-pause on phone call, auto-resume after) relies on this reactive pipeline.
- **Fix**:
  1. Replace with `@Observable @MainActor final class AudioSessionService`
  2. Remove `@Published` from `isInterrupted`
  3. Replace Combine sink in `WhiteNoisesViewModel` with callback or direct observation
  4. Test audio interruption flow: play sounds → trigger Siri/phone call → verify pause → end interruption → verify resume
- **Max PR size**: 100 lines
- **Dependencies**: Task 2.2

### 2.5 — Migrate `EntitlementsCoordinator` to @Observable

- [ ] **Replace `ObservableObject` with `@Observable` on `EntitlementsCoordinator`**
- **Location**: `WhiteNoise/Services/EntitlementsCoordinator.swift:14`
- **Severity**: 🟡 High (consistency)
- **Problem**: `EntitlementsCoordinator` uses `@Published` for `hasActiveEntitlement`, `currentOffering`, and `isPaywallPresented`. These are read by the root `RootView` via `@StateObject` and drive paywall sheet presentation.
- **Fix**:
  1. Replace with `@Observable @MainActor final class EntitlementsCoordinator`
  2. Remove `@Published`
  3. In `WhiteNoiseApp.swift`: replace `@StateObject private var entitlements` with `@State private var entitlements`
  4. In `PaywallSheetView.swift`: replace `@ObservedObject var coordinator` with `let coordinator` or `@Bindable var coordinator`
  5. Verify paywall presentation and entitlement checks still function
- **Max PR size**: 100 lines

---

## Phase 3: ViewState & Architecture Improvements

Adopt modern patterns after the @Observable migration stabilizes.

### 3.1 — Remove `import SwiftUI` from SoundViewModel

- [ ] **Move animation logic from SoundViewModel to View layer**
- **Location**: `WhiteNoise/ViewModels/SoundViewModel.swift:11` (import), lines ~89, ~104, ~224 (`withAnimation` calls)
- **Severity**: 🟡 High (testability, architecture violation)
- **Problem**: `SoundViewModel` imports `SwiftUI` solely for `withAnimation()` calls inside `maxWidth.didSet` and `maxHeight.didSet` and `handleSoundVariantChange()`. This couples the ViewModel to the UI framework, making it impossible to unit test in a pure Swift context without importing SwiftUI into the test target.
- **Fix**:
  1. Remove `import SwiftUI` from `SoundViewModel.swift`
  2. Move `withAnimation` calls to the View layer — either wrap the relevant state changes in `SoundView` with `withAnimation`, or use `.animation()` modifiers on the affected views
  3. Replace any `Image` or `Color` types in the ViewModel with plain `String` identifiers
  4. Verify animations still work correctly in the UI
- **Max PR size**: 100 lines

### 3.2 — Adopt `ViewState<T>` enum for async data

- [ ] **Replace ad-hoc loading/error handling with ViewState enum**
- **Location**: Whole codebase — primarily `WhiteNoisesViewModel`, `EntitlementsCoordinator`
- **Severity**: 🟢 Medium (code quality, impossible-state prevention)
- **Problem**: The app handles loading states ad-hoc. `EntitlementsCoordinator` has a `Bool isRefreshing`. Errors from sound loading and network calls are swallowed and sent to Sentry rather than surfaced to the UI. There's no way for views to show loading spinners or error states because no structured state type exists.
- **Fix**:
  1. Define a `ViewState<T>` enum: `.idle`, `.loading`, `.loaded(T)`, `.error(Error)`
  2. Add it to a shared file (e.g., `WhiteNoise/Models/ViewState.swift`)
  3. Adopt in `EntitlementsCoordinator` for offering/entitlement loading
  4. Optionally adopt in `WhiteNoisesViewModel` for sound loading (sounds load from local JSON, so this may be overkill — evaluate whether the added complexity is justified)
- **Max PR size**: 100 lines
- **Dependencies**: Phase 2 complete (@Observable migration)

### 3.3 — Move gesture arithmetic from SoundView to SoundViewModel

- [ ] **Extract inline tap/drag calculations to named ViewModel methods**
- **Location**: `WhiteNoise/Views/SoundView.swift:56–63` (onTapGesture), drag gesture handler
- **Severity**: 🟢 Medium (testability, SRP)
- **Problem**: `SoundView`'s `onTapGesture` and drag gesture closures contain arithmetic for computing volume from slider position (`sliderWidth / maxWidth`, clamping, etc.). This business logic is untestable in the View layer.
- **Fix**:
  1. Add methods to `SoundViewModel` like `handleTap(at: CGFloat)` and `handleDrag(translation: CGFloat)`
  2. Move the arithmetic there
  3. Call the methods from the gesture closures
  4. Add unit tests for the volume calculation edge cases
- **Max PR size**: 100 lines

### 3.4 — Add `.task { }` modifier for initial data loading

- [ ] **Replace `onAppear` with `.task` where async work is triggered**
- **Location**: `WhiteNoise/Views/WhiteNoisesView.swift`, `WhiteNoiseApp.swift:78`
- **Severity**: 🟢 Medium (lifecycle management)
- **Problem**: No `.task { }` modifier is used anywhere in the codebase. `onAppear` is used for synchronous calls (geometry updates, coordinator launch), which is acceptable. However, if any of these evolve to include async work in the future, the pattern should already be `.task` for proper lifecycle-managed cancellation.
- **Fix**:
  1. Audit all `onAppear` usages — replace with `.task` where the work is (or should be) async
  2. For `WhiteNoiseApp.swift:78` (`entitlements.onAppLaunch()`): if this method becomes async, it must use `.task`
  3. For `SoundView.swift:50-52` (geometry update): this is synchronous and can remain `onAppear`
- **Max PR size**: 50 lines

---

## Phase 4: File Splits & Cleanup

Address file size violations and code hygiene after architecture is stable.

### 4.1 — Split `WhiteNoisesViewModel` (744 lines)

- [ ] **Extract distinct feature groups into extension files**
- **Location**: `WhiteNoise/ViewModels/WhiteNoisesViewModel.swift` (744 lines)
- **Severity**: 🟡 High (maintainability, SRP violation)
- **Problem**: `WhiteNoisesViewModel` is a "God ViewModel" at 744 lines. It manages: sound loading, playback coordination (play/pause/stop all), timer integration, audio session interruption handling, remote command wiring, app lifecycle observation, Now Playing info updates, and Combine subscriptions. This is 7–8 distinct responsibilities in one class.
- **Fix**: Split into extension files by feature group:
  1. `WhiteNoisesViewModel.swift` — core state, dependencies, init (~150 lines)
  2. `WhiteNoisesViewModel+Playback.swift` — play/pause/stop coordination (~150 lines)
  3. `WhiteNoisesViewModel+Timer.swift` — timer integration, countdown display (~100 lines)
  4. `WhiteNoisesViewModel+AudioSession.swift` — interruption handling (~80 lines)
  5. `WhiteNoisesViewModel+RemoteCommands.swift` — MPRemoteCommandCenter wiring (~80 lines)
  6. `WhiteNoisesViewModel+Lifecycle.swift` — app foreground/background observation (~80 lines)
- **Max PR size**: 0 net lines (dedicated split PR, no logic changes)
- **Dependencies**: Phase 2 complete (migration may change internal structure)

### 4.2 — Split `SoundViewModel` (522 lines)

- [ ] **Extract feature groups into extension files**
- **Location**: `WhiteNoise/ViewModels/SoundViewModel.swift` (522 lines)
- **Severity**: 🟡 High (maintainability)
- **Problem**: `SoundViewModel` handles: audio player lifecycle, volume control + persistence, fade operations, sound variant selection, slider geometry calculations, and preloading. Multiple concerns in one file.
- **Fix**: Split into extension files:
  1. `SoundViewModel.swift` — core state, dependencies, init (~150 lines)
  2. `SoundViewModel+Playback.swift` — play/pause/stop, audio loading (~120 lines)
  3. `SoundViewModel+Volume.swift` — volume control, slider calculations, persistence (~120 lines)
  4. `SoundViewModel+Fade.swift` — fade in/out operations (~80 lines)
- **Max PR size**: 0 net lines (dedicated split PR)
- **Dependencies**: Tasks 2.1 and 3.1 (migration + SwiftUI import removal)

### 4.3 — Remove verbose `print()` statements

- [ ] **Replace raw print() calls with LoggingService**
- **Location**: `WhiteNoisesViewModel.swift`, `SoundViewModel.swift`, `TimerService.swift` (scattered throughout)
- **Severity**: 🟢 Medium (code hygiene)
- **Problem**: Many `print()` statements throughout the codebase are unconditional and will execute in Release builds. The project already has a `LoggingService` wrapper that respects build configuration (`#if DEBUG`), but it's not used consistently.
- **Fix**:
  1. Audit all `print()` calls across the codebase
  2. Replace with `LoggingService` equivalents using the project's emoji prefix convention
  3. Remove any debugging prints that are no longer needed
- **Max PR size**: 100 lines

### 4.4 — Expand unit test coverage

- [ ] **Add meaningful unit tests for ViewModels and Services**
- **Location**: `WhiteNoiseUnitTests/`
- **Severity**: 🟡 High (quality assurance)
- **Problem**: Test coverage is effectively zero. The single unit test file won't compile (see task 1.2). No ViewModel tests exist despite the protocol-based DI being well-suited for mocking. There are no tests for: sound loading, volume persistence, fade operations, playback coordination, remote command handling, or entitlement checks.
- **Fix** (prioritized test targets):
  1. Fix existing `TimerServiceTests` (task 1.2)
  2. Add `SoundViewModelTests` — test play/pause/volume/fade through mock `AudioPlayerProtocol`
  3. Add `WhiteNoisesViewModelTests` — test playback coordination through mock services
  4. Add `SoundPersistenceServiceTests` — test save/load with mock UserDefaults
  5. Add `FadeOperationTests` — test different fade strategies
- **Max PR size**: 200 lines per test file
- **Dependencies**: Phase 2 complete (test the final @Observable API, not the outgoing one)

---

## Discovered During Refactoring

> New findings during implementation go here with full descriptions. Do not expand the scope of an in-progress PR.

_(empty — no implementation started)_

---

## Notes

- **Minimum iOS version**: Verify the deployment target in `project.pbxproj` supports iOS 17+ before starting Phase 2. The `@Observable` macro requires iOS 17.
- **Combine removal**: The @Observable migration (Phase 2) will require replacing Combine `$property.sink` subscriptions. Plan for callback-based or `withObservationTracking`-based alternatives.
- **Phase ordering is strict**: Critical fixes → @Observable migration → ViewState/architecture → File splits. Each phase builds on the previous one.
- **PR discipline**: One task per PR, max lines as specified. New findings go to the "Discovered During Refactoring" section above, not into the current PR.
