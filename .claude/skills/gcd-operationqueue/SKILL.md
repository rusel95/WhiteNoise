---
name: gcd-operationqueue
description: "Enterprise skill for GCD and OperationQueue concurrency on Apple platforms (iOS, macOS, watchOS, tvOS, visionOS). Use when reviewing or writing DispatchQueue code, fixing deadlocks, preventing thread explosion, implementing thread-safe collections, creating AsyncOperation subclasses, using DispatchGroup or DispatchSemaphore, setting up reader-writer locks with barriers, selecting lock types (os_unfair_lock, NSLock, OSAllocatedUnfairLock), debugging data races with Thread Sanitizer, profiling with Instruments, or migrating GCD patterns to Swift Concurrency. Covers queue creation, QoS selection, target queue hierarchies, DispatchSource timers, DispatchIO, priority inversion prevention, and enterprise production patterns for Core Data, networking, and background tasks."
version: 1.0.0
tags: [gcd, dispatch, operationqueue, concurrency, ios, macos, apple, thread-safety, enterprise, deadlock, data-race, migration]
platforms: [copilot, claude-code, cursor]
---

# GCD & OperationQueue Concurrency

Enterprise-grade concurrency skill for Grand Central Dispatch and OperationQueue. Opinionated: prescribes serial queues by default, target queue hierarchies, labeled queues, `NSLock`/`OSAllocatedUnfairLock` for synchronization, barrier-based reader-writer on custom concurrent queues, and OperationQueue for dependency graphs. Apple has **not deprecated any core GCD APIs** — GCD remains appropriate for parallelism, system I/O, and performance-critical paths. This skill covers correct usage, deadly bug prevention, and coexistence with Swift Concurrency.

## Concurrency Layers

```text
Application Layer    -> OperationQueue for dependency graphs, cancellation, throttling.
Dispatch Layer       -> Serial queues for state protection, concurrent+barrier for R/W.
Synchronization      -> NSLock / OSAllocatedUnfairLock for short critical sections.
System I/O           -> DispatchSource (timers, file monitoring), DispatchIO (non-blocking file I/O).
Thread Pool          -> GCD manages threads. App targets 3-4 well-defined queue subsystems.
```

## Quick Decision Trees

### "Which queue type should I use?"

```
Do you need mutual exclusion (protecting shared state)?
+-- YES -> Serial queue (default). Simplest, safest.
+-- NO  -> Is this independent parallel work (image processing, batch transforms)?
    +-- YES -> Concurrent queue (custom) with barrier for any writes.
    +-- NO  -> Do you need dependency graphs, cancellation, or throttling?
        +-- YES -> OperationQueue with maxConcurrentOperationCount.
        +-- NO  -> Serial queue. When in doubt, serial.
```

### "Which lock should I use?"

```
Which lock?
+-- iOS 16+ -> OSAllocatedUnfairLock (Apple's safe wrapper)
+-- iOS 18+ / Swift 6 -> Mutex from Synchronization framework
+-- Any iOS -> NSLock (safe, simple, recommended by Apple DTS)
NEVER: os_unfair_lock as direct Swift stored property (memory corruption).
NEVER: DispatchSemaphore as a mutex (no priority donation).
```

### "Which QoS should I use?"

```
Is the user waiting and watching?
+-- Immediate response (animation, touch) -> .userInteractive
+-- User-triggered, blocking progress    -> .userInitiated
+-- Long-running with progress bar       -> .utility
+-- Invisible to user (prefetch, sync)   -> .background
WARNING: .background QoS may be halted entirely in Low Power Mode.
```

## Do's -- Always Follow

1. **Label every queue with reverse DNS** -- labels appear in crash reports, Instruments, and Xcode debugger. `DispatchQueue(label: "com.company.app.subsystem")`.
2. **Use serial queues by default** -- they provide mutual exclusion and ordering. Concurrent queues are an optimization, not a default.
3. **Limit the app to 3-4 well-defined queue subsystems** -- per Apple WWDC 2017-706. Use target queue hierarchies to funnel work. Never scatter `DispatchQueue.global()` calls throughout the codebase.
4. **Balance every `group.enter()` with `defer { group.leave() }`** -- missing leave means `notify()` never fires. Extra leave crashes with `EXC_BAD_INSTRUCTION`.
5. **Use `dispatchPrecondition` at API boundaries** -- `.onQueue(.main)` before UI updates, `.notOnQueue(serialQueue)` before sync dispatch. Debug-only — removed in release builds, zero production cost.
6. **Use `[weak self]` in repeating timers and stored closures** -- one-shot `async` closures are safe (execute and release), but repeating `DispatchSourceTimer` handlers and closures stored on properties create retain cycles.
7. **Always call `endBackgroundTask`** -- in both the expiration handler AND the success path. Failing to end is the #1 cause of background task problems (Apple DTS).
8. **Run all CI tests with Thread Sanitizer enabled** -- catches data races, access races, and use-after-free at runtime.

