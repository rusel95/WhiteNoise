# Development Principles & Checklist

This guide replaces the missing reference that other docs point to. Use it as a pre-flight checklist before shipping changes to the WhiteNoise app.

## Core Engineering Principles
- **SOLID**: Keep responsibilities focused (ViewModels handle orchestration, services handle IO, views render). Introduce protocols when mocking or extending behaviour.
- **DRY & KISS**: Reuse helpers in `AppConstants`, `FadeOperation`, and services rather than duplicating tweaks in-line. Avoid speculative complexity—ship the simplest working solution first.
- **YAGNI**: Remove dead abstractions (e.g., unused factories) and avoid adding new protocols/classes until a second concrete need appears.
- **Document Decisions**: Append `MEMORY_BANK.md` with key deltas (date, files touched, behaviour changes) whenever you make notable adjustments.

## SwiftUI & MVVM Expectations
- Views stay declarative; avoid embedding side effects directly in views. Route actions to the owning `ViewModel`.
- Use `@StateObject` for view models created inside a view (`ContentView`), `@ObservedObject` when injected (`WhiteNoisesView`, `SoundView`).
- UI updates must happen on the main actor; keep asynchronous work in services or dedicated tasks.

## Concurrency Guardrails
- Annotate stateful types with `@MainActor` if they mutate UI-facing properties.
- Cancel tasks you spawn (`Task` handles, `FadeOperation.cancel()`) before replacing them.
- Bounce heavy work (file IO, AVAudioPlayer instantiation) to background priorities via `Task.detached`/`withTaskGroup` and hop back to the main actor for state updates.
- When capturing `self` inside async closures, prefer `[weak self]` and bail early if the owner disappeared.

## Audio, Timer, and Remote Command Rules
- Always call `audioSessionService.ensureActive()` before starting playback to keep background audio entitlement alive.
- Do not talk to `AVAudioPlayer` directly from UI objects—go through the `AudioPlayerProtocol` and factory to preserve testability.
- Honour fade durations defined in `AppConstants.Animation`; keep docs in sync if you change them.
- Manage timer lifecycle exclusively via `TimerService` (start, pause, resume, stop). Avoid creating ad-hoc timers inside view models.
- Remote command callbacks should funnel through `WhiteNoisesViewModel` helpers so lock screen interactions stay in parity with UI controls.

## Logging & Telemetry Discipline
- Follow `docs/LOGGING_STANDARD.md` prefixes and message patterns. Log method entry (`🎯`), state changes (`🔄`), warnings (`⚠️`), and errors (`❌`).
- Avoid logging sensitive info such as access tokens or personal data. Keep Sentry DSN values in `Configuration/Local.xcconfig`, not in code.

## UI & Haptics
- Use gradients and glass morphism helpers from `AppConstants`/`View+Extensions.swift` for consistency.
- Gate haptics behind `#if os(iOS)` (already handled in `HapticFeedbackService`). Callers should still consider fallback behaviour when running on macOS Catalyst.
- Keep adaptive grid breakpoints in sync with design requirements; update `AppConstants.UI` when adjusting layout.

## Testing Expectations
- Prefer protocol-driven dependencies so you can inject stubs (`AudioPlayerFactoryProtocol`, `SoundPersistenceServiceProtocol`, etc.).
- When testing main-actor types, use `MainActor.run { ... }` to drive state and assertions as demonstrated in `TimerServiceTests`.
- Add regression tests to `WhiteNoiseUnitTests` whenever you change timer logic, fade operations, or persistence behaviour.
- Validate UI flows manually: play/pause toggles, timer selections, remote commands, audio interruption recovery, and variant selection.

## Pull Request Checklist
1. **Scope**: Confirm you touched only files related to the change; leave unrelated formatting alone.
2. **Implementation**:
   - Dependencies injected via protocols where practical.
   - Tasks cancelled or awaited appropriately.
   - Error branches log meaningful diagnostics.
3. **Validation**:
   - `xcodebuild -project WhiteNoise.xcodeproj -scheme WhiteNoise build`
   - `xcodebuild test -project WhiteNoise.xcodeproj -scheme WhiteNoise -destination 'platform=iOS Simulator,name=iPhone 15'` or `bash scripts/test.sh`
   - Manual walkthrough of affected flows.
4. **Docs**: Update README/architecture docs/memory bank if behaviour or assumptions changed.
5. **Post-merge**: Monitor Sentry for new regressions, especially around audio session and timer lifecycles.

Keep this file current as conventions evolve. When guidelines change, summarise the update (with a date) in `MEMORY_BANK.md` under “Decisions Log”.
