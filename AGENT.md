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

## Workflow Orchestration

### 1. Plan Mode Default
- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions)
- If something goes sideways, STOP and re-plan immediately – don't keep pushing
- Use plan mode for verification steps, not just building
- Write detailed specs upfront to reduce ambiguity

### 2. Subagent Strategy
- Use subagents liberally to keep main context window clean
- Offload research, exploration, and parallel analysis to subagents
- For complex problems, throw more compute at it via subagents
- One tack per subagent for focused execution

### 3. Self-Improvement Loop
- After ANY correction from the user: update `tasks/lessons.md` with the pattern
- Write rules for yourself that prevent the same mistake
- Ruthlessly iterate on these lessons until mistake rate drops
- Review lessons at session start for relevant project

### 4. Verification Before Done
- Never mark a task complete without proving it works
- Diff behavior between main and your changes when relevant
- Ask yourself: "Would a staff engineer approve this?"
- Run tests, check logs, demonstrate correctness

### 5. Demand Elegance (Balanced)
- For non-trivial changes: pause and ask "is there a more elegant way?"
- If a fix feels hacky: "Knowing everything I know now, implement the elegant solution"
- Skip this for simple, obvious fixes – don't over-engineer
- Challenge your own work before presenting it

### 6. Autonomous Bug Fixing
- When given a bug report: just fix it. Don't ask for hand-holding
- Point at logs, errors, failing tests – then resolve them
- Zero context switching required from the user
- Go fix failing CI tests without being told how

## Task Management

1. **Plan First**: Write plan to `tasks/todo.md` with checkable items
2. **Verify Plan**: Check in before starting implementation
3. **Track Progress**: Mark items complete as you go
4. **Explain Changes**: High-level summary at each step
5. **Document Results**: Add review section to `tasks/todo.md`
6. **Capture Lessons**: Update `tasks/lessons.md` after corrections

## Core Principles

- **Simplicity First**: Make every change as simple as possible. Impact minimal code.
- **No Laziness**: Find root causes. No temporary fixes. Senior developer standards.
- **Minimal Impact**: Changes should only touch what's necessary. Avoid introducing bugs.

## Tools & Etiquette

- Use `apply_patch` for all file edits (atomic patches, minimal diffs).
- Use `rg` for searching and `sed -n 'start,endp'` for reading file chunks (≤250 lines).
- Group related shell actions under a single short preamble to the user.
- Keep responses concise; prefer actionable bullets over long prose.

## Coding Guidelines

- Keep changes minimal and focused on the requested task.
- Match code style of the repo; avoid large refactors unless asked.
- Don't fix unrelated issues; call them out separately if discovered.
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
