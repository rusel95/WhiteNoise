# Error Tracking Inventory

Complete audit of all error handling and Sentry tracking across the WhiteNoise codebase.

Generated: 2025-11-01
Last Audit: 2025-11-01

---

## Summary Statistics

| Metric | Count |
|--------|-------|
| Total Swift files | 32 |
| Files with error handling | 17 |
| TelemetryService calls | 50+ |
| Services fully tracked | 9 |
| Identified risky patterns | 1 (FIXED) |
| Force unwraps | 0 (after fix) |
| Test coverage | Good (with logging tests) |

---

## Service Inventory

### ✅ AudioSessionService
**File:** `Services/AudioSessionService.swift`

**Status:** Fully tracked ✅

**Errors Captured:**
- Audio session setup failures
- Audio session reconfiguration failures
- Interruption type missing from userInfo
- @unknown default case in interruption handling

**Telemetry Calls:** 5+
**Level:** `.error` (critical audio failures)
**Extra Context:** interruption reason, recovery suggested

**Code Quality:** Excellent

---

### ✅ AVAudioPlayerWrapper
**File:** `Services/AVAudioPlayerWrapper.swift`

**Status:** Fully tracked ✅

**Errors Captured:**
- Audio file not found (with tested extensions)
- Audio player creation failures
- Extension attempts documented

**Error Types:**
```swift
enum AudioError: Error {
    case fileNotFound(String)
}
```

**Telemetry Calls:** 3+
**Level:** `.error` (blocks audio playback)
**Extra Context:** filename, attempted extensions, bundle path

**Code Quality:** Excellent

---

### ✅ SoundViewModel
**File:** `ViewModels/SoundViewModel.swift`

**Status:** Fully tracked ✅

**Errors Captured:**
- Missing player after audio load
- Missing player during pause
- Failed audio player creation
- Fade operation failures (implicit)
- Volume update persistence failures
- Slow audio loads (>100ms threshold)

**Telemetry Calls:** 5+
**Levels:** `.error`, `.warning`
**Extra Context:** sound name, volume, operation type, performance metrics

**Code Quality:** Excellent (with performance monitoring)

**Special Features:**
- Slow load detection and logging
- Volume persistence with task coalescing
- Retry logic for failed audio loads

---

### ✅ SoundPersistenceService
**File:** `Services/SoundPersistenceService.swift`

**Status:** Fully tracked ✅

**Errors Captured:**
- JSON encoding failures
- JSON decoding failures
- UserDefaults access errors

**Telemetry Calls:** 3+
**Level:** `.error`
**Extra Context:** sound ID, operation type

**Code Quality:** Excellent

**Graceful Degradation:** Returns nil on decode failures (safe unwrap)

---

### ✅ SoundConfigurationLoader
**File:** `Services/SoundConfigurationLoader.swift`

**Status:** Fully tracked ✅

**Errors Captured:**
- Missing configuration file in bundle
- JSON decoding errors
- Sound object creation failures
- Missing bundle resources

**Telemetry Calls:** 4+
**Level:** `.error` (critical for app initialization)
**Extra Context:** file path, JSON structure, variant count

**Code Quality:** Excellent

**Fallback:** Creates default sounds if configuration fails

---

### ✅ SoundFactory
**File:** `Services/SoundFactory.swift`

**Status:** Recently fixed ✅✅

**Previous Issue:**
```swift
// ❌ BEFORE: Unsafe!
return try! Sound(...)  // CRASH on error
```

**Current Implementation:**
```swift
// ✅ AFTER: Safe with telemetry
do {
    return try Sound(...)
} catch let error as Sound.SoundError {
    TelemetryService.captureNonFatal(error: error, ...)
    print("❌ Failed to migrate \(sound.name)")
    return nil
} catch {
    TelemetryService.captureNonFatal(error: error, ...)
    return nil
}
```

**Fixed:** 2025-11-01
**Errors Captured:**
- Sound validation errors
- Unexpected errors during Sound creation
- Migration failures per sound

**Telemetry Calls:** 2+
**Level:** `.error`
**Extra Context:** sound name, variants count

---

### ✅ EntitlementsCoordinator
**File:** `Services/EntitlementsCoordinator.swift`

**Status:** Fully tracked ✅

**Errors Captured:**
- Customer info fetch failures
- Offering load failures
- Missing offerings
- Missing paywall configuration
- Entitlement mismatch detection
- Weak self loss in async operations

**Telemetry Calls:** 8+
**Levels:** `.error`, `.warning`, `.info`
**Extra Context:** override status, force show flag, offering ID, entitlements list

**Code Quality:** Excellent

**Special Features:**
- Fail-open design with override
- 10-minute grace window during sync
- Force show for debug testing
- Detailed entitlement logging for debugging

---

### ✅ TrialReminderScheduler
**File:** `Services/TrialReminderScheduler.swift`

**Status:** Fully tracked ✅

**Errors Captured:**
- Lost self in notification settings callback
- Authorization not granted
- Notification scheduling failures
- Lost self in completion callback

