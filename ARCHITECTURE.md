# WhiteNoise Architecture

This document captures how the WhiteNoise app is structured today so new contributors can understand the moving parts quickly. Treat it as an overview that complements the implementation details in the source tree and deeper dive docs such as `PLAY_PAUSE_FLOW.md` and `LOGGING_STANDARD.md`.

## System Overview
- **Platform**: Swift 5+, SwiftUI, iOS 15+ (macOS adaptations exist behind platform checks).
- **Pattern**: MVVM with service objects for audio, timer, persistence, remote commands, and haptics.
- **Key Feature Set**: Ambient sound mixing with per-sound volume, fade control, configurable sleep timer, background playback, and lock-screen/Control Center integration.
- **Observability**: Heavy inline logging (emoji-prefixed) plus Sentry for crash/perf telemetry.

```
WhiteNoiseApp → ContentView → WhiteNoisesView
                              │
                              ▼
                     WhiteNoisesViewModel
         ┌──────────────┴──────────────┐
         ▼                             ▼
 SoundViewModel (per sound)      TimerService
         │                             │
         ▼                             ▼
  Audio services & fades       RemoteCommandService
         │                             │
         └── Persistence ──────► NowPlaying info
```

## Module Map
- `WhiteNoise/Views`: SwiftUI surfaces (`ContentView`, `WhiteNoisesView`, `SoundView`, `TimerPickerView`).
- `WhiteNoise/ViewModels`: `WhiteNoisesViewModel` orchestrates the feature; `SoundViewModel` owns per-sound playback and volume gestures.
- `WhiteNoise/Services`: Reusable services (`AudioSessionService`, `AVAudioPlayerFactory`, `SoundConfigurationLoader`, `SoundFactory`, `SoundPersistenceService`, `TimerService`, `RemoteCommandService`, `HapticFeedbackService`).
- `WhiteNoise/Strategies`: Fade strategy + context classes used by `SoundViewModel`.
- `WhiteNoise/Models`: `Sound` model with nested `SoundVariant` and icon definitions.
- `WhiteNoise/Constants`: Centralised layout, animation, audio, timer constants via `AppConstants`.
- `WhiteNoise/Sounds`: Bundled audio assets plus `SoundConfiguration.json` that seeds the catalogue.
- Tests: `WhiteNoiseUnitTests` (timer lifecycle coverage) and `WhiteNoiseUITests` (template UI tests).

## App Lifecycle & Primary Flow
1. **Launch**: `WhiteNoiseApp` configures Sentry and instantiates `ContentView`.
2. **Composition**: `ContentView` creates a `WhiteNoisesViewModel` and renders `WhiteNoisesView`.
3. **Grid Rendering**: `WhiteNoisesView` builds a lazy adaptive grid of `SoundView` instances, each bound to a `SoundViewModel`.
4. **User Interactions**:
   - Play/Pause toggles call `WhiteNoisesViewModel.playingButtonSelected()`, which immediately flips `isPlaying` for UI responsiveness, then fires async play/pause tasks with fade coordination.
   - Volume drags operate entirely inside `SoundViewModel`, updating the audio player, persisting to UserDefaults, and animating the slider geometry.
   - Timer sheet writes through `timerMode` binding, which the view model translates into `TimerService` operations and optional auto-play triggers.
5. **Background & Remote Control**: `RemoteCommandService` wires MPRemoteCommandCenter play/pause/toggle callbacks back into the view model and keeps Now Playing metadata in sync with active sounds/timer state.
6. **Timer Expiry**: `TimerService` invokes `onTimerExpired` which in turn calls `WhiteNoisesViewModel.pauseSounds(fadeDuration: fadeOut)`.
7. **Paywall Enforcement**: RevenueCat checks subscription entitlements on launch/foreground; when inactive, the app presents a RevenueCat Paywall full-screen and locks playback until the user starts the 30-day trial or renews the quarterly subscription.

