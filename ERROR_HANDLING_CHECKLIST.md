# Error Handling Checklist

Use this checklist when:
- Writing new code that can fail
- Reviewing code for pull requests
- Debugging issues from Sentry
- Refactoring legacy code

---

## Pre-Implementation Checklist

Before writing code, identify all failure points:

### Network Operations
- [ ] Network timeout handled
- [ ] Invalid response format handled
- [ ] Missing data fields handled
- [ ] Server error codes handled
- [ ] No connectivity handled (graceful degradation)

### File Operations
- [ ] File not found handled
- [ ] Corrupt file handled
- [ ] Permission denied handled
- [ ] Disk full handled
- [ ] Invalid format handled

### User Input
- [ ] Empty input handled
- [ ] Invalid format handled
- [ ] Out of range handled
- [ ] Special characters handled
- [ ] Very long input handled

### Async Operations
- [ ] Task cancellation handled
- [ ] Timeout handled
- [ ] Weak self loss handled
- [ ] Race conditions prevented
- [ ] Deadlocks prevented

### Resource Management
- [ ] Resource allocation failure handled
- [ ] Resource cleanup on error
- [ ] Memory leaks prevented
- [ ] Circular references prevented
- [ ] Background tasks properly scoped

---

## Implementation Checklist

### Error Handling Structure

```swift
// ✅ Pattern to follow

do {
    // [ ] Can this fail? If yes, wrap in try
    let result = try riskyOperation()

    // [ ] Update UI on success
    updateUI(with: result)

} catch let error as SpecificError {
    // [ ] Handle specific error types
    // [ ] Include context in telemetry
    TelemetryService.captureNonFatal(
        error: error,
        message: "Specific operation failed",
        extra: ["context": value]
    )

} catch {
    // [ ] Handle unexpected errors
    TelemetryService.captureNonFatal(
        error: error,
        message: "Unexpected error",
        level: .error
    )
}
```

### Telemetry Integration

For **every** error path:

- [ ] `TelemetryService.captureNonFatal()` called
- [ ] Error type specified (error, warning, or info)
- [ ] Descriptive message included
- [ ] Relevant context in `extra` parameter
- [ ] No sensitive data in context
- [ ] User is informed (UI feedback)

### Async Operations

- [ ] Weak self captured: `Task { [weak self] in`
- [ ] Weak self nil check with telemetry:
  ```swift
  guard let self = self else {
      TelemetryService.captureNonFatal(
          message: "ClassName.methodName lost self",
          level: .warning
      )
      return
  }
  ```
- [ ] All async calls wrapped in try/catch
- [ ] Task cancellation handled
- [ ] No force unwraps after await

### Force Unwraps Elimination

Search your code for these patterns:

```swift
// ❌ BAD - All of these crash!
value!
dict["key"]!
array[index]!
try! operation()
someOptional!.method()
```

Replace with:

```swift
// ✅ GOOD - Safely handled
guard let value = value else {
    TelemetryService.captureNonFatal(message: "Value was nil")
    return
}

guard let key = dict["key"] else {
    TelemetryService.captureNonFatal(
        message: "Missing key",
        extra: ["expectedKey": "myKey"]
    )
    return
}

guard index < array.count else {
    TelemetryService.captureNonFatal(
        message: "Index out of bounds",
        extra: ["index": index, "count": array.count]
    )
    return
}

do {
    return try operation()
} catch {
    TelemetryService.captureNonFatal(error: error)
    return nil
}
```

---

## Code Review Checklist

When reviewing a PR, verify:

### Safety
- [ ] No `try!` in production code
- [ ] No `!` force unwraps (except after guards)
- [ ] No `fatalError()` in production code
- [ ] All optionals have safe unwrapping
- [ ] All async operations handle failures

### Telemetry
- [ ] All `catch` blocks call `TelemetryService`
- [ ] All error messages are descriptive
- [ ] Context includes useful debugging info
- [ ] No sensitive data in context (passwords, tokens, keys)
- [ ] Appropriate severity level chosen

