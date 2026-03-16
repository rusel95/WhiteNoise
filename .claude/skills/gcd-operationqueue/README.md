# GCD & OperationQueue Concurrency

Enterprise-grade concurrency skill for Grand Central Dispatch and OperationQueue on Apple platforms (iOS, macOS, watchOS, tvOS, visionOS). Prevents the most dangerous concurrency bugs — deadlocks, thread explosion, and data races — through actionable patterns and detection checklists.

## Benchmark Results

Tested on **24 scenarios** (8 topics × 3 difficulty tiers) with **62 assertions**.

### Results Summary

| Model | With Skill | Without Skill | Delta |
| --- | --- | --- | --- |
| **GPT-5.4** | 100% | 72.6% | **+27.4%** |
| **Opus 4.5** | 100% | 81% | **+19%** |
| **Gemini 3.1 Pro** | 100% | 83.9% | **+16.1%** |
| **Sonnet 4.6** | 100% | 93.5% | **+6.5%** |

### Tiered Results (GPT-5.4)

| Difficulty | With Skill | Without Skill | Delta |
| --- | --- | --- | --- |
| Simple | 10/10 (100%) | 10/10 (100%) | **0%** |
| Medium | 22/22 (100%) | 16/22 (72.7%) | **+27.3%** |
| Complex | 30/30 (100%) | 19/30 (63.3%) | **+36.7%** |
| **Total** | **62/62 (100%)** | **45/62 (72.6%)** | **+27.4%** |

### Tiered Results (Sonnet 4.6)

| Difficulty | With Skill | Without Skill | Delta |
| --- | --- | --- | --- |
| Simple | 10/10 (100%) | 10/10 (100%) | **0%** |
| Medium | 22/22 (100%) | 21/22 (95.5%) | **+4.5%** |
| Complex | 30/30 (100%) | 27/30 (90%) | **+10%** |
| **Total** | **62/62 (100%)** | **58/62 (93.5%)** | **+6.5%** |

### Tiered Results (Opus 4.5)

| Difficulty | With Skill | Without Skill | Delta |
| --- | --- | --- | --- |
| Simple | 10/10 (100%) | 9/10 (90%) | **+10%** |
| Medium | 22/22 (100%) | 18/22 (82%) | **+18%** |
| Complex | 30/30 (100%) | 23/30 (77%) | **+23%** |
| **Total** | **62/62 (100%)** | **50/62 (81%)** | **+19%** |

### Tiered Results (Gemini 3.1 Pro)

| Difficulty | With Skill | Without Skill | Delta |
| --- | --- | --- | --- |
| Simple | 10/10 (100%) | 10/10 (100%) | **0%** |
| Medium | 22/22 (100%) | 17/22 (77.3%) | **+22.7%** |
| Complex | 30/30 (100%) | 25/30 (83.3%) | **+16.7%** |
| **Total** | **62/62 (100%)** | **52/62 (83.9%)** | **+16.1%** |

**Interpretation:** The baseline handles the basic GCD cases cleanly, but the skill still adds clear value once the prompts move into Apple-specific and production-hardening details: WWDC 2017-706 queue architecture guidance, target-queue deadlock patterns, `.background` behavior in Low Power Mode, barriers silently ignored on global queues, AsyncOperation KVO requirements, and `dispatchPrecondition` as a proactive debugging guard.

> Raw data:
> `gcd-operationqueue-workspace/iteration-2/benchmark-gpt-5-4-tiered.json`
> `gcd-operationqueue-workspace/iteration-2/benchmark-sonnet-4-6.json`
> `gcd-operationqueue-workspace/iteration-2/benchmark-opus-4-5-tiered.json`
> `gcd-operationqueue-workspace/iteration-2/benchmark-gemini-3-1-pro-tiered.json`

### Benchmark Cost Estimate