## Don'ts -- Critical Anti-Patterns

### Never: `sync` on main queue from main thread

```swift
// CRASH -- libdispatch detects and traps
DispatchQueue.main.sync { print("never") }

// FIX: Always use async
DispatchQueue.main.async { print("works") }
```

### Never: Nested `sync` on same serial queue

```swift
// DEADLOCK -- outer block occupies queue, inner sync waits forever
serialQueue.async {
    serialQueue.sync { /* ... */ } // Circular wait
}
```

### Never: Barrier on global queue

```swift
// SILENTLY IGNORED -- no warning, no error, no exclusion
DispatchQueue.global().async(flags: .barrier) { /* not exclusive */ }

// FIX: Custom concurrent queue
let rwQueue = DispatchQueue(label: "com.app.rwlock", attributes: .concurrent)
rwQueue.async(flags: .barrier) { /* exclusive write */ }
```

### Never: `DispatchSemaphore.wait()` in async context

```swift
// DEADLOCK -- blocks cooperative thread pool thread
func fetch() async {
    let semaphore = DispatchSemaphore(value: 0)
    Task { semaphore.signal() }
    semaphore.wait() // Pool can be as small as 1 thread
}
```

### Never: `.background` QoS for user-visible work

```swift
// FREEZES in Low Power Mode -- system may halt .background entirely
DispatchQueue.global(qos: .background).async {
    downloadUserRequestedFile() // User is waiting!
}

// FIX: .userInitiated for user-triggered work
DispatchQueue.global(qos: .userInitiated).async { /* ... */ }
```

## Workflows

### Workflow: Review Existing Concurrency Code

**When:** First encounter with a codebase using GCD/OperationQueue.

1. Scan for deadlock patterns using detection checklist (`references/deadlocks.md`)
2. Scan for data race patterns (`references/data-races.md`)
3. Check for thread explosion indicators: `DispatchQueue.global()` scattered throughout, many independent queues, no `maxConcurrentOperationCount` (`references/thread-explosion.md`)
4. Verify lock correctness (`references/thread-safety.md`)
5. Check OperationQueue subclasses for missing KVO/state management (`references/operation-queue.md`)
6. Create `refactoring/` directory with per-feature plans and severity-ranked findings (`references/refactoring-workflow.md`)
7. Execute fixes in phase order: Critical → Thread Safety → Queue Architecture → OperationQueue → Monitoring

### Workflow: Add Thread-Safe Collection

**When:** Need concurrent read/exclusive write access to shared state.

1. Create a custom concurrent queue with descriptive label
2. Implement reads via `queue.sync { return value }`
3. Implement writes via `queue.async(flags: .barrier) { mutate }`
4. Verify barrier is on **custom** queue, never global (`references/thread-safety.md`)
5. Add `dispatchPrecondition` assertions at boundaries
6. Test with `DispatchQueue.concurrentPerform` under Thread Sanitizer

### Workflow: Create AsyncOperation Subclass

**When:** Need OperationQueue with async work (network, disk I/O).

1. Override `isAsynchronous`, `isExecuting`, `isFinished` with thread-safe KVO (`references/operation-queue.md`)
2. Never call `super.start()` -- it marks the operation finished immediately
3. Check `isCancelled` at start, call `finish()` if cancelled
4. Call `finish()` from **every** completion path
5. Check dependency cancellation in `main()` -- cancelled deps satisfy dependencies, they don't block
6. Test with Thread Sanitizer enabled

### Workflow: Migrate GCD Pattern to Swift Concurrency

**When:** Modernizing specific GCD patterns. Not all patterns should migrate.

1. Identify the pattern category (`references/migration.md`)
2. Easy: `DispatchQueue.main.async` -> `@MainActor`, `DispatchGroup` -> `TaskGroup`, serial queue -> `actor`
3. Keep as GCD: `concurrentPerform`, `DispatchIO`, `DispatchSource`, concurrent+barrier reader-writer
4. Bridge callbacks with `withCheckedThrowingContinuation` -- resume **exactly once** on every path
5. Never use `DispatchSemaphore.wait()` in any async context

