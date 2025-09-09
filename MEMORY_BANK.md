# MEMORY_BANK.md — WhiteNoise Project Memory

A living log of key facts, conventions, risks, and decisions to accelerate future work. Keep concise, append-only where possible.

## Snapshot

- Platform: iOS (Swift 5+, SwiftUI, iOS 15+). macOS guards present in UI/services.
- Architecture: MVVM + services. AVFoundation for audio. Combine for observers/debounce.
- Entry: `WhiteNoise/WhiteNoiseApp.swift`
- ViewModels: `WhiteNoise/ViewModels/WhiteNoisesViewModel.swift`, `WhiteNoise/ViewModels/SoundViewModel.swift`
- Timer: Task-based `WhiteNoise/Services/TimerService.swift` with start/pause/resume/stop, ticks via closures.
- Fades: Strategy pattern in `WhiteNoise/Strategies/*` with `FadeOperation` cancellation safety.
- Background audio: Enabled via `WhiteNoise/Info.plist` (`UIBackgroundModes: audio`) and `AudioSessionService`.
- Observability: Console logging with emojis + Sentry SDK (errors, perf, profiling).

## Build & Test

- Open: `open WhiteNoise.xcodeproj`
- Build (Debug): `xcodebuild -project WhiteNoise.xcodeproj -scheme WhiteNoise -configuration Debug build`
- Tests: Minimal UI tests in `WhiteNoiseUITests/*`; no unit tests for services/view models yet.

## Components

- App: `WhiteNoise/WhiteNoiseApp.swift` initializes Sentry (profiling enabled, tracesSampleRate=1.0) and loads `ContentView`.
- Views: Grid of `SoundView` cards in `WhiteNoise/Views/WhiteNoisesView.swift`; bottom play/pause + timer controls; `TimerPickerView` overlay.
- ViewModels:
  - `WhiteNoisesViewModel`: orchestrates multi-sound play/pause, timer integration, remote commands, app lifecycle sync.
  - `SoundViewModel`: per-sound volume, lazy audio loading, fades, variant switching, persistence updates.
- Services:
  - `AudioSessionService`: sets `.playback`, handles interruptions, ensures/reconfigures active session.
  - `AVAudioPlayerFactory`/`AVAudioPlayerWrapper`: creates looping players; formats tried in order: m4a, wav, aac, mp3, aiff, caf.
  - `TimerService`: 1s tick Task; modes from 1 minute to 8 hours; pause preserves remaining; stop resets state.
  - `RemoteCommandService`: sets up play/pause/toggle; updates MPNowPlayingInfo (optional artwork: `LaunchScreenIcon`).
  - `SoundPersistenceService`: stores `Sound` JSON per `sound_<id>` key; migration helper exposes volume + variant name.
  - `SoundConfigurationLoader`: loads `SoundConfiguration.json` → `Sound` list; applies special default volumes (rain 0.7, thunder 0.3, birds 0.2).
  - `AbstractSoundFactory`/`ConfigurationDrivenSoundFactory`: category-based providers (set fade type per category); currently not wired into main flow.

## Audio & Configuration

- Config file: `WhiteNoise/Resources/SoundConfiguration.json`
  - Note: Contains trailing commas; `JSONDecoder()` rejects; loader falls back to hardcoded minimal defaults.
  - Variants map to base filenames; `AVAudioPlayerFactory` appends supported extensions and searches bundle root.
  - Ensure Xcode “Copy Bundle Resources” flattens subfolders or pass `withSubdirectory` when looking up files.
- Assets present: waterfall (2), rain (3), fireplace (2). Others (snow, thunder, birds, sea, river, voice) have placeholder filenames like "test" and may not exist.
- Player loops forever (`numberOfLoops = -1`).

## Playback & Concurrency

- UI toggle: `WhiteNoisesViewModel.playingButtonSelected()` updates `isPlaying` immediately, runs async play/pause with debounce guard.
- Actual audio state: computed from `SoundViewModel.isPlaying && volume > 0`; `syncStateWithActualAudio()` aligns UI/timer.
- Parallelism: concurrent play/pause across sounds via `withTaskGroup`.
- Fades: `AppConstants.Animation.fadeStandard=2.0`, `fadeLong=5.0`, `fadeTimerEnd=10.0`; steps per second = 50.
- Volume changes: `SoundViewModel.volume` persisted and applied; debounced 100ms on collection side for Now Playing updates.

