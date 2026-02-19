# AGENT.md — Codex CLI Guide for This Repo

This document helps the Codex CLI agent (and humans using it) work effectively in this repository.

## Quick Start

1. Explore repo
   - `rg --files -n --hidden -g '!.git' | sed -n '1,200p'`
2. Open in Xcode
   - `open WhiteNoise.xcodeproj`
3. Build / Test (CLI)
   - Debug build: `xcodebuild -project WhiteNoise.xcodeproj -scheme WhiteNoise -configuration Debug build`
   - Release build: `xcodebuild -project WhiteNoise.xcodeproj -scheme WhiteNoise -configuration Release build`
   - UI tests: `xcodebuild test -project WhiteNoise.xcodeproj -scheme WhiteNoise -destination 'platform=iOS Simulator,name=iPhone 15'`

## Project Map

- App entry: `WhiteNoise/WhiteNoiseApp.swift`
- Root view: `WhiteNoise/Views/ContentView.swift`
- Main screen: `WhiteNoise/Views/WhiteNoisesView.swift`
- Sound cell: `WhiteNoise/Views/SoundView.swift`
- Timer UI: `WhiteNoise/Views/TimerPickerView.swift`
- ViewModels: `WhiteNoise/ViewModels/WhiteNoisesViewModel.swift`, `WhiteNoise/ViewModels/SoundViewModel.swift`
- Services: `WhiteNoise/Services/*` (audio, session, timer, haptics, persistence, remote commands)
- Config: `WhiteNoise/Resources/SoundConfiguration.json`
- Assets: `WhiteNoise/Assets.xcassets/*`, audio files in `WhiteNoise/Sounds/*`
- Tests: `WhiteNoiseUITests/*`
- Docs: `README.md`, `CLAUDE.md`, `docs/PLAY_PAUSE_FLOW.md`, `docs/LOGGING_STANDARD.md`

## Agent Operating Mode

- Filesystem: workspace-write (safe to add/modify files in repo)
- Network: restricted (avoid installs/downloads without explicit approval)
- Approvals: on-request (escalate only when necessary)

## Tools & Etiquette

- Use `apply_patch` for all file edits (atomic patches, minimal diffs).
- Use `rg` for searching and `sed -n 'start,endp'` for reading file chunks (≤250 lines).
- Group related shell actions under a single short preamble to the user.
- Keep responses concise; prefer actionable bullets over long prose.

## Planning & Progress

- For multi-step work, track with the plan tool:
  - Create plan: define concise steps (5–7 words each).
  - Maintain single `in_progress` step; mark completed as you go.
  - Update the plan if scope changes, with a short rationale.

## Coding Guidelines

- Keep changes minimal and focused on the requested task.
- Match code style of the repo; avoid large refactors unless asked.
- Don’t fix unrelated issues; call them out separately if discovered.
- Prefer protocol-driven design and DI (see `CLAUDE.md` SOLID notes).
- Use `@MainActor` for UI/state where appropriate.
- Follow logging conventions in `docs/LOGGING_STANDARD.md` when adding logs.

## Validation

- Build before/after significant changes with `xcodebuild`.
- Run UI tests when touching UI logic (`WhiteNoiseUITests/*`).
- For audio/timer changes, consult `docs/PLAY_PAUSE_FLOW.md` to avoid race conditions.

## Common Workflows

1. Add a new sound
   - Add audio file to `WhiteNoise/Sounds/<category>/...`
   - Update `WhiteNoise/Resources/SoundConfiguration.json`
   - Provide image in `WhiteNoise/Assets.xcassets/<name>.imageset`
   - Verify view models pick it up and persistence stores it

2. Adjust play/pause behavior
   - Review state transitions in `WhiteNoisesViewModel.playingButtonSelected`
   - Ensure `updateState` flags avoid double toggles
   - Coordinate with `TimerService` pause/resume and fade strategies

3. Timer changes
   - Update `TimerService.swift`; ensure task cancellation and remaining time semantics
   - Validate expiry path triggers `pauseSounds(updateState: true)`

4. Logging improvements
   - Add structured logs per emoji prefix and format
   - Snapshot complex state when debugging concurrency

## Guardrails & Pitfalls

- Avoid duplicating play/pause calls from multiple sources (button, timer, remote, interruptions).
- Protect against rapid toggles causing overlapping async operations.
- Keep fade operations cancellable and coordinated.
- Persist user preferences promptly but atomically.

## Cross-References

- Architecture & principles: `CLAUDE.md`
- Play/pause flow & races: `docs/PLAY_PAUSE_FLOW.md`
- Logging format: `docs/LOGGING_STANDARD.md`
- App usage & install: `README.md`

## Memory Bank

Use `MEMORY_BANK.md` to persist key decisions, conventions, and recurring facts that help future iterations. Update it when you add features, change flows, or establish new conventions.
