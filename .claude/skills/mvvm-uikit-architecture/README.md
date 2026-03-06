# UIKit MVVM Architecture

Enterprise-grade UIKit MVVM architecture skill for iOS 13+. Ensures consistency across teams: every new screen follows the same ViewModel + Coordinator + DI structure, and existing code evolves through safe, reviewable PRs.

## What This Skill Changes

| Without Skill | With Skill |
|---------------|------------|
| AI moves all logic to ViewModel but keeps `import UIKit` | ViewModel imports only `Foundation` + `Combine` — testable on any platform |
| AI uses `var isLoading = false` + `var error: Error?` + `var data: [T]` | `ViewState<T>` enum — impossible states eliminated at compile time |
| AI generates `assign(to:on:)` as "cleaner" syntax (retain cycle) | `sink` with `[weak self]` + `.receive(on: DispatchQueue.main)` — no leaks |
| AI calls `tableView.reloadData()` after mutations | `DiffableDataSource` with `applySnapshot` — crash-free, animatable updates |
| AI has VC instantiate and push other VCs directly | Coordinator pattern — ViewModel signals via closures, never imports UIKit |
| AI uses `NetworkManager.shared` or force-unwrapped `var service: NetworkService!` | Constructor injection via protocol types, Coordinator-owned factories |
| AI skips tests because ViewModel has UIKit deps | Mock pattern + Combine publisher testing + memory leak detection in `tearDown` |
| AI forgets `translatesAutoresizingMaskIntoConstraints = false`, mixes layout approaches | Consistent programmatic Auto Layout with lazy view properties, `NSLayoutConstraint.activate` |
| AI refactors entire file in one pass with no plan | Phased `refactoring/` directory with ≤200-line PRs, one concern per PR |

## Install

```bash
npx skills add git@git.epam.com:epm-ease/research/agent-skills.git --skill mvvm-uikit-architecture
```

Verify installation by asking your AI agent to refactor a UIKit ViewController — it should follow Coordinator + ViewModel + Combine patterns and reference the `refactoring/` directory.

## When to Use

- Creating new UIKit screens or features to enterprise MVVM standards
- Modernizing existing UIKit code — extracting ViewModels, adopting Combine, introducing Coordinators
- Establishing consistent architecture across a growing team
- Setting up Coordinator-based navigation
- Implementing Combine bindings (@Published + sink)
- Building DI with factory pattern and constructor injection
- Adopting DiffableDataSource for collection/table views
- Writing ViewModel unit tests
- Planning incremental UIKit → SwiftUI migration

## Author

[Ruslan Popesku](https://git.epam.com/Ruslan_Popesku)
