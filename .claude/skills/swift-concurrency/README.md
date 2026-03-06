# Swift Concurrency

Enterprise-grade skill for Swift Concurrency on Apple platforms. Prevents the most dangerous production crash patterns — cooperative pool deadlocks, continuation misuse, actor reentrancy corruption, and Sendable violations — through actionable rules, decision trees, and detection checklists. Covers Swift 6.2 Approachable Concurrency, enterprise migration strategies, and security-specific concurrency patterns.

## What This Skill Changes

| Without Skill | With Skill |
|---------------|------------|
| AI uses `DispatchSemaphore.wait()` in async contexts (deadlocks cooperative pool) | Continuation-based bridging with `withCheckedThrowingContinuation`, cooperative pool awareness |
| AI uses `@unchecked Sendable` to silence compiler (hides data races) | `sending` parameter, `Mutex<State>`, actor wrapping — compiler-verified safety |
| AI assumes actor state unchanged after `await` (reentrancy bugs) | Re-check-after-await pattern, in-flight Task coalescing for deduplication |
| AI creates `Task {}` inside `@MainActor` expecting background execution | Understands `Task.init` inherits caller isolation; uses `@concurrent` or `nonisolated` for background |
| AI forgets `continuation.finish()` in AsyncStream (resource leaks) | `onTermination` handler pattern, backpressure policy selection, `withDiscardingTaskGroup` for services |
| AI uses `MainActor.run {}` for isolation (runtime-only, unverifiable) | Static `@MainActor` annotation — compiler-verified at every call site |
| AI ignores Swift 6.2 caller-side isolation change (silent main-thread hangs) | Explicit `@concurrent` for CPU-intensive work, awareness of `nonisolated(nonsending)` default |
| AI generates async tests with timing dependencies (flaky CI) | `withMainSerialExecutor` for determinism, `Clock` injection, `AsyncStream.makeStream` for control |
| AI leaves security-critical code vulnerable to TOCTOU at `await` points | Transaction-style actor methods, token refresh serialization, Keychain actor wrapping |

## Install

```bash
npx skills add git@git.epam.com:epm-ease/research/agent-skills.git --skill swift-concurrency
```

Verify installation by asking your AI agent to review async/await code — it should detect cooperative pool blocking, check continuation safety, warn about actor reentrancy, and reference Swift 6.2 behavioral changes.

## When to Use

- Writing or reviewing async/await, actor, or TaskGroup code
- Diagnosing data races, deadlocks, or continuation crashes
- Migrating a codebase to `SWIFT_STRICT_CONCURRENCY=complete` or Swift 6 mode
- Adopting Swift 6.2 Approachable Concurrency (`@concurrent`, `nonisolated(nonsending)`)
- Implementing Sendable conformance or using `sending` parameters
- Using AsyncStream, AsyncSequence, or AsyncChannel correctly
- Fixing concurrency-related security issues (TOCTOU, token races, Keychain access)
- Setting up Thread Sanitizer and `LIBDISPATCH_COOPERATIVE_POOL_STRICT` in CI
- Creating deterministic async tests with Clock injection
- Establishing Swift Concurrency standards across a team

## Available Workflows

Ask your AI agent to run any of these workflows:

| Workflow | What It Does |
|----------|-------------|
| **Audit Existing Codebase** | Scans for crash patterns, Sendable violations, actor reentrancy, AsyncStream leaks, and security issues. Creates a severity-ranked refactoring plan. |
| **Migrate Module to Strict Concurrency** | Bottom-up migration to `SWIFT_STRICT_CONCURRENCY=complete` or Swift 6 mode. Audits third-party SDKs, fixes global state, enables per-target flags. |
| **Create New Concurrent Feature** | Guides isolation model selection, concurrency structure, Sendable compliance, cancellation, and deterministic testing from scratch. |
| **Fix Production Crash** | Classifies crash type (continuation, deadlock, watchdog, reentrancy), reproduces with targeted test, applies fix with TSan verification. |

## Author

[Ruslan Popesku](https://git.epam.com/Ruslan_Popesku)