| Step | Formula | Tokens |
| --- | --- | --- |
| Eval runs (with_skill) | 24 × 35k | 840k |
| Eval runs (without_skill) | 24 × 12k | 288k |
| Grading (48 runs × 5k) | 48 × 5k | 240k |
| **Total** | | **~1.4M** |
| **Est. cost (Opus 4.5)** | ~$30/1M | **~$41** |
| **Est. cost (Sonnet 4.6)** | ~$5.4/1M | **~$8** |

> Token estimates based on sampled timing.json files. Blended rate ~$30/1M for Opus ($15 input + $75 output, ~80/20 ratio); ~$5.4/1M for Sonnet 4.6 ($3 input + $15 output, ~80/20 ratio).

### Key Discriminating Assertions (GPT-5.4 — missed without skill)

| Topic | Assertion | Why It Matters |
| --- | --- | --- |
| queue-creation | WWDC 2017-706 subsystem-queue guidance | Moves code away from scattered global queues toward controlled concurrency architecture |
| queue-creation | Target queue hierarchy deadlock risk | Prevents nested sync cycles on queues sharing the same root target |
| thread-explosion | `.background` QoS may halt in Low Power Mode | iOS throttles/halts background work |
| thread-explosion | WWDC 2017-706 queue consolidation | 3-4 subsystem queues vs scattered global() |
| thread-explosion | DispatchSemaphore lacks priority donation | Causes priority inversion on lock contention |
| dispatch-primitives | `defer { group.leave() }` pattern | Guarantees balance on all code paths |
| dispatch-primitives | `DispatchSourceTimer` must be cancelled in `deinit` | Prevents timer lifecycle leaks and post-deinit callbacks |
| operation-queue | `maxConcurrentOperationCount` recommendation | Prevents unbounded thread spawning |
| operation-queue | AsyncOperation requires KVO state transitions and must not call `super.start()` | Keeps OperationQueue aware of execution state and avoids immediate-finish bugs |
| debugging | `dispatchPrecondition` at API boundaries | Runtime assertion for queue correctness |

### Key Discriminating Assertions (Gemini 3.1 Pro — missed without skill)

Gemini 3.1 Pro is a stronger baseline (83.9% vs GPT-5.4's 72.6%), handling all simple cases and most production patterns correctly. The 10 remaining gaps are exclusively Apple-specific and WWDC-level details:

| Topic | ID | Assertion | Why It Matters |
| --- | --- | --- | --- |
| queue-creation | Q2.1 | Scattered `global()` calls cause thread explosion and lack control | Root cause of the most common thread explosion pattern |
| queue-creation | Q2.2 | WWDC 2017-706 or 3-4 subsystem queues recommendation | Apple's authoritative guidance for queue architecture |
| queue-creation | Q2.3 | Target queue hierarchies for funneling work | Controls total thread count across subsystems |
| queue-creation | Q3.3 | `.background` QoS may halt in Low Power Mode | Apple silently throttles/halts background queues |
| thread-explosion | E2.2 | `DispatchSemaphore` as mutex lacks priority donation | Priority inversion; NSLock or `os_unfair_lock` required |
| thread-explosion | E3.2 | `.background` QoS may halt entirely in Low Power Mode | Same Apple-specific halting behavior |
| thread-explosion | E3.3 | WWDC 2017-706 / scattered `global()` calls problem | Architecture-level fix for thread explosion |
| thread-safety | T3.3 | `global()` calls may return different queue instances | Barrier writes on assumed-same queue silently become no-ops |
| debugging | G2.3 | `dispatchPrecondition` is removed in release builds | Must not be used as production logic — only as a debug assertion |
| debugging | G3.4 | `dispatchPrecondition` at API boundaries | Proactive contract enforcement at every public concurrent API |

## What This Skill Changes

| Without Skill | With Skill |
| --- | --- |
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
npx skills add git@git.epam.com:epm-ease/research/agent-skills.git --skill gcd-operationqueue --copy
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

## Author

[Ruslan Popesku](https://git.epam.com/Ruslan_Popesku)
