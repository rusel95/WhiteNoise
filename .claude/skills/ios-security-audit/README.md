# iOS Security Audit

Enterprise-grade security auditing skill for iOS codebases aligned with OWASP MASVS v2.1.0. Detects vulnerabilities across storage, cryptography, networking, platform integration, and code quality in both Swift and Objective-C.

## Benchmark Results

Tested on **24 scenarios** (8 topics × 3 difficulty tiers) with **91 assertions**.

### Results Summary

| Model | With Skill | Without Skill | Delta |
| --- | --- | --- | --- |
| **GPT-5.4** | 100% | 73.6% | **+26.4%** |
| **Opus 4.5** | 93% | 79% | **+14%** |

### Tiered Results (GPT-5.4)

| Difficulty | With Skill | Without Skill | Delta |
| --- | --- | --- | --- |
| Simple | 23/23 (100%) | 21/23 (91.3%) | **+8.7%** |
| Medium | 30/30 (100%) | 23/30 (76.7%) | **+23.3%** |
| Complex | 38/38 (100%) | 23/38 (60.5%) | **+39.5%** |
| **Total** | **91/91 (100%)** | **67/91 (73.6%)** | **+26.4%** |

### Tiered Results (Opus 4.5)

| Difficulty | With Skill | Without Skill | Delta |
| --- | --- | --- | --- |
| Simple | 23/23 (100%) | 18/23 (78%) | **+22%** |
| Medium | 28/30 (93%) | 23/30 (77%) | **+16%** |
| Complex | 34/38 (89%) | 31/38 (82%) | **+7%** |
| **Total** | **85/91 (93%)** | **72/91 (79%)** | **+14%** |

**Interpretation:** In this benchmark, the baseline handled simple scenarios reasonably (91.3%) but missed skill-specific details on medium and complex prompts: exact MASVS and MASWE mappings, L2-vs-L1 requirement boundaries, formal audit-report formatting, HIPAA and PCI citation detail, and Apple-specific privacy-manifest terminology. The gain is concentrated in complex scenarios (+39.5%), where the skill supplies precise implementation and compliance language rather than generic security advice.

### Key Discriminating Assertions (missed without skill)

| Topic | Assertion | Why It Matters |
| --- | --- | --- |
| appstore | `NSPrivacyAccessedAPITypes` must declare API usage reasons | Privacy manifest completeness |
| appstore | `NSPrivacyTrackingDomains` for tracking domains | App Store privacy enforcement |
| audit-process | Maps finding to `MASVS-STORAGE-1` | Audit traceability to MASVS control |
| audit-process | Includes MASWE ID such as `MASWE-0005` | Vulnerability taxonomy precision |
| compliance | Missing biometric auth with server binding for L2 | Correct L2 control boundary |

### Topic Breakdown

| Topic | Simple | Medium | Complex |
| --- | --- | --- | --- |
| storage | **+33%** | 0% | **+75%** |
| crypto | 0% | **+25%** | **+40%** |
| network | 0% | **+50%** | 0% |
| platform | 0% | **+25%** | **+60%** |
| objc | 0% | **+25%** | **+40%** |
| compliance | **+33%** | **+25%** | **+20%** |
| appstore | 0% | **+25%** | **+40%** |
| audit-process | 0% | 0% | **+40%** |

> Raw data:
> `ios-security-audit-workspace/iteration-1/benchmark-gpt-5-4-tiered.json`
> `ios-security-audit-workspace/iteration-1/benchmark-opus-4-5-tiered.json`

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

---

## What This Skill Changes

| Without Skill | With Skill |
| --- | --- |
| Ad-hoc security reviews with inconsistent coverage | Structured audit against 24 MASVS controls |
| Missed hardcoded secrets and insecure storage | Pattern-first detection of CRITICAL vulnerabilities |
| No compliance mapping for regulated apps | HIPAA, PCI DSS, GDPR, SOC 2 requirement mapping |
| Generic security advice | Concrete vulnerable/secure code pairs with MASVS traceability |
| Same checklist for all apps | L1/L2/R testing profile-aware severity classification |

## Install

```bash
npx skills add git@git.epam.com:epm-ease/research/agent-skills.git --skill ios-security-audit
```

Verify by asking your AI assistant to "run a security audit on this iOS project".

## Testing From a Feature Branch

To test a skill before it's merged:

```bash
# 1. Clone the repo (or use an existing clone)
git clone https://github.com/anthropics/agent-skills.git
cd agent-skills
git checkout skill/iOS-security-audit  # or your feature branch

# 2. Copy the skill into your target project
cp -r skills/ios/ios-security-audit /path/to/your-ios-project/.claude/skills/

# 3. Add the skill to your project's CLAUDE.md (or .cursorrules, .github/copilot-instructions.md)
# Add this line to the skills section:
# - **ios-security-audit** — Read `skills/ios/ios-security-audit/SKILL.md` for full instructions.
```

For Claude Code, you can also symlink instead of copying:

```bash
mkdir -p /path/to/your-ios-project/.claude/skills/
ln -s "$(pwd)/skills/ios/ios-security-audit" /path/to/your-ios-project/.claude/skills/ios-security-audit
```

This way your local changes are immediately reflected without re-copying. Remove the symlink after testing.

## When to Use

- Reviewing iOS code for security vulnerabilities
- Pre-release security gate checks
- Auditing Keychain usage and data storage patterns
- Checking ATS configuration and certificate pinning
- Detecting hardcoded secrets, weak cryptography, or insecure randomness
- Reviewing Objective-C runtime attack surface
- Mapping compliance requirements (HIPAA, PCI DSS, GDPR, SOC 2)
- Validating WebView security and URL scheme handlers
