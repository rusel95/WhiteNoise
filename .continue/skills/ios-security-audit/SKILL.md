---
name: ios-security-audit
description: "Enterprise skill for iOS security auditing against OWASP MASVS v2.1.0 (24 controls, 8 categories). This skill should be used when reviewing iOS code for security vulnerabilities, auditing Keychain and storage usage, checking ATS and network configuration, detecting hardcoded secrets or weak cryptography, reviewing Objective-C runtime attack surface, validating certificate pinning, auditing WebView security, checking biometric auth implementation, assessing jailbreak detection, reviewing URL scheme handlers, or mapping compliance requirements (HIPAA, PCI DSS, GDPR, SOC 2). Covers both Swift and Objective-C codebases with detection patterns, vulnerable/secure code pairs, and MASVS control mappings."
metadata:
  version: 1.1.3
---

# iOS Security Audit

Production-grade security auditing skill for iOS codebases aligned with OWASP MASVS v2.1.0. Operates pattern-first — high-confidence string/regex detection for CRITICAL issues, then semantic reasoning for HIGH/MEDIUM issues requiring data-flow understanding. Covers both Swift and Objective-C with language-appropriate detection strategies.

The audit produces a structured finding report with severity, location, MASVS mapping, risk explanation, and concrete fix. Every finding links to a MASVS control and, where applicable, a MASWE weakness ID.

## Audit Scope Overview

```
MASVS v2.1.0 — 8 Categories, 24 Controls
├── STORAGE (2)  — Keychain, Data Protection, leakage vectors
├── CRYPTO (2)   — Algorithms, key management, randomness
├── AUTH (3)     — Protocol, local auth, step-up
├── NETWORK (2)  — ATS/TLS, certificate pinning
├── PLATFORM (3) — URL schemes, WebViews, UI security
├── CODE (4)     — Platform version, updates, deps, input validation
├── RESILIENCE (4) — Integrity, tampering, static/dynamic analysis
└── PRIVACY (4)  — Minimization, transparency, control, lifecycle
```

## Quick Decision Trees

### What severity level applies?

```
Is the issue exploitable without physical device access?
├── YES → Is sensitive data (credentials, PII, keys) exposed?
│   ├── YES → 🔴 CRITICAL
│   └── NO  → 🟡 HIGH
└── NO  → Does the issue weaken defense-in-depth?
    ├── YES → 🟢 MEDIUM
    └── NO  → 🔵 LOW
```

### Which language audit strategy to apply?

```
Does the file use Objective-C (.m, .mm, .h with ObjC)?
├── YES → Apply ObjC runtime checks (swizzling, KVC, format strings)
│         AND standard checks → Read references/objc-specific.md
└── NO  → Pure Swift?
    ├── YES → Apply Swift-specific patterns (CryptoKit, actors)
    └── NO  → Mixed — apply BOTH checklists per file type
```

### Is this an L2/regulated app?

```
Does the app handle financial, health, government, or payment data?
├── YES → L2 audit: encryption mandatory, pinning required,
│         compliance mapping needed → Read references/compliance-mapping.md
└── NO  → Does the app store any PII?
    ├── YES → L1+ audit: standard + privacy controls
    └── NO  → L1 audit: standard security controls
```

## Severity Definitions

- **🔴 CRITICAL** — Directly exploitable. Hardcoded secrets, plaintext credentials in UserDefaults, disabled ATS globally, insecure deserialization, hardcoded crypto keys/IVs. Flag immediately.
- **🟡 HIGH** — Significant risk requiring context. Missing certificate pinning, deprecated crypto, ECB mode, insecure randomness, UIWebView usage, PII in logs, format string vulnerabilities.
- **🟢 MEDIUM** — Defense-in-depth gaps. Missing jailbreak detection (L2 apps), absent screenshot prevention, unvalidated URL scheme handlers, biometric auth without server binding.
- **🔵 LOW** — Best practices. CommonCrypto where CryptoKit available, debug logging not gated, missing privacy manifest, overly broad entitlements.

## Audit Process

1. **Discover project structure** — Before scanning, analyze the project to understand audit scope:
   - List targets (main app, extensions, widgets, watch app)
   - List dependencies (Podfile, Package.swift, Carthage)
   - Identify languages present (Swift-only, ObjC-only, mixed)
   - Count source files to estimate audit cost
   - Present scope options to the user:
     - **Main target only** — fastest, covers primary app code
     - **All targets** — includes extensions, widgets, watch app
     - **Main target + dependencies** — audits third-party code too (useful for supply chain review)
     - **Specific target** — user specifies which target to audit