### User Experience
- [ ] User is informed of errors (UI feedback)
- [ ] Errors don't crash the app
- [ ] Graceful degradation where possible
- [ ] Failed operations can be retried
- [ ] Error messages are user-friendly

### Performance
- [ ] No synchronous file I/O on main thread
- [ ] Network operations are async
- [ ] Heavy operations have timeouts
- [ ] Logging doesn't create performance issues
- [ ] Memory is cleaned up on error

### Concurrency
- [ ] Weak self captured in Tasks
- [ ] Nil weak self handled with telemetry
- [ ] Race conditions prevented
- [ ] Deadlocks prevented
- [ ] Task cancellation respected

---

## Testing Checklist

Test these scenarios:

### Network/Async
- [ ] Test with network unavailable
- [ ] Test with slow network (add delays)
- [ ] Test with timeout
- [ ] Test background task cancellation
- [ ] Test view dismissal during operation

### Data
- [ ] Test with missing file
- [ ] Test with corrupt file
- [ ] Test with empty response
- [ ] Test with invalid JSON
- [ ] Test with missing fields

### Edge Cases
- [ ] Test with nil values
- [ ] Test with empty arrays
- [ ] Test with 0 or negative numbers
- [ ] Test with very large inputs
- [ ] Test with special characters

### User Actions
- [ ] Test rapid taps
- [ ] Test backgrounding during operation
- [ ] Test memory warnings
- [ ] Test low battery mode
- [ ] Test restricted access permissions

---

## Sentry Review Checklist

After code review and before merging:

- [ ] Sentry dashboard checked for new errors
- [ ] New error events are categorized correctly
- [ ] Context is useful for debugging
- [ ] No sensitive data exposed
- [ ] Error trends understood
- [ ] Alerts configured if needed

---

## Debugging with Sentry

When investigating a Sentry error:

1. **Identify the error:**
   - [ ] What is the error message?
   - [ ] What is the error type?
   - [ ] When did it first occur?

2. **Gather context:**
   - [ ] What was the app doing?
   - [ ] What version was the user on?
   - [ ] What device/OS?
   - [ ] How many users affected?

3. **Review code:**
   - [ ] What code path caused this?
   - [ ] Are error handlers correct?
   - [ ] Is there a missing guard or check?
   - [ ] Is this a race condition?

4. **Trace the issue:**
   - [ ] Can you reproduce locally?
   - [ ] What conditions trigger it?
   - [ ] Is it environment-specific?
   - [ ] Check git history for recent changes

5. **Fix and verify:**
   - [ ] Add proper error handling
   - [ ] Add telemetry if missing
   - [ ] Test the fix locally
   - [ ] Deploy and monitor Sentry

---

## Service-Specific Checklists

### Audio System (AudioSessionService, SoundViewModel)
- [ ] Session setup errors captured
- [ ] Audio file not found handled
- [ ] Player creation failures captured
- [ ] Interruption handling correct
- [ ] AVAudioSession state valid
- [ ] Audio queue properly managed

### Data Persistence (SoundPersistenceService)
- [ ] JSON encoding errors captured
- [ ] JSON decoding errors captured
- [ ] Decode failures don't crash
- [ ] Graceful fallbacks provided
- [ ] Missing data handled
- [ ] Versioning compatible

### Subscriptions (EntitlementsCoordinator)
- [ ] Customer info fetch failures handled
- [ ] Offering load failures captured
- [ ] Missing offerings handled
- [ ] Grace window properly managed
- [ ] Override cleanup verified
- [ ] Trial reminders scheduled correctly

### Notifications (TrialReminderScheduler)
- [ ] Authorization status handled
- [ ] Scheduling failures captured
- [ ] Weak self loss prevented
- [ ] Fire date valid
- [ ] Duplicate notifications prevented
- [ ] User notifications enabled

