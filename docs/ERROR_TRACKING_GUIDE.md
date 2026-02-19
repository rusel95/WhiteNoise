# Error Tracking & Telemetry Guide

This document provides a comprehensive guide to error tracking and telemetry in the WhiteNoise app. All errors and warnings should be captured in Sentry for visibility.

## Table of Contents
1. [Infrastructure Overview](#infrastructure-overview)
2. [Telemetry Service](#telemetry-service)
3. [Best Practices](#best-practices)
4. [Error Categories](#error-categories)
5. [Implementation Checklist](#implementation-checklist)
6. [Common Patterns](#common-patterns)
7. [Sentry Dashboard](#sentry-dashboard)

---

## Infrastructure Overview

### Services
- **TelemetryService** - Centralized Sentry integration for all non-fatal errors
- **LoggingService** - Performance-conscious logging (DEBUG only by default)
- **Sentry SDK** - Configured in WhiteNoiseApp.swift with full profiling enabled

### Key Features
✅ Automatic file/function/line number tracking
✅ Privacy-aware data redaction
✅ Sensitive data filtering (passwords, tokens, keys, credentials, DSNs, API keys)
✅ String length truncation (>1000 chars truncated)
✅ Description truncation (>500 chars truncated)
✅ Three severity levels: `.info`, `.warning`, `.error`
✅ Extra context payloads with automatic sanitization

---

## Telemetry Service

### Basic API

```swift
// Capture a message
TelemetryService.captureNonFatal(
    message: "User completed purchase",
    level: .info  // .info, .warning, or .error
)

// Capture an error with optional message
TelemetryService.captureNonFatal(
    error: someError,
    message: "Failed to load user profile",
    level: .error,
    extra: ["userId": user.id, "retryCount": 3]
)
```

### Automatic Context
All calls automatically capture:
- File path (`source.file`)
- Function name (`source.function`)
- Line number (`source.line`)
- Severity level tag (`telemetry.level`)

### Privacy Protection
The service automatically redacts:
- Keys containing: `password`, `token`, `secret`, `key`, `credential`, `dsn`, `apikey`, `api_key`
- Strings longer than 1000 characters
- CustomStringConvertible descriptions longer than 500 characters

---

## Best Practices

### 1. Always Use TelemetryService for Errors

❌ **BAD** - Only logs to console:
```swift
do {
    try loadData()
} catch {
    print("Error: \(error)")
}
```

✅ **GOOD** - Captures in Sentry:
```swift
do {
    try loadData()
} catch {
    TelemetryService.captureNonFatal(
        error: error,
        message: "Failed to load user data",
        level: .error
    )
}
```

### 2. Include Relevant Context

❌ **BAD** - No context:
```swift
TelemetryService.captureNonFatal(error: error)
```

✅ **GOOD** - Rich context:
```swift
TelemetryService.captureNonFatal(
    error: error,
    message: "Audio file not found for sound",
    extra: [
        "soundId": sound.id,
        "attemptedExtensions": ["m4a", "wav", "aac"].joined(separator: ", "),
        "bundleResourcePath": "Assets/Sounds"
    ]
)
```

### 3. Choose Appropriate Severity

- **`.info`** - Expected behaviors, milestones
  - "User purchased premium"
  - "Trial reminder scheduled"

- **`.warning`** - Unexpected but recoverable issues
  - "Missing audio file, using default"
  - "Customer info fetch failed, using cached data"

- **`.error`** - Critical failures that impact functionality
  - "Sentry initialization failed"
  - "Audio session configuration failed"
  - "RevenueCat SDK initialization failed"

### 4. Never Force Unwrap in Production

❌ **BAD**:
```swift
let value = dict["key"]!  // CRASH!
return try! Sound(...)      // CRASH!
```

✅ **GOOD**:
```swift
guard let value = dict["key"] else {
    TelemetryService.captureNonFatal(
        message: "Missing expected key in dictionary"
    )
    return nil
}

do {
    return try Sound(...)
} catch {
    TelemetryService.captureNonFatal(error: error)
    return nil
}
```

### 5. Handle Weak Self Loss

❌ **BAD** - Silent failure:
```swift
Task { [weak self] in
    let data = await fetchData()
    self?.process(data)  // What if self is nil?
}
```

✅ **GOOD** - Tracked failure:
```swift
Task { [weak self] in
    guard let self = self else {
        TelemetryService.captureNonFatal(
            message: "MyViewController.fetchData lost self",
            level: .warning
        )
        return
    }
    let data = await fetchData()
    self.process(data)
}
```

---

## Error Categories

### By Type

#### 1. **Audio System Errors**
- Files: `AudioSessionService.swift`, `AVAudioPlayerWrapper.swift`, `SoundViewModel.swift`
- Errors: Session setup, file not found, player creation
- Level: `.error`

#### 2. **Data Persistence Errors**
- Files: `SoundPersistenceService.swift`, `SoundConfigurationLoader.swift`
- Errors: JSON encode/decode, UserDefaults access
- Level: `.error`

#### 3. **Subscription/Entitlement Errors**
- Files: `EntitlementsCoordinator.swift`, `RevenueCatService.swift`
- Errors: Customer info fetch, offering load, entitlement verification
- Level: `.warning` (usually fail-open)

#### 4. **Notification Errors**
- Files: `TrialReminderScheduler.swift`
- Errors: Notification scheduling, authorization
- Level: `.warning`

#### 5. **Timer/Task Errors**
- Files: `TimerService.swift`, `RemoteCommandService.swift`
- Errors: Lost weak self, task cancellation
- Level: `.warning`

### By Service

| Service | Type | Key Errors |
|---------|------|-----------|
| AudioSessionService | Audio | Setup failure, interruption handling |
| AVAudioPlayerWrapper | Audio | File not found, player creation |
| SoundViewModel | Audio | Player missing, fade operations |
| EntitlementsCoordinator | Business | Customer info fetch, offering load |
| SoundPersistenceService | Data | JSON encode/decode |
| SoundConfigurationLoader | Data | File load, JSON parsing |
| TrialReminderScheduler | Notifications | Scheduling, auth status |
| TimerService | Concurrency | Weak self loss, cancellation |
| RemoteCommandService | Media | Command handler failures |

---

## Implementation Checklist

### For Every Error-Prone Code Section

- [ ] All `do/catch` blocks capture errors in Sentry
- [ ] All async operations handle failures
- [ ] All weak self captures check for nil
- [ ] All optionals have guards with telemetry on failure
- [ ] No `try!` or force unwraps (except after guards)
- [ ] No `fatalError()` in production code
- [ ] Error messages are descriptive and actionable
- [ ] Extra context is relevant and privacy-safe
- [ ] Appropriate severity level chosen
- [ ] User is informed when critical features fail

### Before Committing Code

- [ ] Run `grep -r "try!" WhiteNoise/` to find force tries
- [ ] Run `grep -r "\.fatalError" WhiteNoise/` to find fatal errors
- [ ] Check for print statements that should be telemetry
- [ ] Review all `catch` blocks for telemetry calls
- [ ] Verify weak self patterns capture failures
- [ ] Test error paths locally via Sentry console

### When Adding New Feature

1. **Identify failure points:**
   - Network requests
   - File I/O
   - Async operations
   - User input validation

2. **Add error handling:**
   - Wrap in try/catch or do/catch
   - Call TelemetryService.captureNonFatal()
   - Provide user feedback

3. **Test error paths:**
   - Simulate network failures
   - Delete/corrupt files
   - Cancel tasks mid-execution
   - Verify Sentry captures events

4. **Review telemetry:**
   - Check Sentry dashboard for new events
   - Verify context is useful for debugging
   - Ensure no sensitive data is exposed

---

## Common Patterns

### Pattern 1: Async Operation with Error Handling

```swift
func loadData() async {
    do {
        let data = try await fetchFromNetwork()
        self.data = data
        print("✅ Data loaded successfully")
    } catch {
        TelemetryService.captureNonFatal(
            error: error,
            message: "Failed to load data from network",
            level: .error,
            extra: ["retryCount": retryCount]
        )
        // Fallback: use cached data
        self.data = getCachedData()
    }
}
```

### Pattern 2: Weak Self Safety

```swift
func startOperation() {
    Task { [weak self] in
        guard let self = self else {
            TelemetryService.captureNonFatal(
                message: "ViewController.startOperation lost self",
                level: .warning
            )
            return
        }

        let result = await self.doWork()
        self.updateUI(with: result)
    }
}
```

### Pattern 3: Resource Loading with Fallback

```swift
func loadSound() throws -> Sound {
    do {
        let sound = try loadFromBundle()
        return sound
    } catch {
        TelemetryService.captureNonFatal(
            error: error,
            message: "Failed to load sound from bundle",
            level: .warning,
            extra: ["soundId": id]
        )
        return createDefaultSound()
    }
}
```

### Pattern 4: Validation with Telemetry

```swift
func validateInput(_ input: String) throws {
    guard !input.isEmpty else {
        TelemetryService.captureNonFatal(
            message: "Input validation failed: empty string",
            level: .warning,
            extra: ["fieldName": "username"]
        )
        throw ValidationError.emptyInput
    }
}
```

### Pattern 5: Graceful Degradation

```swift
func setupAudioSession() {
    do {
        try audioSession.setActive(true)
        TelemetryService.captureNonFatal(
            message: "Audio session activated",
            level: .info
        )
    } catch {
        TelemetryService.captureNonFatal(
            error: error,
            message: "Failed to activate audio session",
            level: .error
        )
        // Continue anyway - audio may still work
    }
}
```

---

## Sentry Dashboard

### Key Metrics to Monitor

1. **Error Rate**: Filter by time period to see trends
2. **Most Common Errors**: Identify patterns and priority bugs
3. **Affected Users**: How many users experience each error
4. **User Segments**: Filter by app version, device, OS
5. **Release Health**: Regression detection across versions

### Dashboard URL
https://ruslanpopesku.sentry.io/

### Useful Filters

```
# Errors in specific service
tags:source.file:*AudioSessionService*

# Errors in version 1.0.0
release:1.0.0

# Critical errors only
level:error

# Last 24 hours
age:-24h

# Specific feature
tags:feature:audio
```

### Setting Up Alerts

1. Go to Alerts → Create Alert Rule
2. Condition: `If level is error`
3. Action: Notify your Slack/email
4. Repeat for warnings if needed

---

## Current Error Tracking Coverage

### ✅ Fully Tracked Services
- AudioSessionService ✅
- AVAudioPlayerWrapper ✅
- SoundPersistenceService ✅
- SoundConfigurationLoader ✅
- EntitlementsCoordinator ✅
- TrialReminderScheduler ✅
- TimerService ✅
- RemoteCommandService ✅
- Sound model validation ✅

### ⚠️ Partially Tracked
- SoundViewModel (most operations tracked, some edge cases missed)
- WhiteNoisesViewModel (basic telemetry, could be expanded)

### 🔧 Recently Fixed
- SoundFactory: Replaced `try!` with proper error handling and Sentry capture

### 🔍 Areas to Monitor
- View initialization errors (currently minimal tracking)
- SwiftUI state management edge cases
- App lifecycle transitions

---

## Migration Guide (Legacy to Modern)

### Old Pattern
```swift
print("ERROR: Something failed")
```

### New Pattern
```swift
TelemetryService.captureNonFatal(
    message: "Something failed",
    level: .error,
    extra: ["context": "value"]
)
```

### When Migrating
1. Keep the print for console visibility
2. Add TelemetryService call for Sentry tracking
3. Include relevant context in `extra` parameter
4. Verify message is descriptive
5. Test in Sentry dashboard

---

## Troubleshooting

### Issue: Events not appearing in Sentry
- Verify REVENUECAT_API_KEY is configured
- Check Sentry DSN in WhiteNoiseApp.swift
- Ensure app has network connectivity
- Check Sentry rate limiting (95% sampling is intentional for performance)

### Issue: Sensitive data in Sentry
- TelemetryService automatically redacts known sensitive keys
- Use generic keys instead of `apiKey`, `token`, `password`
- Always validate extra parameters before sending
- Review redaction patterns in TelemetryService.swift

### Issue: Too much noise
- Adjust severity levels (some warnings → info)
- Use Sentry's dashboard filters
- Consider error grouping improvements
- Disable less critical telemetry

---

## Quick Reference

```swift
// Capture error
TelemetryService.captureNonFatal(error: error)

// Capture with message
TelemetryService.captureNonFatal(
    error: error,
    message: "Failed to load"
)

// Capture with severity
TelemetryService.captureNonFatal(
    message: "Something happened",
    level: .warning
)

// Capture with context
TelemetryService.captureNonFatal(
    error: error,
    message: "Operation failed",
    extra: ["retryCount": 3, "userId": id]
)
```

---

## Contact & Questions

- Sentry Dashboard: https://ruslanpopesku.sentry.io/
- Review logs: Check Xcode console during development
- Debug mode: Set breakpoints in TelemetryService