2. **Identify testing profile** — Determine L1/L2/R from app category and data sensitivity
3. **Run quick scan** — For maximum coverage, use both: run `scripts/quick-scan.sh` locally (whole-repo grep, zero tokens, deterministic) AND use your own search tools to scan for CRITICAL patterns. The script catches literals across every file regardless of depth; agent search catches patterns requiring multi-file context or semantic understanding. Neither alone is sufficient.
4. **Audit Info.plist** — Check ATS, URL schemes, permissions, privacy keys → Read `references/plist-audit.md`
5. **Audit storage** — Search for UserDefaults with sensitive keys, Keychain accessibility levels, file protection
6. **Audit cryptography** — Detect deprecated algorithms, weak randomness, hardcoded keys/IVs
7. **Audit network** — Verify TLS enforcement, certificate pinning implementation, ATS exceptions
8. **Audit platform** — Review URL scheme handlers, WebView configuration, IPC boundaries
9. **Audit ObjC surface** — If ObjC present, check runtime attack vectors → Read `references/objc-specific.md`
10. **Audit resilience** — For L2/R apps, verify jailbreak/debugger/Frida detection layers
11. **Map compliance** — For regulated apps, verify HIPAA/PCI/GDPR/SOC2 requirements → Read `references/compliance-mapping.md`
12. **Check App Store rejection risks** — Verify UIWebView, privacy manifest, ATT, entitlements → Read `references/appstore-rejections.md`
13. **Generate report** — Output findings using the report template → Read `references/audit-workflow.md`
14. **Output MASVS Coverage Matrix** — Always the final section of every report. Fill all 8 rows with real counts and status icons. This step is mandatory even if the user did not explicitly request it.

## Finding Report Template

```
### [SEVERITY] [Short title]

**File:** `path/to/file.swift:42`
**MASVS:** MASVS-[CATEGORY]-[N] | MASWE-[NNNN]
**Issue:** [1-2 sentence description of the vulnerability]
**Risk:** [What an attacker can achieve]
**Fix:**
```swift
// ✅ Secure replacement code
```
```

## Core Detection Patterns (CRITICAL)

> For complete patterns with code pairs, read `references/critical-patterns.md`

| # | Pattern | Search for |
|---|---------|-----------|
| C1 | Hardcoded secrets | String literals assigned to vars named `apiKey`, `secret`, `password`, `PRIVATE_KEY`, `client_secret`; `Bearer ` prefix in literals |
| C2 | Sensitive data in UserDefaults | `UserDefaults.standard.set(` with keys containing password/token/secret/credential/sessionId |
| C3 | Globally disabled ATS | `NSAllowsArbitraryLoads` = `true`/`YES` in Info.plist |
| C4 | Hardcoded crypto keys | Byte arrays or string literals used as encryption key parameters |
| C5 | Insecure deserialization | `NSKeyedUnarchiver.unarchiveObject(` — use `unarchivedObject(ofClass:from:)` |
| C6 | Hardcoded/zero IVs | `Data(repeating: 0, count:` or string literals used as IV/nonce |

## Workflows

### Workflow: Full Security Audit

**When:** User requests "security audit", "security review", or "find vulnerabilities"

#### Phase 0: Discover & Scope Gate (MANDATORY — do not skip, do not start scanning yet)

1. **Discover project structure:**
   - Scan for `.xcodeproj`/`.xcworkspace` — list all targets (main app, extensions, widgets, watch app)
   - Scan for `Podfile`/`Package.swift`/`Cartfile` — list dependencies and count them
   - Count `.swift` files and `.m`/`.mm` files per target separately
   - Detect languages: Swift-only / ObjC-only / Mixed

