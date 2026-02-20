# Enterprise Refactoring & Tech-Debt Tracker

## Purpose

`REFACTORING_PLAN.md` is a **living tech-debt tracker** that lives at the project root. It uses GitHub-flavoured checkbox syntax (`- [ ]` / `- [x]`) so progress is visible in any Markdown renderer — PRs, IDE previews, GitHub web UI.

Short titles get forgotten in a week. **Every task MUST carry a rich description** — the "what", "where", "why it matters", and "how to fix" — so any team member (or your future self) can pick it up months later without archaeology.

## The Problem with "Fix Everything at Once"

A single PR that migrates @Observable, restructures navigation, introduces DI, and adds tests is:
- **Unreviewable**: 2000+ line diffs get rubber-stamped, not reviewed
- **Unrevertable**: If one change introduces a regression, you can't revert without losing everything
- **Unblockable**: Blocks the entire team while one person refactors
- **Unmeasurable**: You can't measure which change improved what

Enterprise refactoring requires **small, focused, independently-shippable PRs** with a living plan document that tracks everything.

---

## Task Description Requirements

Every task — whether tech-debt, refactoring, or discovered issue — MUST include the fields below. A checkbox with only a title is **not acceptable**.

### Required Fields

| Field | Why | Example |
|-------|-----|---------|
| **Title** | Scannable one-liner for the plan overview | `Force-unwrapped dependencies in ProfileViewModel` |
| **Location** | Exact file(s) and line(s) so the next person finds it instantly | `ProfileViewModel.swift:14`, `ProfileView.swift:8` |
| **Severity** | Prioritisation — 🔴 Critical / 🟡 High / 🟢 Medium | `🔴 Critical` |
| **Problem** | 2-4 sentences: what is wrong and what bad outcome it causes | "The `networkService` property is implicitly unwrapped (`!`). If the DI container fails to register it — or registration order changes — the app crashes on launch with no actionable error message. This has caused 2 Crashlytics incidents in the last month." |
| **Fix** | Concrete steps or code pointer | "Replace IUO with constructor injection. Accept `NetworkServiceProtocol` in `init`. Remove the `!` property. Update `ProfileScreenFactory` to pass the dependency." |

### Optional Fields (add when applicable)

| Field | When |
|-------|------|
| **Dependencies** | Task depends on another task being completed first |
| **Blocker** | Something external prevents starting |
| **PR** | Link when submitted |
| **Found during** | Which task uncovered this (for "Discovered" items) |
| **Assigned** | Team member handling it |
| **Branch** | WIP branch name |
| **Verification** | How to confirm the fix works |

---

## The REFACTORING_PLAN.md Protocol

### Step 1: Generate the Plan

On first analysis of a codebase, create `REFACTORING_PLAN.md` at the project root. This file is the **single source of truth** for ALL discovered issues — not just the ones you'll fix today.

