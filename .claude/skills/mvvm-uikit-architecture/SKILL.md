---
name: mvvm-uikit-architecture
description: "Production-first enterprise skill for UIKit MVVM architecture (iOS 13+). Guides iterative refactoring of legacy UIKit MVC codebases to modern MVVM through phased, low-risk PRs tracked in a `refactoring/` directory. Also applies when creating new screens, setting up Coordinator navigation, implementing Combine bindings, migrating GCD completion handlers, building DI with factories, adopting DiffableDataSource, or writing ViewModel tests. Covers ViewState enum, Combine @Published + sink, GCD patterns, Coordinator lifecycle, constructor injection, programmatic Auto Layout, and phased refactoring workflow."
# Approach: Production-First Iterative Refactoring

This UIKit MVVM skill is built for **production enterprise codebases** where stability and reviewability matter more than speed. Architecture changes are delivered through **iterative refactoring** — small, focused PRs (≤200 lines, single concern) tracked in a `refactoring/` directory with per-feature plan files. Every issue gets a full description (location, severity, problem, fix). New findings are logged as tasks, never mixed into ongoing PRs. Critical safety issues ship first; cosmetic improvements come last. This enables teams to adopt modern MVVM standards without disrupting feature delivery or destabilizing production.
version: 1.0.0
tags: [uikit, mvvm, combine, ios, architecture, enterprise, coordinator, testing, di, gcd]
platforms: [copilot, claude-code, cursor]
---

# UIKit MVVM Architecture (iOS 13+)

Enterprise-grade UIKit MVVM architecture skill. Opinionated: prescribes Combine-bound ViewModels, Coordinator navigation, constructor injection via factories, ViewState enum, DiffableDataSource, and programmatic Auto Layout. Adopts a **production-first iterative refactoring** approach — every pattern is chosen for testability, reviewability, and safe incremental adoption in large teams. UIKit MVVM remains the dominant production architecture for large-scale iOS apps.

## Architecture Layers

```text
View/ViewController  → UIViewController + UIView. Binds to ViewModel via Combine/closures/GCD. Renders state.
ViewModel Layer      → Zero UIKit imports. Exposes ViewState<T>. Uses @Published (Combine) or closures (GCD).
Coordinator Layer    → Manages navigation flow. Creates ViewModels + VCs. Owns UINavigationController.
Repository Layer     → Protocol-based data access. Hides data source details.
Service Layer        → URLSession, persistence. Injected via protocol. May use GCD or async/await.
```

## Quick Decision Trees

### "Should this ViewController have a ViewModel?"

```
Is there business logic, networking, or complex state?
├── YES → Create a ViewModel (ObservableObject with @Published)
└── NO → Is it a container/flow controller (tab bar, navigation)?
    ├── YES → Coordinator manages it, no ViewModel needed
    └── NO → No ViewModel needed unless it simplifies testing
```

### "Which binding mechanism should I use?"

```text
Is this a legacy codebase with heavy GCD / completion handlers?
├── YES → Is the goal to extract ViewModels first (keep GCD)?
│   ├── YES → Closures / Bindable<T> + GCD in service layer
│   │   └── Upgrade to Combine later (see migration-patterns.md)
│   └── NO → Adopt Combine during extraction
│       └── @Published + sink (production standard)
└── NO → What is the minimum iOS target?
    ├── iOS 13+ → Combine: @Published + sink
    │   └── One-shot events? → PassthroughSubject
    └── < iOS 13 → Closures / Bindable<T> wrapper
```

### "Where do dependencies come from?"

```
ViewModel always receives dependencies via constructor:
  init(service: NetworkServiceProtocol)

Who creates the ViewModel?
├── Coordinator (recommended)
│   └── Coordinator owns factory, creates VM with deps, passes to VC init
├── VC creates it (simpler apps)
│   └── VC receives deps via init, passes to VM init
└── DI Container (large apps, 20+ screens)
    └── Container resolves protocols, coordinator pulls from container
```

### "How should I handle navigation?"

```
Is there more than one navigation flow (auth + main, tabs)?
├── YES → Coordinator pattern with parent/child hierarchy
│   └── AppCoordinator → AuthCoordinator / MainCoordinator → TabCoordinator
└── NO → Single Coordinator wrapping UINavigationController
    └── ViewModel signals navigation via closures, never UIKit imports
```

## Do's — Always Follow

1. **Keep ViewModels free of UIKit imports** — ViewModel imports only Foundation. No UIView, UIColor, UIImage references. This ensures testability on any platform.
2. **Use `ViewState<T>` enum for async data** — prevents impossible states (loading AND error simultaneously). Never use separate `isLoading` + `error` + `data` booleans.
3. **Bind in `viewDidLoad`, never in `init`** — at `viewDidLoad`, all outlets are connected and the view hierarchy is loaded. During `init`, views don't exist yet.
4. **Inject dependencies via constructor with protocol types** — enables testing, prevents singleton coupling. `init(viewModel: ProfileViewModel)`.
5. **Use `private(set) var` for ViewModel state** — ViewController can observe but not write. Enforces unidirectional data flow.
6. **Always use `[weak self]` in `sink` closures** — the retain cycle path is `self → cancellables Set → AnyCancellable → closure → self`.
7. **Use Coordinator pattern for navigation** — ViewModels signal navigation intent through closures. VCs never instantiate other VCs.
8. **Cancel Tasks in `deinit`** — UIKit does NOT auto-cancel Tasks like SwiftUI's `.task` modifier. Store `Task` references and cancel in `deinit`.
9. **Keep new files ≤ 400 lines** — split large VCs into child VCs; split large ViewModels by extension files (`VM+Feature.swift`). For existing files over 400 lines, add a split task to the feature's `refactoring/` plan.