## Code Generation Rules

<critical_rules>
Whether reviewing, generating, or refactoring concurrent code, every output must be **thread-safe, deadlock-free, and production-ready**. ALWAYS:

1. Label every `DispatchQueue` with reverse DNS naming including subsystem
2. Use serial queues for state protection -- concurrent only when reads vastly outnumber writes
3. Use `defer { group.leave() }` immediately after every `group.enter()`
4. Use `OSAllocatedUnfairLock` (iOS 16+), `NSLock` (any iOS), or `Mutex` (Swift 6+) for short critical sections -- never `os_unfair_lock` as a direct stored property
5. Use `dispatchPrecondition(condition:)` before sync dispatch and UI updates
6. Use `[weak self]` in repeating timer handlers and stored closures
7. Cancel `DispatchSource` timers in deinit (resume first if suspended)
8. Override `isAsynchronous`, `isExecuting`, `isFinished` with KVO in async Operations
9. Set `maxConcurrentOperationCount` on OperationQueues -- never leave unlimited for blocking work
10. Never call `DispatchQueue.main.sync` from any code that might run on the main thread
11. Before generating concurrent code, output a brief `<thought>` analyzing potential deadlocks, races, and retention.
</critical_rules>

## Fallback Strategies & Loop Breakers

<fallback_strategies>
When fixing concurrency bugs, you may encounter cascading issues. If you fail to fix the same issue twice, break the loop:

1. **Deadlock in sync dispatch:** Replace `sync` with `async` and restructure the call site to use a completion handler or continuation. Eliminating `sync` eliminates the deadlock category entirely.
2. **Thread explosion from blocking work:** Wrap blocking calls in Operations with `maxConcurrentOperationCount = 4` instead of trying to make GCD limit threads.
3. **Data race under TSan:** If concurrent queue + barrier is proving fragile, fall back to `NSLock` protecting a plain property. Simpler is safer.
</fallback_strategies>

## Confidence Checks

Before finalizing generated or refactored concurrent code, verify ALL:

```
[] No deadlock risk -- no sync on main, no nested sync on same queue, no ABBA chains
[] No thread explosion -- maxConcurrentOperationCount set, no scattered global() calls
[] No data races -- shared mutable state protected by queue, lock, or actor
[] Queue labels -- every queue has reverse DNS label with subsystem name
[] Barrier correctness -- barriers on custom concurrent queues only, never global
[] Group balance -- every enter() has defer { group.leave() }
[] Timer safety -- [weak self], cancel in deinit, resume before dealloc if suspended
[] Lock safety -- no os_unfair_lock as stored property, no semaphore as mutex
[] Operation KVO -- async operations override isExecuting/isFinished with thread-safe KVO
[] Main thread -- UI updates verified with dispatchPrecondition(.onQueue(.main))
[] Swift Concurrency coexistence -- no semaphore.wait() in async contexts
[] Background tasks -- endBackgroundTask called on every path
```

## References

| Reference | When to Read |
|-----------|-------------|
| `references/queue-creation.md` | Queue types, QoS selection, target queue hierarchies, queue labeling |
| `references/deadlocks.md` | The 5 deadlock patterns, prevention with dispatchPrecondition, lock ordering |
| `references/thread-safety.md` | Lock selection (NSLock, OSAllocatedUnfairLock, Mutex), reader-writer barrier, @Atomic trap, singletons |
| `references/thread-explosion.md` | Thread explosion causes, priority inversion, thread starvation, throttling strategies |
| `references/dispatch-primitives.md` | DispatchGroup, DispatchWorkItem, DispatchSemaphore, DispatchSource timers, DispatchIO |
| `references/operation-queue.md` | AsyncOperation base class, KVO state management, cancellation, dependency graphs |
| `references/data-races.md` | Value type COW races, memory management, main thread violations, real-world fixes |
| `references/debugging.md` | Thread Sanitizer, dispatchPrecondition, Instruments, os_signpost, testing strategies |
| `references/migration.md` | GCD to Swift Concurrency mapping, what to migrate vs keep, bridging with continuations |
| `references/refactoring-workflow.md` | `refactoring/` directory protocol, per-feature plans, PR sizing, verification checklist |
