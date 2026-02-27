<!--
Sync Impact Report
===================
Version change: 1.0.0 → 1.1.0
Modified principles:
  - I. MVVM with Protocol Services — condensed; delegates detail to
    /swiftui-mvvm-architecture skill
  - III. Modern Swift Concurrency — condensed; delegates detail to
    /swift-concurrency skill
Added sections: N/A
Removed sections: N/A
Templates requiring updates:
  - .specify/templates/plan-template.md — ✅ no update needed
    (Constitution Check section is generic; gates derived at plan time)
  - .specify/templates/spec-template.md — ✅ no update needed
    (Spec structure is technology-agnostic; aligns with principles)
  - .specify/templates/tasks-template.md — ✅ no update needed
    (Task phasing is generic; no principle-specific task types required)
Follow-up TODOs: none
-->

# WhiteNoise Constitution

## Core Principles

### I. MVVM with Protocol Services

**Skill**: Invoke `/swiftui-mvvm-architecture` when creating new
SwiftUI views, ViewModels, or refactoring existing UI code. The
skill provides detailed patterns for `@Observable`, `@State`,
dependency injection, navigation, and file organisation.

All feature code MUST follow the Model-View-ViewModel pattern with
dedicated service objects. Views are declarative, ViewModels
orchestrate business logic, Models are pure data, and Services
encapsulate IO behind protocols.

*Rationale*: Strict layering keeps each component testable in
isolation and prevents UI code from accumulating hidden dependencies.

### II. SOLID, DRY, KISS, YAGNI

All code changes MUST respect these complementary principles:

- **Single Responsibility**: Each type has exactly one reason to
  change. Classes MUST stay under 200 lines; methods under 30 lines.
- **Open/Closed**: Extend behaviour through protocols and strategy
  objects (e.g., `FadeStrategy`), not by modifying existing types.
- **Liskov Substitution**: Protocol implementations MUST fulfil the
  full contract; callers MUST NOT need to know the concrete type.
- **Interface Segregation**: Protocols MUST be focused and minimal.
  Split large protocols into smaller, specific ones.
- **Dependency Inversion**: ViewModels and services MUST depend on
  protocol abstractions, never on concrete implementations.
- **DRY**: Common logic MUST live in shared helpers (`AppConstants`,
  extensions, utility services). Duplication across files is a defect.
- **KISS / YAGNI**: Ship the simplest working solution. New
  abstractions MUST NOT be introduced until a second concrete need
  exists. Remove dead code promptly.

*Rationale*: These principles prevent accidental complexity, reduce
coupling, and keep the codebase navigable as features grow.

### III. Modern Swift Concurrency (NON-NEGOTIABLE)

**Skill**: Invoke `/swift-concurrency` when creating new files or
refactoring existing code that involves async work, actors, tasks,
Sendable conformance, or `@MainActor` isolation. The skill provides
decision trees, migration guides, and detailed patterns for
structured concurrency, cancellation, and thread safety.

All asynchronous work MUST use structured Swift concurrency
(`async/await`, `Task`, task groups). Legacy patterns
(completion handlers, Combine, `@StateObject`/`@Published`)
MUST NOT be used in new code. Cancel every `Task` before replacing
it or on `deinit`. Never use semaphores or locks in async contexts.

*Rationale*: Structured concurrency eliminates data races, simplifies
cancellation, and aligns with Apple's forward-looking runtime.

### IV. Protocol-First Dependency Injection

Every external dependency (audio players, persistence, audio session,
haptics) MUST be accessed through a protocol:

- Define a protocol for each service contract
  (e.g., `AudioPlayerProtocol`, `SoundPersistenceServiceProtocol`).
- Inject dependencies through initialisers, not through singletons or
  global access.
- Factory types (e.g., `AVAudioPlayerFactory`) MUST conform to a
  factory protocol so tests can substitute stubs.
- Production wiring happens at the composition root (`ContentView` /
  app entry point), not inside individual types.

*Rationale*: Protocol-driven DI makes every component independently
testable and allows substitution without modifying production code.

### V. Audio & Resource Safety

Audio is the app's core value; its management MUST be rigorous:

- Always call `audioSessionService.ensureActive()` before starting
  playback.
- MUST NOT talk to `AVAudioPlayer` directly from UI objects — go
  through the `AudioPlayerProtocol` and factory.
