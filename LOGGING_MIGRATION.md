# Logging Migration Guide

## Performance Issue

Currently, the codebase has extensive `print()` statements that execute in both DEBUG and RELEASE builds. This:
- Impacts performance in production
- Increases binary size
- Potentially leaks implementation details
- Wastes CPU cycles formatting strings that are never seen by users

## Solution: LoggingService

A new `LoggingService` has been created that automatically gates logging based on build configuration.

## Migration Instructions

### Replace print() statements

**Before:**
```swift
print("🎵 SoundVM.\(sound.name) - LOADING: Audio not loaded")
```

**After:**
```swift
LoggingService.logAudio("SoundVM.\(sound.name) - LOADING: Audio not loaded")
```

### Available Methods

```swift
// General logging (DEBUG only)
LoggingService.log("Message")
LoggingService.log("🔊", "Message with prefix")

// Category-specific (DEBUG only)
LoggingService.logAudio("Audio-related message")
LoggingService.logTimer("Timer-related message")
LoggingService.logState("State change message")
LoggingService.logAction("User action message")
LoggingService.logWarning("Warning message")
LoggingService.logSuccess("Success message")
LoggingService.logFlow("Flow/control message")

// Critical errors (ALWAYS logs, even in RELEASE)
LoggingService.logError("Critical error message")
LoggingService.logAlways("Must-see message")
```

### Migration Priority

1. **High Priority** (do first):
   - Any loops or frequently-called methods
   - Timer tick handlers
   - Volume change handlers
   - Fade operations

2. **Medium Priority**:
   - Playback state changes
   - View lifecycle methods
   - Audio session changes

3. **Low Priority** (nice to have):
   - One-time initialization logs
   - Infrequent user actions

### Example Migration

**File: `SoundViewModel.swift`**

```swift
// Before
print("🔊 SoundVM.\(sound.name) - VOLUME CHANGE: \(String(format: "%.2f", oldValue))→\(String(format: "%.2f", volume))")

// After
LoggingService.log("🔊", "SoundVM.\(sound.name) - VOLUME CHANGE: \(String(format: "%.2f", oldValue))→\(String(format: "%.2f", volume))")
```

**File: `TimerService.swift`**

```swift
// Before
if self.remainingSeconds % 10 == 0 || self.remainingSeconds < 10 {
    print("⏱️ TimerSvc - TICK: \(self.remainingTime) remaining")
}

// After
if self.remainingSeconds % 10 == 0 || self.remainingSeconds < 10 {
    LoggingService.logTimer("TimerSvc - TICK: \(self.remainingTime) remaining")
}
```

## Benefits

- **Performance**: Zero overhead in RELEASE builds
- **Clean**: No #if DEBUG scattered throughout code
- **Categorized**: Easy to filter logs by category
- **Consistent**: Standardized logging format
- **Safe**: Critical errors always logged

## Gradual Migration

This doesn't need to be done all at once. Migrate files as you touch them:
1. Import the service: (no import needed, it's in the app module)
2. Replace print statements with LoggingService calls
3. Test in both DEBUG and RELEASE builds

## Testing

```bash
# Verify DEBUG build logs
xcodebuild -project WhiteNoise.xcodeproj -scheme WhiteNoise -configuration Debug build

# Verify RELEASE build has minimal logs
xcodebuild -project WhiteNoise.xcodeproj -scheme WhiteNoise -configuration Release build
```