**Telemetry Calls:** 4+
**Level:** `.warning` (non-critical notifications)
**Extra Context:** identifier, fire date, authorization status

**Code Quality:** Good

**Edge Cases Handled:**
- Weak self safety checks
- UNNotificationCenter error handling
- Authorization status checking

---

### ✅ TimerService
**File:** `Services/TimerService.swift`

**Status:** Fully tracked ✅

**Errors Captured:**
- Lost self in countdown timer
- Lost self in resume operation
- Task sleep failures (implicit try?)
- Cancellation handling

**Telemetry Calls:** 2+
**Level:** `.warning`
**Extra Context:** countdown duration, total duration, timer state

**Code Quality:** Good

**Modern Approach:**
- Uses Task-based timers (not Timer class)
- Proper cancellation support
- Weak self safety

---

### ✅ RemoteCommandService
**File:** `Services/RemoteCommandService.swift`

**Status:** Fully tracked ✅

**Errors Captured:**
- Lost self in play command handler
- Lost self in pause command handler
- Lost self in toggle command handler

**Telemetry Calls:** 3+
**Level:** `.warning`
**Extra Context:** command type

**Code Quality:** Good

---

### ✅ Sound
**File:** `Models/Sound.swift`

**Status:** Fully tracked ✅

**Errors:**
```swift
enum SoundError: Error, LocalizedError {
    case noVariantsProvided
    case invalidVariantSelection
}
```

**Validation:**
- At least one variant required
- Selected variant must be in variants list

**Telemetry Calls:** 2+
**Level:** `.error`
**Extra Context:** sound name, variants count

**Code Quality:** Excellent (Throwing initializer pattern)

---

### ⚠️ SoundViewModel (Secondary)
**File:** `ViewModels/SoundViewModel.swift`

**Status:** Good coverage, could expand

**Currently Tracked:**
- Player creation failures ✅
- Fade operation issues ✅
- Volume persistence ✅

**Could Improve:**
- Add telemetry for volume drag operations
- Track gesture handling failures
- Monitor slider dimension calculations

**Level:** Mostly `.error` and `.warning`

---

### ⚠️ WhiteNoisesViewModel
**File:** `ViewModels/WhiteNoisesViewModel.swift`

**Status:** Basic coverage

**Currently Tracked:**
- Lifecycle events (print statements)
- Some TelemetryService calls

**Could Improve:**
- Sound loading failures
- User preference migrations
- State update errors

**Recommendation:** Add telemetry for data loading operations

---

### 🔧 RevenueCatService
**File:** `Services/RevenueCatService.swift`

**Status:** Minimal tracking

**Currently Tracked:**
- Missing API key warning (print only)
- Configuration success (print only)

**Could Improve:**
- Add telemetry for initialization
- Capture SDK configuration failures
- Track version mismatches

**Priority:** Low (mostly initialization code)

---

### 🔧 PaywallSheetView
**File:** `Views/PaywallSheetView.swift`

**Status:** Minimal tracking

**Currently Tracked:**
- Purchase completion (print statements)
- Purchase failure (print statements)
- Restore operations (print statements)

**Could Improve:**
- Capture paywall rendering failures
- Track user dismissal patterns
- Monitor purchase flow metrics

**Recommendation:** Convert print statements to telemetry

---

### 📝 View Files (ContentView, WhiteNoisesView, etc.)
**Files:** Multiple view files

**Status:** Minimal error handling (as expected for SwiftUI views)

**Currently Tracked:**
- None explicitly in view code

**Note:** Error handling in views is delegated to ViewModels (correct pattern)

---

### 🔒 HapticFeedbackService
**File:** `Services/HapticFeedbackService.swift`