- Honour fade durations defined in `AppConstants.Animation`.
- Manage timer lifecycle exclusively via `TimerService` — no ad-hoc
  timers inside ViewModels.
- Remote-command callbacks MUST funnel through
  `WhiteNoisesViewModel` helpers so lock-screen interactions stay in
  parity with on-screen UI controls.
- Background audio entitlement (`UIBackgroundModes = audio`) MUST
  remain enabled and functional.

*Rationale*: Incorrect audio session handling causes silent failures,
battery drain, and poor user experience on iOS.

### VI. Testing Discipline

Quality gates MUST be enforced on every change:

- Prefer protocol-driven dependencies so stubs can be injected.
- Add regression tests to `WhiteNoiseUnitTests` for any change to
  timer logic, fade operations, or persistence behaviour.
- When testing `@MainActor` types, use `MainActor.run { ... }` to
  drive state and assertions.
- Validate UI flows manually: play/pause toggles, timer selections,
  remote commands, audio-interruption recovery, variant selection.
- The project MUST build without warnings before merging:
  `xcodebuild -project WhiteNoise.xcodeproj -scheme WhiteNoise build`

*Rationale*: Automated and manual testing catches regressions early,
especially in audio and timer edge cases that are hard to reproduce.

### VII. Observability & Diagnostics

All runtime behaviour MUST be traceable:

- Follow structured logging prefixes: method entry (`🎯`), state
  changes (`🔄`), warnings (`⚠️`), errors (`❌`).
- MUST NOT log sensitive information (access tokens, personal data).
- Sentry DSN values MUST live in `Configuration/Local.xcconfig`, not
  in source code.
- Sentry integration MUST remain active for crash and performance
  telemetry.

*Rationale*: Structured, consistent logging and crash reporting are
essential for diagnosing issues in an audio app that frequently runs
in the background.

## Technology Constraints

- **Language**: Swift 5+
- **UI Framework**: SwiftUI (declarative only; no UIKit unless
  platform-gated)
- **Minimum iOS Version**: iOS 17.0 (required for `@Observable`)
- **Device Support**: Universal (iPhone and iPad)
- **Audio**: AVFoundation with background mode entitlement
- **Persistence**: UserDefaults for user preferences (per-sound
  volume, selected variant)
- **Crash Reporting**: Sentry (DSN via xcconfig)
- **Monetisation**: RevenueCat for subscription/paywall management
- **Constants**: Centralised in `AppConstants` — layout, animation,
  audio, and timer values MUST NOT be hardcoded elsewhere
- **Haptics**: Gated behind `#if os(iOS)` via `HapticFeedbackService`

## Development Workflow

### Pull Request Checklist

1. **Scope**: Touch only files related to the change; leave unrelated
   formatting alone.
2. **Implementation**:
   - Dependencies injected via protocols where practical.
   - Tasks cancelled or awaited appropriately.
   - Error branches log meaningful diagnostics.
3. **Validation**:
   - Project builds without warnings.
   - Unit tests pass.
   - Manual walkthrough of affected flows.
4. **Documentation**: Update architecture docs and memory bank if
   behaviour or assumptions changed.
5. **Post-merge**: Monitor Sentry for new regressions, especially
   around audio session and timer lifecycles.

### Build & Test Commands

```bash
# Debug build
xcodebuild -project WhiteNoise.xcodeproj -scheme WhiteNoise \
  -configuration Debug build

# Unit tests
xcodebuild test -project WhiteNoise.xcodeproj -scheme WhiteNoise \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Governance

This constitution is the authoritative source of engineering
principles for the WhiteNoise project. Together with `CLAUDE.md`,
these are the two canonical project documents.

- **Supremacy**: Constitution principles supersede ad-hoc practices.
  When a conflict arises, the constitution wins.
- **Amendments**: Any change to principles MUST be documented with a
  version bump, rationale, and migration plan for affected code.
- **Versioning**: MAJOR for principle removals or redefinitions,
  MINOR for new principles or material expansions, PATCH for
  clarifications and wording.
- **Compliance Review**: All PRs and code reviews MUST verify
  adherence to these principles. Complexity that violates a principle
  MUST be justified in the PR description.
- **Runtime Guidance**: Use this constitution alongside `CLAUDE.md`
  as the authoritative project references.

**Version**: 1.1.0 | **Ratified**: 2026-02-27 | **Last Amended**: 2026-02-27