2. **Present the Scope Menu — ask the user to choose BEFORE proceeding:**

   Output exactly this block (fill in real numbers from discovery):

   ```
   ## 🔍 iOS Security Audit — Scope Selection

   **Project:** [App name]
   **Targets found:** [list: MainApp (42 .swift), ShareExtension (8 .swift), ...]
   **Dependencies:** [N pods / N SPM packages]
   **Languages:** [Swift-only / Mixed Swift+ObjC]

   ### Target scope — which code to scan?

   | Option | Scope | Files | Est. time | Est. tokens |
   |--------|-------|-------|-----------|-------------|
   | A | Main target only | ~N files | fast (~5 min) | ~15–25k |
   | B | All targets (incl. extensions) | ~N files | medium (~10 min) | ~30–50k |
   | C | Main target + dependencies | ~N files | slow (~20 min) | ~60–100k |
   | D | Specific target (tell me which) | ? | varies | varies |

   **Recommended:** A for first audit, C for supply chain review.

   ### MASVS depth — how thorough?

   | Option | Coverage | What's included | Est. tokens (delta) |
   |--------|----------|-----------------|---------------------|
   | 1 | Critical only | CRITICAL patterns + Info.plist | baseline |
   | 2 | Essential (recommended) | + HIGH patterns + NETWORK + AUTH | +8–12k |
   | 3 | Full MASVS (all 8 categories) | + MEDIUM/LOW + RESILIENCE + PRIVACY | +15–25k |
   | 4 | Full MASVS + compliance mapping | + HIPAA/PCI/GDPR gaps | +20–35k |

   **Recommended:** Option 2 for most apps, Option 3 for regulated/fintech/health apps.

   ### Testing profile

   | Option | Profile | When |
   |--------|---------|------|
   | L1 | Standard | General-purpose apps |
   | L2 | Enhanced | Finance, health, government, payment |
   | R  | Resilience | Apps requiring anti-tampering/obfuscation |

   **Reply with your choices, e.g.: A2L1 or B3L2**
   ```

3. **Wait for user response. Do not begin scanning until scope is confirmed.**

#### Phase 1: Audit (after scope confirmed)

4. Determine testing profile (L1/L2/R) from user choice or app category
5. Read `references/critical-patterns.md` — scan selected scope for CRITICAL patterns
6. Read `references/plist-audit.md` — audit Info.plist and entitlements
7. If MASVS depth ≥ 2: Read `references/high-patterns.md` — scan for HIGH severity patterns
8. If Objective-C files present → Read `references/objc-specific.md`
9. If MASVS depth ≥ 3: Read `references/medium-low-patterns.md` — scan for defense-in-depth gaps
10. If L2/R and depth ≥ 3: audit resilience — jailbreak/debugger/Frida detection layers
11. If depth = 4: Read `references/compliance-mapping.md` — HIPAA/PCI/GDPR/SOC2 gaps
12. Read `references/appstore-rejections.md` — check App Store rejection risks (AS1-AS9)

#### Phase 2: Report

13. Compile findings using the report template → Read `references/audit-workflow.md`
14. **Output the MASVS Coverage Matrix** — mandatory final section. Fill all 8 rows with real counts and status icons. Mark categories not audited (due to scope choice) as `—`. Use the template from `references/audit-workflow.md`.
15. Summarize: total findings by severity, rejection risks, top 3 recommendations

### Workflow: Targeted Pattern Check

**When:** User asks about a specific category — "check my crypto", "review network security", "audit storage"

1. Identify which MASVS category maps to the request → Read `references/masvs-mapping.md`
2. Read the relevant patterns reference file
3. Scan only the relevant code areas
4. Report findings for that category with MASVS mapping

### Workflow: Pre-Release Security Gate

**When:** User asks "is this ready for release" or "security checklist"

1. Run all CRITICAL pattern checks — any CRITICAL finding blocks release
2. Run HIGH pattern checks — each needs risk acceptance or fix
3. Read `references/appstore-rejections.md` — run App Store rejection checklist (AS1-AS9)
4. For L2 apps: verify encryption, pinning, and compliance requirements
5. Output pass/fail gate with blocking issues and rejection risks listed

### Workflow: Fix Guidance

**When:** User asks "how do I fix this" or "secure alternative for X"

1. Identify the insecure pattern in use
2. Provide the secure replacement with full context
3. Reference the MASVS control and rationale
4. If migration is complex (e.g., NSCoding → NSSecureCoding), provide step-by-step migration

### Cost Optimization for Large Codebases

Full audits on large codebases (500+ Swift files) consume significant tokens. Use a tiered approach:

1. **Run `scripts/quick-scan.sh` first** — zero token cost, whole-repo grep for CRITICAL/HIGH patterns across every file. Paste output into the conversation.
2. **Agent scans in parallel with own tools** — grep-based CRITICAL/HIGH detection using search tools covers patterns requiring context the script misses (multi-line calls, indirect key references, data-flow). Both together = maximum depth.
3. **Use Sonnet for contextual analysis** — data-flow reasoning, false-positive filtering, cross-file checks
4. **Use Sonnet/Opus for fix generation** — secure replacement code must be correct

This reduces audit cost by 60-80%. See `references/audit-workflow.md` for detailed model-to-phase mapping.