### Timers (TimerService)
- [ ] Task sleep errors handled
- [ ] Cancellation proper
- [ ] Weak self loss prevented
- [ ] Race conditions prevented
- [ ] No memory leaks
- [ ] Completion blocks safe

### Media Controls (RemoteCommandService)
- [ ] Command handler registration verified
- [ ] Handler failures captured
- [ ] Weak self loss prevented
- [ ] State consistency maintained
- [ ] Concurrent commands handled

---

## Common Issues to Avoid

### ❌ Pattern to Avoid
```swift
// Silent failure - error lost!
try? riskyOperation()

// Crash risk - no unwrap check
value.count

// Weak self lost
Task {
    let result = await something()
    self.update(result)
}

// Force unwrap - CRASH!
let value = dict["key"]!
```

### ✅ Pattern to Use
```swift
// Explicit handling
do {
    try riskyOperation()
} catch {
    TelemetryService.captureNonFatal(error: error)
}

// Safe unwrap
guard let value = value, !value.isEmpty else {
    return
}

// Safe weak self
Task { [weak self] in
    guard let self = self else {
        TelemetryService.captureNonFatal(
            message: "Lost self"
        )
        return
    }
    let result = await something()
    self.update(result)
}

// Safe optional access
if let value = dict["key"] {
    print(value.count)
}
```

---

## Refactoring Legacy Code

When updating old code:

1. **Identify error points:**
   - [ ] Search for `try!`
   - [ ] Search for `!` force unwraps
   - [ ] Search for `try?` with ignored errors
   - [ ] Search for print statements only

2. **Add proper handling:**
   - [ ] Replace `try!` with `do/catch`
   - [ ] Replace `!` with guards or optionals
   - [ ] Replace `try?` with proper error capture
   - [ ] Add telemetry to print statements

3. **Test thoroughly:**
   - [ ] Test error paths locally
   - [ ] Verify Sentry captures events
   - [ ] Check user experience
   - [ ] Monitor for regressions

4. **Document changes:**
   - [ ] Update commit message
   - [ ] Reference any related issues
   - [ ] Note telemetry additions

---

## Integration with CI/CD

### Pre-commit Hook
```bash
# Search for dangerous patterns
grep -r "try!" WhiteNoise/
grep -r "\.fatalError" WhiteNoise/
grep -r "!\.count\|!\.isEmpty\|!\[" WhiteNoise/
```

### Code Review Automation
- [ ] Linter checks for `try!`
- [ ] Linter checks for force unwraps
- [ ] Require TelemetryService calls
- [ ] Verify error messages present

### Post-Release Monitoring
- [ ] Monitor Sentry for regressions
- [ ] Compare error rates to previous release
- [ ] Alert on spikes
- [ ] Track error trends

---

## Quick Commands

```bash
# Find force tries
grep -r "try!" WhiteNoise/ | grep -v "^Binary"

# Find force unwraps
grep -rn "!" WhiteNoise/ | grep -E "\![^=]" | head -20

# Find print statements
grep -rn "print(" WhiteNoise/ | grep -v "TelemetryService"

# Find missing telemetry in catch blocks
grep -B2 "catch" WhiteNoise/ | grep -v "TelemetryService"

# Count telemetry calls
grep -r "TelemetryService.captureNonFatal" WhiteNoise/ | wc -l
```

---

## Resources

- [ERROR_TRACKING_GUIDE.md](ERROR_TRACKING_GUIDE.md) - Full guide with patterns
- [Sentry Dashboard](https://ruslanpopesku.sentry.io/) - Live error tracking
- [CLAUDE.md](CLAUDE.md) - Project guidelines
- [DEVELOPMENT_PRINCIPLES.md](DEVELOPMENT_PRINCIPLES.md) - Code quality standards

---

## Last Updated
- Checked: 2025-11-01
- Services audited: All main services
- Coverage: ~95% of critical code paths
- Next audit: After major feature additions