## Timer System

- Modes: off, 1/2/3/5/10/15/30 min, 1/2/3/4/5/6/7/8 hours.
- Ticks every 1s; `onTimerTick` fired; view model updates remaining string and Now Playing every 10s.
- Expiry: triggers `pauseSounds(fadeDuration: fadeOut)`; UI clears remaining string.
- Pause: preserves remaining; Resume: restarts Task with remaining seconds; Stop: resets to `.off` and clears state.

## Remote Commands & Now Playing

- Commands: play, pause, toggle wired to `WhiteNoisesViewModel` with extra sync to actual audio state.
- Now Playing: title = joined active sound names or "White Noise"; includes timer duration/elapsed when active.
- Artwork: attempts `UIImage(named: "LaunchScreenIcon")` → optional.

## Persistence Model

- Key: `sound_<name>`; entire `Sound` encoded/decoded.
- Migration in `SoundFactory`: applies saved volume (or 0.0 if none) and matches selected variant by name; discards loader’s default volume.
- `clearAll()`: removes all keys starting with `sound_` (unused by app logic currently).

## UI/UX Notes

- Grid: adaptive sizes per platform; dark glass morphic cards; slider is tap + drag anywhere on card.
- Haptics: iOS-only; selection feedback on timer picker changes; impact on actions.
- Styling: `View+Extensions` centralizes gradients/glass.

## Constants & Tunables

- Animation: springDuration=1.0; fades as above; `fadeSteps=50` (per-second granularity).
- Audio: `slowLoadThreshold=0.5s` logs a warning; `loopForever=-1`.
- Timer: `updateInterval=1s`; now playing update cadence = 10s.
- UI sizing: control button 50x50 (iOS); various font/icon sizes under `AppConstants.UI`.

## Error Handling & Observability

- Missing audio file: factory logs attempts; throws `.fileNotFound`; view model logs and avoids crash (player remains nil).
- Sentry: enabled with PII + profiling; use for error/perf insights. Keep DSN value out of public logs.
- Logging: follow `LOGGING_STANDARD.md` (emoji prefix, entry/exit, state snapshots for complex flows).

## Risks & Gaps

- SoundConfiguration.json invalid (trailing commas) → decoder failure → fallback sounds. Fix to use configured assets.
- Default volume policy inconsistent: loader sets per-sound defaults, but factory overrides to 0.0 when no saved value.
- Docs vs code mismatch: `PLAY_PAUSE_FLOW.md` fade durations differ from `AppConstants` (doc: 2/3/5s vs code: 2/5/10s).
- Artwork name `LaunchScreenIcon` may not exist; Now Playing will have no artwork.
- Asset bundling: filenames live under `WhiteNoise/Sounds/...`; ensure bundle flattening or adjust lookup to subdirectories.
- Race windows remain possible under extreme rapid toggles despite guards (UI immediate flip vs async audio).

## TODOs

- Fix `WhiteNoise/Resources/SoundConfiguration.json` (remove trailing commas) and ensure assets exist for all variants.
- Decide default volume behavior (honor loader defaults when no saved prefs vs force 0.0). Update `SoundFactory` accordingly.
- Reconcile fade durations across docs and `AppConstants`; consider using `fadeTimerEnd` for timer expiry.
- Add unit tests for `TimerService`, `FadeOperation`, and `SoundViewModel` fade/load paths; expand UI tests.
- Consider centralizing Now Playing time math (avoid string parsing) and expose seconds directly from `TimerService`.
- Evaluate `AppConstants.Animation.fadeStepDuration` (currently unused) vs computed step duration.
- Provide artwork asset named `LaunchScreenIcon` or parameterize via constants.
- Consider wiring `AbstractSoundFactory` categories into main flow or removing until used.

## Decisions Log

- 2025-09-09: Added `AGENT.md` and `MEMORY_BANK.md` to guide Codex usage and persist knowledge.
- 2025-09-09: Established logging, concurrency, and timer behavior snapshot in memory bank for future consistency.

## How To Update This File

- Add short entries; prefer bullets. Date-stamp notable decisions (YYYY-MM-DD).
- When adding features, record: file paths touched, constants added, behavior changes, and assumptions.