```markdown
# Refactoring Plan

Generated: 2025-01-15
Last Updated: 2025-01-22
Status: In Progress — Phase 2 of 4

## Progress

| Phase | Total | Done | Remaining |
|-------|-------|------|-----------|
| 1. Critical Safety | 3 | 3 | 0 |
| 2. @Observable Migration | 4 | 1 | 3 |
| 3. ViewState Adoption | 3 | 0 | 3 |
| 4. Architecture | 4 | 0 | 4 |
| Discovered | 2 | 0 | 2 |
| **Total** | **16** | **4** | **12** |

---

## Phase 1: Critical Safety Issues ✅ COMPLETED
> Goal: Eliminate crashes and data corruption risks
> PR size target: ≤200 lines changed per PR

- [x] **C1: Force-unwrapped dependencies in ProfileViewModel**
  - **Location**: `ProfileViewModel.swift:14`
  - **Severity**: 🔴 Critical
  - **Problem**: `networkService` is declared as `var networkService: NetworkService!`
    (implicitly unwrapped optional). If DI registration order changes or the
    container is misconfigured in a test target, the app crashes on first
    network call with no actionable error. Crashlytics shows 2 incidents in the
    last 30 days linked to this.
  - **Fix**: Replace IUO with constructor injection. Accept
    `NetworkServiceProtocol` in `init`. Remove the `!` property. Update
    `ProfileScreenFactory` to pass the dependency.
  - **PR**: #142 (merged 2025-01-16)

- [x] **C2: Missing @MainActor on CartViewModel**
  - **Location**: `CartViewModel.swift:1`
  - **Severity**: 🔴 Critical
  - **Problem**: `CartViewModel` mutates `@Published var items` from the result
    of `await api.fetchCart()`, which resumes on a background thread. This
    causes purple "Publishing changes from background threads" warnings in
    Xcode and intermittent UI glitches where the cart badge shows stale data
    for 1-2 seconds.
  - **Fix**: Add `@MainActor` to the class declaration. The compiler will flag
    any call sites that need updating (expect ~5 warnings in tests). Wrap test
    assertions in `@MainActor` or use `await MainActor.run { }`.
  - **PR**: #143 (merged 2025-01-17)

- [x] **C3: NavigationStack inside NavigationStack in OrderFlow**
  - **Location**: `OrderTabView.swift:22`, `OrderListView.swift:8`
  - **Severity**: 🔴 Critical
  - **Problem**: `OrderListView` creates its own `NavigationStack`, but it is
    already embedded inside the `NavigationStack` in `OrderTabView`. This
    causes double navigation bars, broken swipe-back gestures, and
    `.navigationDestination` routing to the wrong stack depending on which
    push fires first.
  - **Fix**: Remove the inner `NavigationStack` in `OrderListView`. Use
    `.navigationDestination(for: OrderRoute.self)` attached to the content
    inside the outer stack. Verify swipe-back works for 3-level deep pushes.
  - **PR**: #145 (merged 2025-01-18)

---

## Phase 2: @Observable Migration 🔄 IN PROGRESS
> Goal: Migrate from ObservableObject to @Observable (iOS 17+)
> PR size target: 1 ViewModel + its View(s) per PR

- [x] **M1: Migrate ItemListViewModel to @Observable**
  - **Location**: `ItemListViewModel.swift`, `ItemListView.swift`
  - **Severity**: 🟡 High
  - **Problem**: `ItemListViewModel` uses `ObservableObject` + `@Published`.
    Any property change re-evaluates ALL observing views — including 8
    `ItemRow` cells that only read `item.name`. `Self._printChanges()` shows
    the entire list re-renders on every keystroke in the search field.
  - **Fix**: Replace `ObservableObject` with `@Observable` macro, remove all
    `@Published`, change `@StateObject` → `@State` in `ItemListView`.
  - **Verification**: `Self._printChanges()` confirms only `SearchBar`
    re-evaluates on keystroke, not `ItemRow` cells.
  - **PR**: #148 (merged 2025-01-20)

- [ ] **M2: Migrate CartViewModel to @Observable**
  - **Location**: `CartViewModel.swift`, `CartView.swift`, `CartBadge.swift`
  - **Severity**: 🟡 High
  - **Problem**: Same over-invalidation as M1. Additionally, `CartBadge` uses
    `@ObservedObject var viewModel` to read `.totalItems` and binds to
    `$viewModel.promoCode`. After migration, `@ObservedObject` is invalid
    with `@Observable` classes and will compile but silently break tracking.
  - **Fix**: Same pattern as M1. `CartBadge` specifically needs `@Bindable`
    because it uses `$viewModel.promoCode` in a `TextField`.
  - **Blocker**: Need to verify `@Bindable` works for both read + binding on
    the same view. Test in isolation first.
  - **Assigned**: @ruslan
  - **Branch**: `feature/migrate-cart-observable`

- [ ] **M3: Migrate ProfileViewModel to @Observable**
  - **Location**: `ProfileViewModel.swift`, `ProfileView.swift`
  - **Severity**: 🟡 High
  - **Problem**: `ProfileViewModel` uses Combine's `ObservableObject` with 6
    `@Published` properties. `ProfileView` reads only 2 of them (`userName`,
    `avatarURL`) but re-evaluates on changes to all 6, including `isEditing`
    and `validationErrors` which only `ProfileEditSheet` needs.
  - **Fix**: Replace with `@Observable`. After migration, `ProfileView` will
    only re-evaluate when `userName` or `avatarURL` change.
  - **Dependencies**: C1 must be merged first (done ✅) because constructor
    injection changes the init signature this migration depends on.

- [ ] **M4: Migrate SearchViewModel to @Observable**
  - **Location**: `SearchViewModel.swift`, `SearchView.swift`, `SearchBar.swift`
  - **Severity**: 🟡 High
  - **Problem**: `SearchBar` uses `@ObservedObject var viewModel` and binds to
    `$viewModel.query`. The parent `SearchView` uses `@StateObject`. After
    migration `@StateObject` → `@State` is straightforward, but `SearchBar`
    needs `@Bindable` for the `$query` binding.
  - **Fix**: `@StateObject` → `@State` in `SearchView`. `@ObservedObject` →
    `@Bindable` in `SearchBar`. Remove `@Published` from all properties.

---

## Phase 3: ViewState Enum Adoption
> Goal: Replace separate isLoading/error/data booleans with ViewState<T>
> PR size target: 1 ViewModel per PR

- [ ] **V1: ItemListViewModel — replace 3 booleans with ViewState**
  - **Location**: `ItemListViewModel.swift:5-7`
  - **Severity**: 🟡 High
  - **Problem**: Three separate state variables: `var isLoading = false`,
    `var error: Error?`, `var items: [Item] = []`. This allows impossible
    states — e.g., `isLoading == true` AND `error != nil` AND `items` is
    non-empty, which currently happens during pull-to-refresh when a previous
    error is still displayed. The View has a 15-line `if/else` chain to decode
    the current state.
  - **Fix**: Replace all three with `var state: ViewState<[Item]> = .idle`.
    Update `loadItems()`, `deleteItem()`, and `refreshItems()` to set state
    transitions. Simplify the View to `switch viewModel.state`.

- [ ] **V2: CartViewModel — introduce ViewState for checkout flow**
  - **Location**: `CartViewModel.swift:8-12`
  - **Severity**: 🟡 High
  - **Problem**: Checkout uses `isProcessing`, `checkoutError`, and
    `orderConfirmation` as three independent variables. A race condition exists
    where `isProcessing = false` is set before `orderConfirmation` is
    populated, causing a brief flash of the cart (empty state) before the
    confirmation screen appears.
  - **Fix**: Introduce `var checkoutState: ViewState<OrderConfirmation> = .idle`.
    Transition directly from `.loading` → `.loaded(confirmation)`.

- [ ] **V3: SearchViewModel — ViewState + debounce via .task(id:)**
  - **Location**: `SearchViewModel.swift:4-8`
  - **Severity**: 🟢 Medium
  - **Problem**: Search uses `isSearching`, `searchError`, `results` separately.
    Also uses a manual `DispatchQueue.main.asyncAfter` debounce which doesn't
    cancel properly when the query changes rapidly.
  - **Fix**: `ViewState<[SearchResult]>` for state. Replace the manual debounce
    with `.task(id: viewModel.query) { try? await Task.sleep(for: .milliseconds(300)); await viewModel.search() }`.

---

## Phase 4: Architecture Improvements
> Goal: DI, Router, Repository layer
> PR size target: varies, max 400 lines

- [ ] **A1: Extract networking into Repository protocol**
  - **Location**: `ItemListViewModel.swift:34-52`, `CartViewModel.swift:28-45`,
    `ProfileViewModel.swift:22-38`
  - **Severity**: 🟡 High
  - **Problem**: Three ViewModels call `URLSession.shared.data(from:)` directly
    with inline URL construction and JSON decoding. The same endpoint URL
    (`/api/items`) appears in 2 files. JSON decoding error handling is
    inconsistent — one ViewModel retries, another shows an alert, the third
    silently fails.
  - **Fix**: Create `ItemRepositoryProtocol` / `CartRepositoryProtocol` with
    async methods. Implement with shared `HTTPClient`. Inject via constructor.

- [ ] **A2: Introduce AppRouter for centralized navigation**
  - **Location**: `ContentView.swift:12-45`, scattered `NavigationLink` across
    8 views
  - **Severity**: 🟢 Medium
  - **Problem**: Navigation is scattered. `ItemListView` has a `NavigationLink`
    that hard-codes `ItemDetailView(item:)`. Can't test what navigation occurs
    on a tap. Can't add deep linking without touching every View.
  - **Fix**: `@Observable class AppRouter` with `@Published var path: [Route]`.
    Typed `enum Route: Hashable` with `.itemDetail(Item)`, `.cart`,
    `.profile`. Central `navigationDestination(for:)` in root view.

- [ ] **A3: Add @Injected DI infrastructure**
  - **Location**: New files: `DependencyContainer.swift`, `Injected.swift`
  - **Severity**: 🟢 Medium
  - **Problem**: Dependencies are created ad-hoc. `ItemListView` does
    `ItemListViewModel(service: NetworkService())` inline. Tests can't swap
    implementations without changing call sites. No single place to see all
    dependencies.
  - **Fix**: `@Injected` property wrapper backed by `DependencyContainer`.
    Register protocols in app launch. Views resolve via `@Injected` or
    `@Environment`.

- [ ] **A4: Add unit tests for all migrated ViewModels**
  - **Location**: New files in `Tests/` for each ViewModel
  - **Severity**: 🟢 Medium
  - **Problem**: Zero ViewModel tests exist. All business logic (filtering,
    CRUD, checkout validation) is untested. Two bugs in the last release were
    regressions that tests would have caught.
  - **Fix**: One test file per ViewModel. Protocol mocks with stubbed returns
    and call-count tracking. Async tests with `await fulfillment(of:)`.
    Memory leak checks with `addTeardownBlock { [weak sut] in XCTAssertNil(sut) }`.

---

## Discovered During Refactoring
> New issues found while working. Add here immediately — do NOT fix in-flight.

- [ ] **D1: Memory leak in OrderDetailViewModel**
  - **Found during**: M2 migration
  - **Location**: `OrderDetailViewModel.swift:67`
  - **Severity**: 🟡 High
  - **Problem**: `NotificationCenter.default.addObserver(self, ...)` captures
    `self` strongly. The observer is never removed. Instruments shows
    `OrderDetailViewModel` instances accumulate — one per navigation push —
    and never deallocate. Each instance holds a decoded `Order` with
    potentially large image data.
  - **Fix**: Switch to `NotificationCenter.default.addObserver(forName:object:queue:using:)`
    with `[weak self]`. Store the returned token and remove in `deinit`.

- [ ] **D2: Unnecessary @State on non-creating view in SettingsView**
  - **Found during**: M1 migration code review
  - **Location**: `SettingsView.swift:5`
  - **Severity**: 🟢 Medium
  - **Problem**: `SettingsView` declares `@State var viewModel: SettingsViewModel`
    but receives the VM from its parent (`SettingsTab`). This means SwiftUI
    creates a redundant cached copy. If the parent updates the VM reference,
    `SettingsView` silently uses its stale cached version.
  - **Fix**: Change to `let viewModel: SettingsViewModel` since this view does
    not create the VM. If `$` bindings are needed, use `@Bindable`.
```

