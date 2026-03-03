# iOS Security Audit

Enterprise-grade security auditing skill for iOS codebases aligned with OWASP MASVS v2.1.0. Detects vulnerabilities across storage, cryptography, networking, platform integration, and code quality in both Swift and Objective-C.

## What This Skill Changes

| Without Skill | With Skill |
|---|---|
| Ad-hoc security reviews with inconsistent coverage | Structured audit against 24 MASVS controls |
| Missed hardcoded secrets and insecure storage | Pattern-first detection of CRITICAL vulnerabilities |
| No compliance mapping for regulated apps | HIPAA, PCI DSS, GDPR, SOC 2 requirement mapping |
| Generic security advice | Concrete vulnerable/secure code pairs with MASVS traceability |
| Same checklist for all apps | L1/L2/R testing profile-aware severity classification |

## Install

```bash
npx openskills add ios-security-audit
```

Verify by asking your AI assistant to "run a security audit on this iOS project".

## Testing From a Feature Branch

The default `npx openskills add` installs from the `main` branch. To test a skill before it's merged:

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
