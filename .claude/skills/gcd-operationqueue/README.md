# GCD & OperationQueue Concurrency

Enterprise-grade concurrency skill for Grand Central Dispatch and OperationQueue on Apple platforms (iOS, macOS, watchOS, tvOS, visionOS). Prevents the most dangerous concurrency bugs — deadlocks, thread explosion, and data races — through actionable patterns and detection checklists.

## What This Skill Changes

| Without Skill | With Skill |
|---------------|------------|
| AI scatters `DispatchQueue.global().async` throughout codebase | 3-4 well-defined queue subsystems with target queue hierarchies (WWDC 2017-706) |
| AI uses `DispatchQueue.main.sync` causing deadlocks | `async` by default, `dispatchPrecondition` at API boundaries |
| AI stores `os_unfair_lock` as Swift property (memory corruption) | `OSAllocatedUnfairLock` (iOS 16+) or `NSLock` (any iOS) — safe by construction |
| AI uses `DispatchSemaphore` as a mutex (no priority donation) | Lock selection hierarchy: NSLock for general, barrier for R/W, semaphore only for rate-limiting |
| AI uses barriers on global queues (silently ignored) | Custom concurrent queues with explicit barrier for reader-writer pattern |
| AI creates `AsyncOperation` without KVO or thread-safe state | Complete AsyncOperation base class with KVO, barrier-protected state, cancel-before-start handling |
| AI leaves `DispatchGroup.enter()` without `defer { group.leave() }` | Balanced enter/leave with `defer` on every code path |
| AI mixes `DispatchSemaphore.wait()` with Swift Concurrency (deadlock) | Clear migration mapping: what to migrate vs keep as GCD |
| AI generates concurrent code without Thread Sanitizer verification | TSan in CI, `dispatchPrecondition` at boundaries, stress tests with `concurrentPerform` |

## Install

```bash
# Install the skills repository
npx openskills install git@git.epam.com:epm-ease/research/agent-skills.git

# Install this specific skill
npx openskills add gcd-operationqueue
```

Verify installation by asking your AI agent to review concurrent code — it should detect deadlock patterns, recommend proper lock selection, and reference `dispatchPrecondition`.

## When to Use

- Reviewing or writing GCD/OperationQueue concurrent code
- Fixing deadlocks, data races, or thread explosion issues
- Implementing thread-safe collections or caches
- Creating AsyncOperation subclasses for OperationQueue
- Selecting the right lock type (NSLock, OSAllocatedUnfairLock, barriers)
- Using DispatchGroup, DispatchWorkItem, or DispatchSemaphore correctly
- Setting up DispatchSource timers or DispatchIO file operations
- Debugging concurrency issues with Thread Sanitizer and Instruments
- Migrating specific GCD patterns to Swift Concurrency
- Establishing concurrency standards across a team