### Step 2: Plan One PR

Before writing any code, define the scope of the NEXT PR. Each PR scope uses checkboxes for its own verification steps:

```markdown
## Next PR Scope

**PR Title**: Migrate CartViewModel to @Observable
**Files to change**: CartViewModel.swift, CartView.swift, CartBadge.swift
**Max lines changed**: ~150
**Risk**: Low (isolated feature, no shared state)

### Changes:
1. CartViewModel: ObservableObject → @Observable, remove @Published
2. CartView: @StateObject → @State
3. CartBadge: @ObservedObject → @Bindable (needs $ binding for badge count)

### Verification:
- [ ] Add `Self._printChanges()` before and after — confirm reduced redraws
- [ ] Run existing tests — all pass
- [ ] Manual test: add/remove items, verify badge updates
- [ ] Remove `Self._printChanges()` before merge

### NOT in this PR:
- ViewState enum migration (Phase 3)
- DI changes (Phase 4)
- New tests (Phase 4)
```

### Step 3: Execute the PR

Apply ONLY the changes listed in the PR scope. If you discover new issues during implementation:
- **DO NOT fix them now**
- Add them to "Discovered During Refactoring" section with a **full description**
- Continue with the original scope

### Step 4: Update the Plan

After completing each refactoring task:
1. Mark the task done: `- [ ]` → `- [x]`
2. Add any newly discovered issues (with full descriptions) to the "Discovered" section
3. Update the Progress table counters
4. Reassess phase ordering if priorities changed

