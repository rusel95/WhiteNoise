# Refactoring Plan

Generated: 2026-02-20
Last Updated: 2026-02-24
Status: All Complete

## Progress

| Phase | Total | Done | Remaining |
|-------|-------|------|-----------|
| 1. Critical Safety | 3 | 3 | 0 |
| 2. @Observable Migration | 3 | 3 | 0 |
| 3. ViewState & State Hygiene | 3 | 3 | 0 |
| 4. Architecture & DI | 4 | 4 | 0 |
| Discovered | 10 | 10 | 0 |
| **Total** | **23** | **23** | **0** |

---

## Phase 1: Critical Safety Issues
> Goal: Eliminate thread-safety risks, Combine/Observation framework mixing, and unmanaged tasks
> PR size target: ≤200 lines changed per PR

- [x] **C1: `@StateObject` / `@ObservedObject` used with `ObservableObject` — must migrate to `@Observable` + `@State`**
  - **Location**: [ContentView.swift](WhiteNoise/Views/ContentView.swift#L12) (`@StateObject var viewModel`), [WhiteNoisesView.swift](WhiteNoise/Views/WhiteNoisesView.swift#L12) (`@ObservedObject var viewModel`), [SoundView.swift](WhiteNoise/Views/SoundView.swift#L12) (`@ObservedObject var viewModel`)
  - **Severity**: 🔴 Critical (anti-pattern C3)
  - **Problem**: `WhiteNoisesViewModel` and `SoundViewModel` are `ObservableObject` classes. Every `@Published` property change re-evaluates **all** observing views — the entire `ForEach` grid re-renders when *any* sound changes volume. Once these VMs migrate to `@Observable` (Phase 2), the current `@StateObject`/`@ObservedObject` wrappers will silently break observation tracking. This is a ticking time bomb that will cause "nothing updates" or "everything updates" bugs.
  - **Fix**: This is resolved as part of Phase 2 migration. Blocked on M1/M2 below. Listed here for severity tracking.
  - **Dependencies**: M1, M2

- [x] **C2: `SoundViewModel` imports `SwiftUI`**
  - **Location**: [SoundViewModel.swift](WhiteNoise/ViewModels/SoundViewModel.swift#L12) (`import SwiftUI`)
  - **Severity**: 🔴 Critical (anti-pattern H3)
  - **Problem**: `SoundViewModel` imports `SwiftUI` to use `withAnimation()` and `CGFloat`. This couples the ViewModel to the UI framework, making it impossible to unit test without the SwiftUI framework loaded. It also prevents sharing this VM with macOS/watchOS targets.
  - **Fix**: Remove `import SwiftUI`. Replace `CGFloat` slider properties (`sliderWidth`, `sliderHeight`, `maxWidth`, `maxHeight`, `lastDragValue`) with `Double`. Move the `withAnimation` calls into the View layer (or use a callback/published property the View observes). The ViewModel should only expose a normalized `volume: Float` (0…1) — all slider geometry is a View concern.

- [x] **C3: Heavy work in ViewModel `init` — `loadSounds()`, `setupServices()`, `setupObservers()`, `registerForCleanup()`**
  - **Location**: [WhiteNoisesViewModel.swift](WhiteNoise/ViewModels/WhiteNoisesViewModel.swift#L92-L107)
  - **Severity**: 🔴 Critical (anti-pattern M2 escalated to Critical because of `@State` lifecycle)
  - **Problem**: The `init` performs synchronous disk reads (`soundFactory.getSavedSounds()`), sets up `NotificationCenter` observers, creates Combine subscriptions, and spawns a `Task.detached` for audio preloading. With `@State` (post-migration), SwiftUI may call this initializer **multiple times** during parent redraws — each call registers duplicate observers, re-reads persistence, and spawns orphan tasks. The static `activeInstance` singleton pattern is a workaround for this, not a solution.
  - **Fix**: Make `init` lightweight (assign dependencies only). Move all setup into a `func bootstrap() async` method called via `.task { await viewModel.bootstrap() }`. Remove the static `activeInstance` singleton pattern entirely — it's a code smell from working around eager init.

---

## Phase 2: @Observable Migration
> Goal: Migrate both ViewModels from `ObservableObject` to `@Observable` (iOS 17+)
> PR size target: 1 ViewModel + its View(s) per PR

- [x] **M1: Migrate `WhiteNoisesViewModel` to `@Observable`**
  - **Location**: [WhiteNoisesViewModel.swift](WhiteNoise/ViewModels/WhiteNoisesViewModel.swift), [ContentView.swift](WhiteNoise/Views/ContentView.swift), [WhiteNoisesView.swift](WhiteNoise/Views/WhiteNoisesView.swift)
  - **Severity**: 🟡 High
  - **Problem**: `WhiteNoisesViewModel` is an `ObservableObject` with 3 `@Published` properties (`soundsViewModels`, `isPlaying`, `remainingTimerTime`). Any change to `remainingTimerTime` (every second when timer is active) triggers re-evaluation of the entire `WhiteNoisesView`, including the sound grid. With `@Observable`, only the timer label would re-render.
  - **Fix**:
    1. Replace `class WhiteNoisesViewModel: ObservableObject` → `@Observable @MainActor final class WhiteNoisesViewModel`
    2. Remove all `@Published` — use plain `var` (with `private(set)` where appropriate)
    3. Replace `@StateObject` in `ContentView` → `@State private var viewModel`
    4. Replace `@ObservedObject` in `WhiteNoisesView` → `let viewModel` (or `@Bindable` for `$viewModel.timerMode`)
    5. Remove `import Combine` if only used for `@Published` / Combine observation (keep if Combine publishers from services remain)
    6. Add `// MARK: -` sections per template
  - **Verification**: Add `Self._printChanges()` before and after. Confirm that timer ticks no longer redraw the sound grid.
  - **Dependencies**: C3 should be done first (lightweight init)

- [x] **M2: Migrate `SoundViewModel` to `@Observable`**
  - **Location**: [SoundViewModel.swift](WhiteNoise/ViewModels/SoundViewModel.swift), [SoundView.swift](WhiteNoise/Views/SoundView.swift)
  - **Severity**: 🟡 High
  - **Problem**: `SoundViewModel` is `ObservableObject` with 6 `@Published` properties. Each of 15+ `SoundView` instances observes its own VM, but any `@Published` change (e.g., `sliderWidth` during drag) causes a full `SoundView` body re-evaluation instead of just the slider track. Heavy drag-frequency updates amplify this.
  - **Fix**:
    1. Replace `class SoundViewModel: ObservableObject` → `@Observable @MainActor final class SoundViewModel`
    2. Remove all `@Published`
    3. Replace `@ObservedObject` in `SoundView` → `let viewModel` (or `@Bindable` if `$` bindings needed)
    4. Remove Combine subscriptions for `$volume` / `$selectedSoundVariant` — replace with `onChange(of:)` in View or Observation-framework `withObservationTracking` in VM
    5. Remove `import Combine` if no longer needed
  - **Dependencies**: C2 (remove SwiftUI import) should be done first
  - **Verification**: `Self._printChanges()` confirms only slider value changes trigger slider redraw, not icon/title.

- [x] **M3: Update `ContentView` and remove legacy `PreviewProvider`**
  - **Location**: [ContentView.swift](WhiteNoise/Views/ContentView.swift#L20-L24), [WhiteNoisesView.swift](WhiteNoise/Views/WhiteNoisesView.swift#L170-L175)
  - **Severity**: 🟢 Medium
  - **Problem**: Both files use the deprecated `PreviewProvider` pattern instead of the modern `#Preview` macro. `ContentView` is also a pass-through wrapper that adds no value — the app entry point could present `WhiteNoisesView` directly.
  - **Fix**: Replace `struct ContentView_Previews: PreviewProvider` with `#Preview { ... }`. Consider inlining `ContentView` into `WhiteNoiseApp.body` or keeping it as the DI composition root where dependencies are created and passed down.

---

## Phase 3: ViewState & State Hygiene
> Goal: Enforce unidirectional data flow, eliminate impossible states
> PR size target: 1 ViewModel per PR

- [x] **V1: `WhiteNoisesViewModel` — add `private(set)` to all state properties**
  - **Location**: [WhiteNoisesViewModel.swift](WhiteNoise/ViewModels/WhiteNoisesViewModel.swift#L49-L51)
  - **Severity**: 🟡 High (anti-pattern M1)
  - **Problem**: `soundsViewModels`, `isPlaying`, and `remainingTimerTime` are all publicly writable. The View (or any consumer) can directly mutate `viewModel.isPlaying = true` bypassing all the play/pause orchestration logic. This breaks unidirectional data flow and makes state changes untrackable.
  - **Fix**: Change to `private(set) var soundsViewModels`, `private(set) var isPlaying`, `private(set) var remainingTimerTime`. The only writable property from the View should be `timerMode` (via the sheet binding). For the timer sheet, expose a `func setTimerMode(_ mode:)` action method instead.

- [x] **V2: Move slider geometry out of `SoundViewModel` into the View layer**
  - **Location**: [SoundViewModel.swift](WhiteNoise/ViewModels/SoundViewModel.swift#L72-L115) (`sliderWidth`, `sliderHeight`, `lastDragValue`, `maxWidth`, `maxHeight`, `isVolumeInteractive`)
  - **Severity**: 🟡 High
  - **Problem**: Six properties related to UI geometry (`sliderWidth`, `sliderHeight`, `lastDragValue`, `maxWidth`, `maxHeight`, `isVolumeInteractive`) live in the ViewModel. These are purely **View-layer concerns** — they map a normalized 0…1 volume to pixel coordinates for a specific layout. This violates SRP, bloats the VM, and creates the SwiftUI import dependency (C2). The `withAnimation` call in `maxWidth.didSet` is a SwiftUI call inside a ViewModel.
  - **Fix**: Create a `@State` value or a small helper struct in `SoundView` that manages slider geometry. The ViewModel exposes only `volume: Float` (0…1). The View converts volume ↔ pixel width using `GeometryReader`. Remove `VolumeControlWithGestures` protocol from ViewModel — gesture callbacks belong in the View.

- [x] **V3: Replace Combine `$volume.sink` pattern with Observation-compatible approach**
  - **Location**: [WhiteNoisesViewModel.swift](WhiteNoise/ViewModels/WhiteNoisesViewModel.swift#L281-L290) (`soundViewModel.$volume.dropFirst().debounce...`), [SoundViewModel.swift](WhiteNoise/ViewModels/SoundViewModel.swift#L444-L453) (`$selectedSoundVariant.dropFirst()...`)
  - **Severity**: 🟡 High
  - **Problem**: After `@Observable` migration, `@Published` is removed, so `$volume` and `$selectedSoundVariant` Combine publishers disappear, breaking these subscriptions. Current code uses `Combine` sinks with `dropFirst()`, `debounce`, and `receive(on:)` — these need a non-Combine replacement.
  - **Fix**: For volume observation in `WhiteNoisesViewModel` → use `withObservationTracking` in a `Task` loop, or move volume-change handling to a method the View calls via `.onChange(of: soundVM.volume)`. For variant changes → same pattern. This naturally decouples observation from Combine.

---

## Phase 4: Architecture & DI
> Goal: Clean dependency injection, remove singletons, improve testability
> PR size target: ≤300 lines per PR

- [x] **A1: Replace inline singleton `HapticFeedbackService.shared` in Views**
  - **Location**: [WhiteNoisesView.swift](WhiteNoise/Views/WhiteNoisesView.swift#L15) (`HapticFeedbackService.shared`), [SoundView.swift](WhiteNoise/Views/SoundView.swift#L16) (`HapticFeedbackService.shared`)
  - **Severity**: 🟢 Medium
  - **Problem**: Views directly access `HapticFeedbackService.shared`, creating a hidden dependency that can't be mocked in SwiftUI previews or UI tests. If the haptic service ever needs configuration or A/B testing, every call site must change.
  - **Fix**: Register `HapticFeedbackServiceProtocol` via `@Entry` in `EnvironmentValues`. Views read `@Environment(\.hapticService)`. Previews and tests inject a no-op mock.

- [x] **A2: Replace optional/defaulted dependencies in `WhiteNoisesViewModel.init`**
  - **Location**: [WhiteNoisesViewModel.swift](WhiteNoise/ViewModels/WhiteNoisesViewModel.swift#L82-L87)
  - **Severity**: 🟡 High
  - **Problem**: `init` uses `?? SoundFactory()` / `?? AudioSessionService()` / `?? TimerService()` / `?? RemoteCommandService()` for defaults. This hides concrete dependencies, makes the dependency graph invisible, and creates real service instances during unit tests unless the caller remembers to inject mocks.
  - **Fix**: Make all parameters non-optional with protocol types: `init(soundFactory: SoundFactoryProtocol, audioSessionService: AudioSessionManaging, timerService: TimerServiceProtocol, remoteCommandService: RemoteCommandHandling)`. Create a convenience `static func makeDefault() -> WhiteNoisesViewModel` factory for production use. The composition root (ContentView or App) calls the factory; tests call `init` with mocks.

- [x] **A3: Split `WhiteNoisesViewModel` — file exceeds 760 lines**
  - **Location**: [WhiteNoisesViewModel.swift](WhiteNoise/ViewModels/WhiteNoisesViewModel.swift) (761 lines)
  - **Severity**: 🟡 High (anti-pattern H1)
  - **Problem**: The ViewModel handles sound collection management, timer integration, remote command handling, audio session interruption, app lifecycle, Now Playing info updates, and state synchronization — at least **6 distinct responsibilities** in a single 761-line file. This makes code review painful and increases merge conflict risk.
  - **Fix**: Split into extension files by concern:
    - `WhiteNoisesViewModel+Playback.swift` — `playSounds`, `pauseSounds`, `stopAllSounds`, fade coordination
    - `WhiteNoisesViewModel+Timer.swift` — `handleTimerModeChange`, `handleTimerExpired`, timer callbacks
    - `WhiteNoisesViewModel+RemoteCommands.swift` — remote command setup and callbacks
    - `WhiteNoisesViewModel+Lifecycle.swift` — app lifecycle observers, audio interruption, state sync
    - `WhiteNoisesViewModel+NowPlaying.swift` — `updateNowPlayingInfo`
  - Keep the core file (Properties, Init, `loadSounds`, `playingButtonSelected`) under 200 lines.

- [x] **A4: Remove `SoundCollectionManager` and `TimerIntegration` protocols from ViewModel**
  - **Location**: [WhiteNoisesViewModel.swift](WhiteNoise/ViewModels/WhiteNoisesViewModel.swift#L18-L36)
  - **Severity**: 🟢 Medium
  - **Problem**: `SoundCollectionManager` and `TimerIntegration` protocols are defined in the ViewModel file and only have one conforming type (`WhiteNoisesViewModel`). This is speculative generality — the protocols don't enable substitution or testing (tests interact with the concrete VM). They also expose mutable setters (`var soundsViewModels: [SoundViewModel] { get set }`) which weakens encapsulation.
  - **Fix**: Remove these protocols. If testability is needed, extract a proper service (e.g., `SoundPlaybackCoordinator`) that the VM delegates to — the *service* gets a protocol, the VM does not. Similarly for `VolumeControlWithGestures` and `SoundPlaybackControl` on `SoundViewModel` — remove or migrate to service protocols.

---

## Discovered Issues
> Issues found during analysis that don't fit neatly into the phases above

- [x] **D1: Excessive logging clutters codebase**
  - **Location**: Throughout [WhiteNoisesViewModel.swift](WhiteNoise/ViewModels/WhiteNoisesViewModel.swift) and [SoundViewModel.swift](WhiteNoise/ViewModels/SoundViewModel.swift)
  - **Severity**: 🟢 Medium
  - **Problem**: Both ViewModels contain dozens of `print()` statements with emoji prefixes and multi-line state dumps. While useful during debugging, these remain in production code, pollute console output, and add visual noise that makes the business logic harder to read. Some methods have more log lines than logic lines.
  - **Fix**: Replace `print()` with the project's `LoggingService` / OSLog as defined in `docs/LOGGING_STANDARD.md`. Use log levels (`debug`, `info`, `warning`, `error`) so production builds can filter appropriately. Remove redundant state-dump logs — keep only meaningful transitions.

- [x] **D2: `Sound` model is a mutable `class` — should be a `struct`**
  - **Location**: [Sound.swift](WhiteNoise/Models/Sound.swift)
  - **Severity**: 🟢 Medium
  - **Problem**: `Sound` is a reference-type `class` with mutable properties (`volume`, `selectedSoundVariant`). This means multiple parts of the code can hold a reference and mutate it unexpectedly. In the Observation framework, value-type models are preferred because mutations are tracked at the property level.
  - **Fix**: Convert `Sound` to a `struct`. Update `SoundViewModel` to own its `Sound` data as a value. Persistence writes take a snapshot rather than a shared reference. This is a larger change — evaluate after Phase 2.

- [x] **D3: `nonisolated(unsafe)` markers are tech debt for Swift 6**
  - **Location**: [WhiteNoisesViewModel.swift](WhiteNoise/ViewModels/WhiteNoisesViewModel.swift#L54-L56) (`appLifecycleObservers`, `playPauseTask`), [SoundViewModel.swift](WhiteNoise/ViewModels/SoundViewModel.swift#L63-L69) (`fadeTask`, `audioLoadingTask`, `volumePersistenceTask`)
  - **Severity**: 🟢 Medium
  - **Problem**: Five properties across two ViewModels are marked `nonisolated(unsafe)` to allow access in `deinit` (which runs outside the MainActor). While `Task.cancel()` is thread-safe, this pattern silences the compiler rather than solving the isolation issue. Swift 6 strict concurrency will flag these.
  - **Fix**: Move cleanup to a `func tearDown()` method called from the View's `.onDisappear` or use `NotificationCenter` token-based API with automatic removal for lifecycle observers. For Task properties, consider a dedicated cancellation bag pattern.

- [x] **D4: SoundView duplicated drag gesture handler (DRY violation)**
  - **Location**: [SoundView.swift](WhiteNoise/Views/SoundView.swift#L116-L128) (`volumeSlider` gesture) and [SoundView.swift](WhiteNoise/Views/SoundView.swift#L267-L279) (`variantSelector` gesture)
  - **Severity**: 🟢 Medium
  - **Problem**: The drag gesture logic (`.onChanged` and `.onEnded`) is copy-pasted identically in both `volumeSlider` and `variantSelector`. If the drag behavior changes (e.g., adding haptic feedback on thresholds), both copies must be updated in sync. This is a DRY violation.
  - **Fix**: Extract a shared `dragGesture` computed property or a `makeDragGesture()` method in `SoundView` that returns the configured `DragGesture`. Both sites call the same function.

- [x] **D5: WhiteNoisesViewModel state properties lost `private(set)` after A3 split**
  - **Location**: [WhiteNoisesViewModel.swift](WhiteNoise/ViewModels/WhiteNoisesViewModel.swift#L27-L29) (`soundsViewModels`, `isPlaying`, `remainingTimerTime`)
  - **Severity**: 🟡 High (anti-pattern M1 — public mutable state)
  - **Problem**: During A3 (file split), `private(set)` was removed from `soundsViewModels`, `isPlaying`, and `remainingTimerTime` because Swift does not allow extension files in separate `.swift` files to access `private(set)` setters. This re-opens the unidirectional data flow violation that V1 fixed — any code can now write `viewModel.isPlaying = true` directly.
  - **Fix**: Create internal mutation methods (e.g., `func setPlaying(_ value: Bool)`, `func updateRemainingTime(_ time: String)`) that extension files call instead of direct property assignment. Then restore `private(set)` on the properties. Alternatively, use `internal(set)` as a middle ground — it restricts to the module but allows cross-file extension access.

- [x] **D6: NowPlaying manual time string parsing is fragile**
  - **Location**: [WhiteNoisesViewModel+NowPlaying.swift](WhiteNoise/ViewModels/WhiteNoisesViewModel+NowPlaying.swift#L22-L28)
  - **Severity**: 🟢 Medium
  - **Problem**: `updateNowPlayingInfo()` manually parses the `remainingTime` string (e.g., "12:30") back into total seconds using `components(separatedBy: ":")` and power-of-60 math. This is fragile — it depends on the exact string format of `TimerService.remainingTime` and will break if the format changes (e.g., "1h 30m").
  - **Fix**: Add a `remainingSeconds: Int` property to `TimerServiceProtocol`. Use that directly in `updateNowPlayingInfo()` instead of reverse-parsing the display string.

- [x] **D7: RemoteCommands extension uses redundant `MainActor.run` blocks**
  - **Location**: [WhiteNoisesViewModel+RemoteCommands.swift](WhiteNoise/ViewModels/WhiteNoisesViewModel+RemoteCommands.swift#L27-L41) (`onPlayCommand`), [line 46-59](WhiteNoise/ViewModels/WhiteNoisesViewModel+RemoteCommands.swift#L46-L59) (`onPauseCommand`)
  - **Severity**: 🟢 Medium
  - **Problem**: `onPlayCommand` and `onPauseCommand` closures wrap all logic in `await MainActor.run { }`. Since `WhiteNoisesViewModel` is `@MainActor`, this hop is technically needed because the closures come from non-MainActor context — but the `strongSelf` dance is verbose and error-prone. The `onToggleCommand` already uses `Task { @MainActor in }` — inconsistent approach.
  - **Fix**: Standardize all remote command callbacks to use `Task { @MainActor [weak self] in }` pattern (matching `onToggleCommand`). Or better, mark the callback types in `RemoteCommandHandling` protocol as `@MainActor @Sendable`.

- [x] **D8: SoundView.runInitialAnimation() creates unmanaged Task**
  - **Location**: [SoundView.swift](WhiteNoise/Views/SoundView.swift#L150-L157)
  - **Severity**: 🟡 High
  - **Problem**: `runInitialAnimation()` creates a `Task { }` that is never stored or cancelled. If the SoundView disappears before the random delay (0-150ms) completes, the task will still attempt to mutate `@State` properties (`sliderWidth`, `lastDragValue`, `isInteractive`) on a potentially deallocated view. SwiftUI silently ignores stale `@State` writes, but this is technically undefined behavior and can cause warnings in strict mode.
  - **Fix**: Replace the bare `Task` with the `.task { }` view modifier using `id:` to control lifecycle, or store the task in a `@State` property and cancel it in `.onDisappear`. A simpler alternative: use `.task { try? await Task.sleep(nanoseconds: delay); withAnimation { ... } }` directly on the view.

- [x] **D9: Lifecycle extension still couples to Combine via `$isInterrupted`**
  - **Location**: [WhiteNoisesViewModel+Lifecycle.swift](WhiteNoise/ViewModels/WhiteNoisesViewModel+Lifecycle.swift#L13-L20)
  - **Severity**: 🟡 High
  - **Problem**: After the @Observable migration, `WhiteNoisesViewModel` still imports `Combine` and uses `audioService.$isInterrupted.sink { }` to observe audio interruptions. This is because `AudioSessionService` hasn't been migrated from `ObservableObject`. The `if let audioService = audioSessionService as? AudioSessionService` downcast also violates DIP — the VM casts the protocol to a concrete type to access the `$isInterrupted` publisher.
  - **Fix**: Add `var isInterrupted: Bool { get }` and an `interruptionStream: AsyncStream<Bool>` (or callback-based approach) to the `AudioSessionManaging` protocol. The VM subscribes to the protocol's stream, not the concrete class's Combine publisher. This removes the Combine dependency and the protocol downcast.

- [x] **D10: SoundViewModel.init still uses optional/defaulted DI (inconsistent with A2)**
  - **Location**: [SoundViewModel.swift](WhiteNoise/ViewModels/SoundViewModel.swift#L75-L76) (`persistenceService: SoundPersistenceServiceProtocol? = nil`)
  - **Severity**: 🟢 Medium
  - **Problem**: `SoundViewModel.init` still uses `persistenceService ?? SoundPersistenceService()` default — the same anti-pattern that A2 fixed in `WhiteNoisesViewModel`. During tests, if you forget to inject a mock, a real `SoundPersistenceService` is silently created, making tests slower and potentially flaky.
  - **Fix**: Make `persistenceService` a required non-optional parameter. Add `static func make(sound: Sound) -> SoundViewModel` factory for production use. Update `WhiteNoisesViewModel.loadSounds()` to pass the persistence service when creating child VMs.

---

## Recommended Execution Order

```
Phase 1 (3 PRs, sequential):
  PR 1: C2 — Remove SwiftUI import from SoundViewModel
  PR 2: C3 — Lightweight init + .task bootstrap for WhiteNoisesViewModel
  PR 3: C1 — (resolved by Phase 2)

Phase 2 (3 PRs, sequential):
  PR 4: M2 — Migrate SoundViewModel to @Observable
  PR 5: M1 — Migrate WhiteNoisesViewModel to @Observable
  PR 6: M3 — Clean up previews & ContentView

Phase 3 (3 PRs, can parallelize):
  PR 7: V1 — Add private(set) to all VM state
  PR 8: V2 — Move slider geometry to View layer
  PR 9: V3 — Replace Combine $volume sink with Observation

Phase 4 (4 PRs, semi-parallel):
  PR 10: A3 — Split WhiteNoisesViewModel into extensions
  PR 11: A2 — Non-optional DI with factory
  PR 12: A1 — Environment-based haptic service
  PR 13: A4 — Remove single-conformance protocols

Discovered — Priority Order:
  PR 14: D5 — Restore private(set) with internal mutation methods
  PR 15: D8 — Fix unmanaged Task in SoundView animation
  PR 16: D9 — Decouple Lifecycle from Combine $isInterrupted
  PR 17: D1 — Replace print() with structured logging
  PR 18: D4 — Extract shared drag gesture in SoundView
  PR 19: D6 — Add remainingSeconds to TimerService protocol
  PR 20: D7 — Standardize remote command callback patterns
  PR 21: D10 — Non-optional DI for SoundViewModel
  PR 22: D2 — Convert Sound to struct
  PR 23: D3 — Resolve nonisolated(unsafe) tech debt
```