## Services at a Glance
| Service | Responsibility | Key Interactions |
| --- | --- | --- |
| `AudioSessionService` | Configure and re-activate the shared audio session; watch for interruptions. | `WhiteNoisesViewModel` ensures activation before playback and resumes after app foregrounding. |
| `AVAudioPlayerFactory` / `AVAudioPlayerWrapper` | Locate bundled audio (`m4a`, `wav`, `aac`, `mp3`, `aiff`, `caf`), hydrate `AVAudioPlayer`, and expose a protocol-friendly wrapper. | `SoundViewModel` requests players lazily, enabling DI for testing. |
| `SoundConfigurationLoader` | Decode `SoundConfiguration.json` into `Sound` + `SoundVariant` instances, applying default volume knobs for rain/thunder/birds. | `SoundFactory` uses the loader when building the initial catalogue. |
| `SoundFactory` | Compose fresh `Sound` models by merging loader defaults with persisted user preferences. | `WhiteNoisesViewModel.loadSounds()` seeds each `SoundViewModel`. |
| `SoundPersistenceService` | Serialize/deserialize individual `Sound` entries in `UserDefaults` under `sound_<id>`. | `SoundViewModel` saves after every volume edit and variant change. |
| `TimerService` | Task-based countdown with pause/resume semantics and 1 s tick callbacks. | `WhiteNoisesViewModel` delegates timer mode changes, receives tick/expiry events for UI + Now Playing updates. |
| `RemoteCommandService` | Register play/pause/toggle handlers, manage Now Playing metadata (title, timer progress, optional artwork). | Hooks to `WhiteNoisesViewModel` closures for remote control parity. |
| `HapticFeedbackService` | Thin wrapper around UIKit feedback generators (iOS only). | Timer picker & variant menu interactions trigger haptics. |
| `FadeOperation` + `FadeStrategy` | Strategy-based fade-in/out using cooperative cancellation, 50 steps per second. | `SoundViewModel` cancels/restarts fades during play/pause/refresh flows. |

## Data & Persistence
- `Sound` objects include a human-readable `name`, icon enum (system/custom), `volume`, selected `SoundVariant`, and available variants.
- `SoundConfiguration.json` (bundled in `WhiteNoise/Sounds/`) seeds the master list; ensure the file is valid JSON and added to the Xcode "Copy Bundle Resources" phase so `Bundle.main.url(...)` can resolve it.
- User preferences are saved per sound. Only `volume` and `selectedSoundVariant` are persisted; the loader’s default volume is overridden when no preference exists.
- Timer state lives entirely within `TimerService` and is not persisted between launches.

## Concurrency Boundaries
- `WhiteNoisesViewModel`, `SoundViewModel`, `TimerService`, and `AudioSessionService` are `@MainActor` to guard UI state.
- Play/pause fan out across sounds via `withTaskGroup`, allowing concurrent fades without blocking the main actor longer than necessary.
- Long-running or blocking audio initialisation is pushed off-thread (`Task.detached`) inside `AVAudioPlayerFactory` before rejoining the main actor.
- All asynchronous tasks are cancelled on deinit to avoid leaks or stray state mutations.

## Background Audio & Remote Commands
- Info.plist sets `UIBackgroundModes = audio`, enabling playback outside the foreground.
- `RemoteCommandService` attaches to Control Center / lock screen commands and keeps Now Playing info fresh. The default artwork name (`LaunchScreenIcon`) must correspond to an asset to display; otherwise the system falls back to a generic icon.

## Logging & Diagnostics
- Extensive emoji-prefixed logging captures entry/exit, state transitions, and timer ticks. Refer to `LOGGING_STANDARD.md` before adding new logs to keep the format consistent.
- Sentry initialisation in `WhiteNoiseApp` collects crashes, traces, and optional profiling. Sensitive DSNs should be injected via the `Configuration/Local.xcconfig` template.

## Extensibility Guidelines
- **Adding a sound**: drop assets under `WhiteNoise/Sounds/<category>/`, update `SoundConfiguration.json`, ensure filenames match without extensions (factory appends them), and provide icons.
- **New audio behaviours**: add new fade strategies or services using protocol-first patterns so they can be injected/testing.
- **Timer adjustments**: prefer modifying `TimerService.TimerMode` and related constants; keep the picker options and remote command progress in sync.
- **UI tweaks**: leverage `AppConstants.UI` for layout/sizing so iOS/macOS differences stay centralised.

## Known Gaps & Risks (2025-09-16)
- `TimerServiceTests` reference a `remainingSecondsValue` accessor that the concrete `TimerService` no longer exposes; tests currently fail until the accessor or alternative observation API is restored.
- `SoundConfiguration.json` still contains trailing commas and inconsistent spellings (`"sprint"` instead of `"spring"`, etc.); the loader will throw if the JSON isn’t cleaned before bundling.
- The loader expects the configuration file at the bundle root (`Bundle.main.url` with no subdirectory). Ensure the project build phase copies the JSON accordingly or update the loader to pass the `subdirectory` argument.
- Artwork asset `LaunchScreenIcon` is referenced but absent from `Assets.xcassets`, so Now Playing metadata renders without artwork by default.

Keep this doc updated when architectural decisions shift or when new subsystems (e.g., analytics, new timers, widgets) land.