## Don'ts — Critical Anti-Patterns

### Never: ViewModel imports UIKit

```swift
// ❌ Couples ViewModel to platform, breaks unit testing
import UIKit
class BadVM { var icon: UIImage = UIImage(systemName: "star")! }

// ✅ Platform-agnostic types only
import Foundation
class GoodVM: ObservableObject { @Published private(set) var iconName: String = "star" }
```

### Never: Networking in ViewController

```swift
// ❌ Business logic in VC, untestable
override func viewDidLoad() {
    super.viewDidLoad()
    URLSession.shared.dataTask(with: url) { data, _, _ in
        DispatchQueue.main.async { self.tableView.reloadData() }
    }.resume()
}

// ✅ ViewModel handles data, VC observes
override func viewDidLoad() {
    super.viewDidLoad()
    setupBindings()
    viewModel.fetch()
}
```

### Never: Missing `[weak self]` in sink closures

```swift
// ❌ RETAIN CYCLE — self → cancellables → AnyCancellable → closure → self
viewModel.$posts
    .sink { posts in self.renderPosts(posts) }
    .store(in: &cancellables)

// ✅ SAFE
viewModel.$posts
    .receive(on: DispatchQueue.main)
    .sink { [weak self] posts in self?.renderPosts(posts) }
    .store(in: &cancellables)
```

### Never: Force-unwrapped dependencies

```swift
// ❌ Runtime crash when not set
var service: NetworkService!

// ✅ Constructor injection with protocol
private let service: NetworkServiceProtocol
init(service: NetworkServiceProtocol) { self.service = service }
```

### Never: ViewController instantiating other ViewControllers

VCs should not know about other VCs. Navigation is Coordinator's responsibility. This ensures screens are reusable in different flows.

## Workflows

> **Default workflow**: Analyze & Refactor (below). New screen creation applies the same patterns but from a clean slate. In production enterprise codebases, most work is iterative modernization — not greenfield.

### Workflow: Analyze & Refactor Existing MVC Codebase

**When:** First encounter with a legacy UIKit MVC codebase — the most common enterprise scenario.

1. Scan for anti-patterns using the detection checklist (`references/anti-patterns.md`)
2. Create `refactoring/` directory with per-feature plan files (`references/refactoring-workflow.md`)
3. Write each issue with **full description** (Location, Severity, Problem, Fix) — titles alone get forgotten
4. Categorize issues by severity: 🔴 Critical → 🟡 High → 🟢 Medium
5. Plan Phase 1 PR: fix critical safety issues only (≤200 lines per PR)
6. Execute one PR at a time. New findings go to `refactoring/discovered.md` with full descriptions, NOT into current PR
7. After completing each fix: mark the task `- [x]` and update the Progress table
8. Proceed through phases: Critical → ViewModel extraction → Coordinator → Combine bindings → DI

### Workflow: Create a New Screen

**When:** Building a new feature screen from scratch. Apply enterprise patterns from the start.

1. Define the data model and repository protocol (`references/testing.md` for mock pattern)
2. Create ViewModel: `ObservableObject` with `@Published private(set) var state: ViewState<T>` — zero UIKit imports
3. Add `// MARK: -` sections: Properties, Init, Actions, Computed Properties
4. Create the ViewController with constructor injection: `init(viewModel: MyViewModel)`
5. Wire Combine bindings in `setupBindings()` called from `viewDidLoad`
6. Build UI programmatically with Auto Layout (`references/layout-approaches.md`)
7. Add Coordinator route and factory method (`references/coordinator-navigation.md`)
8. Create test file with mock repository (`references/testing.md`)

### Workflow: Extract ViewModel from Massive ViewController

**When:** Refactoring an existing MVC screen to MVVM incrementally.

1. Identify all state properties in the VC (data, loading flags, error state)
2. Create ViewModel class — move state properties to `@Published private(set) var`
3. Move business logic methods from VC to VM (networking, validation, formatting)
4. Add Combine `@Published` to VM state, `Set<AnyCancellable>` to VC
5. Replace direct state access in VC with `viewModel.$property.sink` bindings
6. Remove all `import UIKit` from ViewModel — compiler will flag violations
7. Write tests for the ViewModel (now possible since VM has no UIKit dependency)
8. Verify VC only does: bind, render, forward user actions to VM

### Workflow: Introduce Coordinators to Existing MVVM

**When:** Navigation is scattered across ViewControllers. Adding Coordinators incrementally.

