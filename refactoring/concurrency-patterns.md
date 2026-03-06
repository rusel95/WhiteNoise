# Feature: Concurrency Patterns

> **Context**: Swift Concurrency audit found three patterns that need improvement:
> `nonisolated(unsafe)` on Task properties (data race risk in deinit),
> hardcoded `Task.sleep` in FadeOperation (untestable), and an untracked
> detached preload task (no cancellation on dealloc). All are best-practice
> violations, not crashes, but they block strict Swift 6 compliance.
> **Created**: 2026-03-06 | **Status**: Completed

---

## Data Race Safety

- [x] **D1: Remove nonisolated(unsafe) from Task properties in ViewModels**
  - **Location**: `WhiteNoise/ViewModels/WhiteNoisesViewModel.swift:55-59`,
    `WhiteNoise/ViewModels/SoundViewModel.swift:79-85`
  - **Severity**: 🟠 Data Race
  - **Problem**: Seven `Task<Void, Never>?` properties are marked
    `nonisolated(unsafe)` to allow `deinit` to call `.cancel()`. Since `deinit` is
    `nonisolated` and runs on an arbitrary thread, accessing these properties is
    technically a data race. TSan will flag it. In practice `Task.cancel()` is
    thread-safe and deallocation implies single ownership, so this rarely crashes —
    but it's unsound under strict concurrency.
  - **Fix**:
    1. Remove `nonisolated(unsafe)` from all Task properties
    2. Remove `deinit` task cancellation from both ViewModels
    3. Add `func cleanup()` method to `WhiteNoisesViewModel` that cancels all tasks
    4. Add `func cleanup()` method to `SoundViewModel` that cancels all tasks
    5. Call `viewModel.cleanup()` from `.onDisappear` in `ContentView`
    6. Call `soundViewModel.cleanup()` from `WhiteNoisesViewModel.cleanup()` for each child
  - **Verification**: Build succeeds, no TSan warnings, app lifecycle works correctly

## Best Practices & Testability

- [x] **P1: Inject Clock into FadeOperation for testability**
  - **Location**: `WhiteNoise/Strategies/FadeOperation.swift:137`
  - **Severity**: 🟢 Medium
  - **Problem**: `FadeOperation.performFade()` uses hardcoded
    `Task.sleep(nanoseconds:)` for fade step timing. This makes fade operations
    impossible to test deterministically — tests must wait real-time seconds for
    a fade to complete. Per swift-concurrency Rule 7, time-dependent code must
    inject a `Clock` protocol.
  - **Fix**:
    1. Add `private let clock: any Clock<Duration>` to `FadeOperation`
    2. Accept `clock` parameter in `init` with default `ContinuousClock()`
    3. Replace `Task.sleep(nanoseconds:)` with `clock.sleep(for:)`
    4. Update `SoundViewModel` to pass clock through to `FadeOperation`
  - **Verification**: Build succeeds, fade in/out works, future tests can use `ImmediateClock`

- [x] **P2: Track detached preload task for proper cancellation**
  - **Location**: `WhiteNoise/ViewModels/WhiteNoisesViewModel.swift:160-169`
  - **Severity**: 🟢 Medium
  - **Problem**: `loadSounds()` creates a `Task.detached(priority: .background)`
    for preloading audio, but the task handle is not stored. If the ViewModel is
    deallocated during preload, the task continues running (held alive by `[weak self]`
    guard, but still wastes CPU/IO). Not storing the handle also means `cleanup()`
    cannot cancel it.
  - **Fix**:
    1. Add `private var preloadTask: Task<Void, Never>?` property
    2. Store the detached task handle
    3. Cancel it in `cleanup()`
  - **Verification**: Build succeeds, preloading still works, cleanup cancels preload