<critical_rules>
## Code Review Rules

1. Every `UserDefaults.standard.set` call handling sensitive data is a CRITICAL finding — recommend Keychain with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
2. `NSAllowsArbitraryLoads = true` in Info.plist is CRITICAL unless every domain has a justified `NSExceptionDomains` entry
3. `NSKeyedUnarchiver.unarchiveObject(` is CRITICAL — always recommend `unarchivedObject(ofClass:from:)` with `requiresSecureCoding = true`
4. String literals containing what appears to be API keys, tokens, or passwords assigned to variables are CRITICAL — recommend secure configuration management
5. `kCCOptionECBMode` is always HIGH — ECB mode preserves plaintext patterns
6. `kSecAttrAccessibleAlways` and `kSecAttrAccessibleAlwaysThisDeviceOnly` are HIGH — deprecated since iOS 12
7. `rand()`, `random()`, `srand()` in any security context are HIGH — recommend `SecRandomCopyBytes`
8. `UIWebView` is HIGH — deprecated since iOS 12, App Store rejection since April 2020
9. `NSLog` or `print` with variables named password/token/ssn/creditCard is HIGH — logs persist to system log
10. `LAContext.evaluatePolicy` without server-side cryptographic binding is MEDIUM — biometric result is bypassable
11. For Objective-C files, `NSLog(variable)` without format specifier is HIGH — format string vulnerability
12. Keychain queries without explicit `kSecAttrAccessible` inherit the default (`kSecAttrAccessibleWhenUnlocked`) — flag as informational for L2 apps
</critical_rules>

<fallback_strategies>
## Fallback Strategies & Loop Breakers

**If unable to determine data sensitivity for UserDefaults:**
Ask the user what data the key stores. If the key name is ambiguous, flag as informational with a note to verify.

**If Info.plist is not found:**
Check for multiple targets (look in each `.xcodeproj` target's build settings for `INFOPLIST_FILE`). Also check for `.plist` files generated by build tools.

**If the codebase uses a third-party networking library:**
Check Alamofire's `ServerTrustManager`, Moya's plugins, or URLSession wrappers for pinning configuration. The absence of pinning in a wrapper doesn't mean it's missing — check the underlying configuration.
</fallback_strategies>

## Confidence Checks

Before finalizing the audit report, verify:

```
[ ] Every CRITICAL finding has been double-checked for false positives
[ ] Findings include file path, line number, and MASVS mapping
[ ] Secure code fixes compile and follow current API (no deprecated replacements)
[ ] L1 vs L2 distinction is applied — L2 controls not flagged as failures for L1 apps
[ ] Objective-C runtime checks applied only to ObjC files
[ ] Info.plist findings cross-referenced with actual code behavior
[ ] No duplicate findings for the same root cause
[ ] Summary includes total count by severity and top recommendations
```

## Companion Skills

> **If the audit uncovers concurrency-related vulnerabilities:** load the appropriate companion skill for fix patterns.

| Finding type | Companion skill | Apply when |
|---|---|---|
| TOCTOU races, token refresh races, actor double-spend | `skills/swift-concurrency/SKILL.md` | Fixing async security bugs, serializing token refresh with actors, TOCTOU prevention |
| Data races in `DispatchQueue` code, unprotected shared state | `skills/gcd-operationqueue/SKILL.md` | Fixing reader-writer races, adding barrier-based synchronization, thread-safe collections |

## References

| Reference | When to Read |
|-----------|-------------|
| `references/rules.md` | Do's and Don'ts quick reference: priority rules and critical audit anti-patterns |
| `references/critical-patterns.md` | Every audit — CRITICAL detection patterns with vulnerable/secure code pairs |
| `references/high-patterns.md` | Every audit — HIGH severity patterns with context requirements |
| `references/medium-low-patterns.md` | Full audits — defense-in-depth and best practice checks |
| `references/objc-specific.md` | When Objective-C files are present — runtime attack surface |
| `references/plist-audit.md` | Every audit — Info.plist and entitlements security checks |
| `references/compliance-mapping.md` | L2/regulated apps — HIPAA, PCI DSS, GDPR, SOC 2, FDA 21 CFR Part 11 requirements |
| `references/audit-workflow.md` | Audit report template, cost optimization (Sonnet tiers), and structured remediation tracking |
| `references/appstore-rejections.md` | Pre-release — App Store rejection patterns (UIWebView, privacy manifest, ATT, ATS, entitlements) |
| `references/masvs-mapping.md` | Reference — MASVS control to detection pattern mapping |