1. Start with one flow (e.g., auth flow or a tab's navigation stack)
2. Create Coordinator protocol and AppCoordinator (`references/coordinator-navigation.md`)
3. Move VC creation from VCs/Storyboard segues to Coordinator's factory methods
4. Replace `performSegue` / `pushViewController` calls with ViewModel navigation closures
5. Wire Coordinator as `UINavigationControllerDelegate` for back-button cleanup
6. Add child coordinator lifecycle management (didFinish delegate pattern)
7. Test Coordinator with mock `UINavigationController` (`references/testing.md`)

## Code Generation Rules

<critical_rules>
Whether generating new code or refactoring existing code, every output must be **production-ready and PR-shippable** — small, focused, and testable. ALWAYS:

1. ViewModels import only `Foundation` and `Combine` — never `UIKit`
2. Use `@Published private(set) var` for state properties modified only by the ViewModel
3. Use `ViewState<T>` enum for async data — never separate boolean flags
4. Inject dependencies via constructor with protocol types
5. Bind in `viewDidLoad` using `setupBindings()` — store in `Set<AnyCancellable>`
6. Always `[weak self]` in `sink` closures when stored in `cancellables`
7. Always `.receive(on: DispatchQueue.main)` before UI updates in sink
8. Add `// MARK: -` sections: Properties, Init, Lifecycle, Bindings, Actions
9. Use programmatic Auto Layout — `translatesAutoresizingMaskIntoConstraints = false`
10. Keep every generated file ≤ 400 lines. Extract child VCs or ViewModel extensions when approaching that limit.
11. Before modifying a ViewController, output a brief `<thought>` analyzing its current dependencies and retain cycles.
</critical_rules>

When generating tests, ALWAYS:

1. Use protocol mocks with `var stubbed*` and `var *CallCount` tracking
2. Test through public interface, never test private methods
3. Use `XCTestExpectation` + `sink` + `dropFirst()` for Combine publisher tests
4. Use `await fulfillment(of:)` for async tests — NEVER `wait(for:)` in async contexts (deadlocks)
5. Include memory leak detection with `addTeardownBlock { [weak sut] in XCTAssertNil(sut) }`

## Fallback Strategies & Loop Breakers

<fallback_strategies>
When refactoring legacy code, you may encounter stubborn Swift compiler errors. If you fail to fix the same error twice, break the loop:

1. **Combine Type Erasure:** If you get generic type mismatch errors with Combine `AnyPublisher`, append `.eraseToAnyPublisher()` to the pipeline or fall back to closures instead of fighting the type system.
2. **DiffableDataSource Generics:** If the compiler complains about `Hashable` conformance or type differences in `NSDiffableDataSourceSnapshot`, verify your `CellViewModel` uses a unique `UUID` instead of complex nested generic models.
3. **Revert and Restart:** If a ViewController refactor spirals into 50+ compiler errors, stop. Propose reverting the changes and breaking the problem into two smaller phases (e.g., extract networking first, then migrate state).
</fallback_strategies>

## Confidence Checks

Before finalizing generated or refactored code, verify ALL:

```
□ No duplicate functionality — searched codebase for existing implementations
□ Architecture adherence — follows patterns already established in the project
□ Naming conventions — matches existing project naming style
□ Import check — ViewModel imports only Foundation + Combine, NOT UIKit
□ ViewState — used for all async data, no separate isLoading/error booleans
□ Combine bindings — [weak self] in every sink, .receive(on: .main) before UI updates
□ DI — dependencies injected via protocol, not accessed via singletons
□ Coordinator — navigation handled by Coordinator, not by VC pushing other VCs
□ Memory management — deinit cancels Tasks, no retain cycles in closures
□ Tests — corresponding test file exists or is created alongside
□ PR scope — changes within defined scope, new findings go to `refactoring/discovered.md`
□ File size — new files ≤ 400 lines; existing oversized files have a split task logged
```

## References

| Reference | When to Read |
|-----------|-------------|
| `references/binding-mechanisms.md` | Combine @Published + sink, closures, async/await, Input/Output pattern, decision matrix |
| `references/coordinator-navigation.md` | Coordinator protocol, hierarchy, memory management, back button handling, deep linking |
| `references/viewcontroller-lifecycle.md` | VC lifecycle, ViewState enum, DiffableDataSource, VC containment, keyboard handling |
| `references/dependency-injection.md` | Constructor injection, Factory pattern, Storyboard DI, Container/Resolver, @Injected wrapper |
| `references/layout-approaches.md` | Programmatic Auto Layout, UIStackView, XIBs, Storyboards, decision criteria |
| `references/testing.md` | Testing Combine publishers, async ViewModels, mocking, memory leak detection, Coordinator tests |
| `references/anti-patterns.md` | Code review detection checklist, severity-ranked UIKit MVVM violations |
| `references/migration-patterns.md` | MVC → MVVM, UIKit → SwiftUI, Combine adoption strategies |
| `references/refactoring-workflow.md` | `refactoring/` directory protocol, per-feature plans, PR sizing, phase ordering |
| `references/file-organization.md` | File size guidelines, ViewModel extension splits, child ViewControllers and subclassing views |
