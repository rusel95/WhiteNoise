# Repository Guidelines

## Project Structure & Module Organization
- `WhiteNoise/` holds the SwiftUI app, organised by role: `Views/`, `ViewModels/`, `Services/`, `Strategies/`, `Factories/`, and `Constants/`. Keep new files in the matching folder and mirror the MVVM separation already in place.
- `Assets.xcassets`, `Sounds/`, and `Configuration/*.xcconfig` store design, audio, and runtime configuration—never hardcode values that belong there.
- Tests live alongside the app: unit coverage under `WhiteNoiseUnitTests/` and UI scaffolding under `WhiteNoiseUITests/`. Documentation and policy references sit in `docs/`.

## Build, Test, and Development Commands
- `open WhiteNoise.xcodeproj` to work in Xcode; use the `WhiteNoise` scheme for all targets.
- `xcodebuild build -project WhiteNoise.xcodeproj -scheme WhiteNoise` verifies the app compiles (run before every PR).
- `xcodebuild test -project WhiteNoise.xcodeproj -scheme WhiteNoise -destination 'platform=iOS Simulator,name=iPhone 15'` executes unit and UI bundles.
- `bash scripts/test.sh` wraps the test command; override `SCHEME`, `PROJECT`, or `DESTINATION` via environment variables when needed.

## Coding Style & Naming Conventions
- Follow Swift API Design Guidelines: types in UpperCamelCase, methods/properties in lowerCamelCase, and prefer clarity over brevity.
- Use four-space indentation, trailing comma-friendly formatting, and keep braces on the same line as declarations.
- Annotate UI-bound types with `@MainActor`, route side effects through services, and lean on protocol abstractions for testability.
- Logging should follow `docs/LOGGING_STANDARD.md` (emoji prefixes such as `🎯`, `🔄`, `⚠️`, `❌`). Record notable decisions in `MEMORY_BANK.md`.

## Testing Guidelines
- Name tests `<Subject>Tests.swift` and focus on single responsibilities (e.g. `TimerServiceTests` exercises lifecycle logic).
- Prefer protocol-backed stubs for audio, persistence, and command services; keep async assertions on the main actor.
- Update or extend coverage whenever you touch timer, fade, or subscription flows. Document any temporary gaps in `docs/TESTING.md`.

## Commit & Pull Request Guidelines
- Write imperative, present-tense commit titles (e.g. `Add adaptive iPad UI layout`). Optional square-bracket tags like `[fix]` are acceptable when scoped.
- Before opening a PR, run the build and test commands above, update relevant docs (`README.md`, `MEMORY_BANK.md`, architecture notes), and note manual QA performed.
- PR descriptions should outline motivation, key changes, linked issues, and attach UI screenshots or recordings when visuals shift.