---

## Writing Good Task Descriptions

A task description must be understandable **6 months later** by someone with no prior context.

### ❌ Bad — Titles Without Context

```markdown
- [ ] **Fix CartViewModel state issue**
- [ ] **Fix CartViewModel state issue**
  - Has some boolean state problems. Should probably use ViewState.
```

Six months later: "What state issue? Which booleans? What breaks? Is this still relevant?"

### ✅ Good — Full Context

```markdown
- [ ] **V2: CartViewModel — introduce ViewState for checkout flow**
  - **Location**: `CartViewModel.swift:8-12`
  - **Severity**: 🟡 High
  - **Problem**: Checkout uses `isProcessing`, `checkoutError`, and
    `orderConfirmation` as three independent variables. A race condition
    exists where `isProcessing = false` is set before `orderConfirmation`
    is populated, causing a brief flash of the empty cart before the
    confirmation screen appears.
  - **Fix**: Introduce `var checkoutState: ViewState<OrderConfirmation> = .idle`.
    Transition directly from `.loading` → `.loaded(confirmation)`.
```

Six months later: crystal clear. File, line, exact symptom, exact fix.

## PR Size Guidelines

| Change Type | Max Lines | Example |
|-------------|-----------|---------|
| Single ViewModel migration | 150 | ObservableObject → @Observable |
| ViewState enum adoption | 100 | Replace 3 booleans with ViewState |
| New feature screen | 300 | ViewModel + View + basic test |
| DI infrastructure setup | 200 | @Injected wrapper + first 2 keys |
| Router introduction | 250 | Router + Route enum + RootView wiring |
| Bug fix | 50 | Single focused fix |
| File split (View or ViewModel) | 0 net | Extract extensions / subviews — dedicated PR, not mid-refactor |

If a PR exceeds these limits, split it. If a file exceeds 1000 lines, log a dedicated split task in the plan — see `references/file-organization.md`. Do NOT force a file split inside an unrelated refactoring PR.

## Phase Ordering Strategy

Execute phases in this order: **Critical → @Observable → ViewState → Architecture**.

- **Phase 1 (Critical)** first — these are bugs. Ship safety fixes before anything else.
- **Phase 2 (@Observable)** — mechanical migration, reduces noise in later diffs.
- **Phase 3 (ViewState)** — ViewModel-internal; doesn't affect how VMs are created or injected.
- **Phase 4 (Architecture)** last — cross-cutting DI/Router changes build on the final API shape.

## When to Deviate from the Plan

**Acceptable**: critical production bug (fix now, add to plan retroactively), blocker dependency discovered (reorder phases), team re-prioritisation, phase larger than expected (subdivide it).

**Never**: expanding PR scope mid-implementation, skipping the plan update step, fixing "just one more thing" in an unrelated area.