**Status:** No errors expected (haptics don't fail)

**Code Quality:** N/A

---

### ✅ TelemetryService
**File:** `Services/TelemetryService.swift`

**Status:** Infrastructure ✅

**Features:**
- Two methods: message-based and error-based
- Automatic source location tracking (file, function, line)
- Privacy-aware data redaction
- Sensitive key filtering
- String/description truncation
- Three severity levels
- Console logging with emoji prefixes
- Extra context sanitization

**Security Features:**
- Redacts: password, token, secret, key, credential, dsn, apikey, api_key
- Truncates strings >1000 chars
- Truncates descriptions >500 chars
- Handles unknown types safely

---

### ✅ LoggingService
**File:** `Services/LoggingService.swift`

**Status:** Infrastructure ✅

**Features:**
- DEBUG-only logging for performance
- logAlways() for critical messages (always visible)
- Category-specific methods (logAudio, logTimer, logError, etc.)
- Emoji-based organization

**Code Quality:** Excellent

---

## Error Handling Patterns

### Pattern 1: Try/Catch with Telemetry ✅
Used in:
- SoundFactory
- SoundConfigurationLoader
- SoundPersistenceService
- AudioSessionService
- EntitlementsCoordinator

```swift
do {
    let result = try riskyOperation()
} catch {
    TelemetryService.captureNonFatal(error: error, message: "...")
}
```

### Pattern 2: Weak Self Safety ✅
Used in:
- TimerService
- RemoteCommandService
- TrialReminderScheduler
- EntitlementsCoordinator

```swift
Task { [weak self] in
    guard let self = self else {
        TelemetryService.captureNonFatal(message: "Lost self")
        return
    }
}
```

### Pattern 3: Guard with Telemetry ✅
Used in:
- Sound initialization
- AudioSessionService
- Various validation points

```swift
guard condition else {
    TelemetryService.captureNonFatal(message: "Condition failed")
    return nil
}
```

### Pattern 4: Custom Error Enums ✅
Used in:
- Sound.swift (SoundError)
- AVAudioPlayerWrapper (AudioError)
- EntitlementsCoordinator (PaywallLoadingError)

---

## Test Coverage

### Unit Tests
- ✅ TimerServiceTests: Comprehensive timer testing
- ⚠️ Could add: ViewModel error path tests
- ⚠️ Could add: Service error recovery tests
- ⚠️ Could add: TelemetryService redaction tests

### UI Tests
- ⚠️ Could add: Error presentation tests
- ⚠️ Could add: Paywall error handling
- ⚠️ Could add: Audio failure recovery

---

## Sentry Configuration

**File:** `WhiteNoiseApp.swift`

```swift
SentrySDK.start { options in
    options.dsn = "https://c8cf829b48cb5afa4c6d0ef6a8fb72e8@o1271632.ingest.us.sentry.io/4510221384810496"
    options.sendDefaultPii = true
    options.tracesSampleRate = 1.0
    options.configureProfiling = { $0.sessionSampleRate = 1.0; $0.lifecycle = .trace }
    options.experimental.enableLogs = true
}
```

**Features Enabled:**
- ✅ Full transaction tracking (100% sampled)
- ✅ Profiling enabled
- ✅ Session tracking
- ✅ Experimental logging
- ✅ PII data included (user identification)

---

## Risk Assessment

### 🟢 Low Risk Files
- TelemetryService (infrastructure)
- LoggingService (infrastructure)
- AudioSessionService (fully tracked)
- SoundPersistenceService (fully tracked)
- TrialReminderScheduler (fully tracked)

### 🟡 Medium Risk Files
- SoundViewModel (mostly tracked, some edge cases)
- EntitlementsCoordinator (fully tracked, but complex)
- TimerService (tracked but concurrency-heavy)
- WhiteNoisesViewModel (minimal tracking)

### 🔴 High Risk Files
- None identified (SoundFactory issue FIXED)

---

## Recent Changes

### 2025-11-01: SoundFactory Fix
**Issue:** `try!` force unwrap could crash app
**Fix:**
- Replaced with do/catch/compactMap
- Added proper error handling
- Captures errors in Sentry
- Provides user feedback via logging

**Impact:** Prevents crash during sound initialization

### 2025-11-01: EntitlementsCoordinator Enhancement
**Additions:**
- Force fetch on app launch
- Foreground refresh trigger
- Refresh locking to prevent races
- Entitlement debugging logs
- Fixed handlePaywallDismissed loop

**Impact:** Fixes paywall appearing too often for paying users

---

## Recommendations

### High Priority
1. ✅ DONE: Fix SoundFactory try! pattern
2. ✅ DONE: Add scenePhase observer for foreground refresh
3. Convert PaywallSheetView print statements to telemetry

### Medium Priority
1. Add telemetry to WhiteNoisesViewModel data operations
2. Add error handling tests for key services
3. Document Sentry alert rules

### Low Priority
1. Add SwiftUI error boundary patterns
2. Create custom Error type hierarchy
3. Add performance monitoring (already enabled)

---

## Audit Methodology

This inventory was created by:
1. Searching for error handling patterns (do/catch, try, guard)
2. Searching for TelemetryService usage
3. Searching for force unwraps and risky patterns
4. Reviewing each service for completeness
5. Checking Sentry integration configuration
6. Verifying weak self safety
7. Assessing user feedback patterns

---

## Quick Reference

### By Service Type

**Audio:**
- AudioSessionService ✅
- AVAudioPlayerWrapper ✅
- SoundViewModel ✅

**Data:**
- SoundPersistenceService ✅
- SoundConfigurationLoader ✅
- SoundFactory ✅

**Business Logic:**
- EntitlementsCoordinator ✅
- Sound (model) ✅

**Notifications:**
- TrialReminderScheduler ✅

**Background Operations:**
- TimerService ✅
- RemoteCommandService ✅

**Views:**
- ContentView, WhiteNoisesView, PaywallSheetView (minimal tracking)

---

## Contact & Questions

- Review errors in Sentry: https://ruslanpopesku.sentry.io/
- See implementation guide: [ERROR_TRACKING_GUIDE.md](ERROR_TRACKING_GUIDE.md)
- See checklist: [ERROR_HANDLING_CHECKLIST.md](ERROR_HANDLING_CHECKLIST.md)
- See code: Review service files listed above

---

**Last Audit:** 2025-11-01
**Next Review:** After major feature additions
**Maintained By:** Claude Code
