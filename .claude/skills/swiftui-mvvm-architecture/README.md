# SwiftUI MVVM Architecture

Enterprise-grade SwiftUI MVVM architecture with @Observable (iOS 17+). Takes a **production-first iterative refactoring** approach — modernizing legacy codebases through small, reviewable PRs while also ensuring new features meet enterprise standards from day one.

## What This Skill Changes

| Without Skill | With Skill |
|---------------|------------|
| `ObservableObject` + `@Published` | `@Observable @MainActor final class` |
| `isLoading` + `error` + `data` booleans | `ViewState<T>` enum (no impossible states) |
| `onAppear { Task { } }` | `.task { }` (managed lifecycle, auto-cancel) |
| `URLSession.shared` in ViewModel | Protocol-based Repository + HTTPClient injection |
| `NavigationLink("Details") { DetailView() }` | Typed `enum Route` + `AppRouter` |
| No tests | Mock pattern + async testing + memory leak detection |
| "Fix everything at once" PRs | Phased `REFACTORING_PLAN.md` with ≤200-line PRs |

## When to Use

- Creating new SwiftUI screens or features to enterprise MVVM standards
- **Refactoring legacy SwiftUI code** — iterative, phased PRs tracked in REFACTORING_PLAN.md
- Migrating from ObservableObject to @Observable
- Setting up Router-based navigation or dependency injection
- Building async/await networking layers
- Writing ViewModel unit tests
- Diagnosing unnecessary view redraws or performance issues