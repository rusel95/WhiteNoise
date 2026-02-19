# Firebase Integration Guide

Complete guide for Firebase Analytics and Crashlytics integration in WhiteNoise.

## Overview

Firebase is integrated for:
- **Firebase Analytics** - User behavior tracking and analytics (disabled in DEBUG)
- **Firebase Crashlytics** - Crash reporting (disabled in DEBUG, using Sentry instead)

## SDK Installation

Firebase SDK is already added via Swift Package Manager:
- Package: `https://github.com/firebase/firebase-ios-sdk.git`
- Products included:
  - `FirebaseAnalytics`
  - `FirebaseCrashlytics`

## Configuration

### Option 1: Using GoogleService-Info.plist (Recommended)

1. **Download GoogleService-Info.plist:**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Select your project
   - Go to Project Settings → General
   - Download `GoogleService-Info.plist`

2. **Add to Xcode:**
   - Drag `GoogleService-Info.plist` into your Xcode project
   - Make sure "Copy items if needed" is checked
   - Add to WhiteNoise target

3. **Done!**
   - `FirebaseService` will automatically detect and use this file

---

### Option 2: Manual Configuration via xcconfig

If you prefer not to use the plist file, configure via xcconfig:

1. **Get Firebase Configuration:**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Select your project → Project Settings → General
   - Find your iOS app configuration

2. **Update Local.xcconfig:**
   ```bash
   FIREBASE_API_KEY = AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXX
   FIREBASE_GCM_SENDER_ID = 123456789012
   FIREBASE_PROJECT_ID = your-project-id
   FIREBASE_GOOGLE_APP_ID = 1:123456789012:ios:abcdef1234567890
   FIREBASE_STORAGE_BUCKET = your-project-id.appspot.com
   ```

3. **Where to find each value:**
   - **API Key**: `apiKey` in Firebase config
   - **GCM Sender ID**: `messagingSenderId` in Firebase config
   - **Project ID**: `projectId` in Firebase config
   - **Google App ID**: `appId` in Firebase config (format: `1:xxx:ios:xxx`)
   - **Storage Bucket**: `storageBucket` in Firebase config

---

## Service Architecture

### FirebaseService.swift

Located: `WhiteNoise/Services/FirebaseService.swift`

**Features:**
- ✅ Automatic plist detection
- ✅ Manual configuration fallback
- ✅ Validation of configuration keys
- ✅ Sentry error tracking for configuration issues
- ✅ DEBUG/RELEASE behavior differences
- ✅ Helper methods for Analytics and Crashlytics

**DEBUG Mode:**
- Analytics: **DISABLED** (privacy/performance)
- Crashlytics: **DISABLED** (using Sentry instead)
- Console logging: **ENABLED**

**RELEASE Mode:**
- Analytics: **ENABLED**
- Crashlytics: **ENABLED**
- Console logging: **MINIMAL**

---

## Initialization

Firebase is initialized in `WhiteNoiseApp.swift`:

```swift
init() {
    // 1. Firebase (Analytics/Crashlytics)
    FirebaseService.configure()

    // 2. Sentry (Error tracking)
    SentrySDK.start { ... }

    // 3. RevenueCat (Subscriptions)
    RevenueCatService.configure()
}
```

**Initialization Order:**
1. Firebase first (needed for Analytics)
2. Sentry second (error tracking)
3. RevenueCat last (subscriptions)

---

## Usage Examples

### Analytics

```swift
// Log custom event
FirebaseService.logEvent("sound_played", parameters: [
    "sound_name": "rain",
    "volume": 0.75,
    "duration": 300
])

// Set user property
FirebaseService.setUserProperty("premium", forName: "subscription_status")

// Set user ID
FirebaseService.setUserID("user_12345")
```

### Crashlytics

```swift
// Record non-fatal error
FirebaseService.recordError(error, userInfo: [
    "context": "audio_playback",
    "sound_id": soundID
])

// Log message for crash context
FirebaseService.log("Starting audio playback for rain sound")

// Set custom key for crash reports
FirebaseService.setCustomKey("premium_user", value: true)

// Set user identifier
FirebaseService.setCrashlyticsUserID("user_12345")
```

---

## Logging Output

### Successful Configuration (with plist)

```
🔥 FirebaseService.configure - Using GoogleService-Info.plist
ℹ️ FirebaseService - Analytics disabled in DEBUG mode
ℹ️ FirebaseService - Crashlytics disabled in DEBUG mode (using Sentry)
✅ FirebaseService.configure - Firebase configured successfully
```

### Successful Configuration (manual)

```
🔥 FirebaseService.configure - Using manual configuration from xcconfig
🔥 FirebaseService - Configured with manual options
  - Project ID: whitenoise-app
  - Bundle ID: ruslan.whiteNoise.WhiteNoise
✅ FirebaseService.configure - Firebase configured successfully
```

### Configuration Errors

```
⚠️ FirebaseService.configure - Missing Firebase configuration keys
ℹ️ Add FIREBASE_API_KEY and FIREBASE_GCM_SENDER_ID to Local.xcconfig
```

**This error is tracked in Sentry** for production monitoring.

---

## Error Tracking Integration

All Firebase configuration errors are tracked in Sentry:

```swift
TelemetryService.captureNonFatal(
    message: "FirebaseService.configure - Missing configuration keys",
    level: .warning,
    extra: [
        "hasApiKey": true/false,
        "hasGcmSenderId": true/false
    ]
)
```

---

## Configuration Files

### Modified Files

1. **Local.xcconfig** - Your local configuration (not in git)
   ```bash
   FIREBASE_API_KEY = your_key
   FIREBASE_GCM_SENDER_ID = your_id
   # ... etc
   ```

2. **AppConfig.xcconfig** - Default/fallback values
   ```bash
   FIREBASE_API_KEY =
   FIREBASE_GCM_SENDER_ID =
   # ... etc
   ```

3. **Info.plist** - Exposes xcconfig values to app
   ```xml
   <key>FIREBASE_API_KEY</key>
   <string>$(FIREBASE_API_KEY)</string>
   <!-- ... etc -->
   ```

4. **WhiteNoiseApp.swift** - Initialization
   ```swift
   FirebaseService.configure()
   ```

5. **FirebaseService.swift** - Service implementation

---

## Troubleshooting

### Issue: "Missing Firebase configuration keys"

**Solution:**
- **Option A:** Add `GoogleService-Info.plist` to your project
- **Option B:** Set configuration in `Local.xcconfig`:
  ```bash
  FIREBASE_API_KEY = AIzaSy...
  FIREBASE_GCM_SENDER_ID = 123...
  FIREBASE_PROJECT_ID = my-project
  FIREBASE_GOOGLE_APP_ID = 1:123:ios:abc
  FIREBASE_STORAGE_BUCKET = my-project.appspot.com
  ```

### Issue: "Invalid API key format"

**Symptom:**
```
⚠️ FirebaseService.configure - Invalid API key (placeholder detected)
```

**Solution:**
Replace placeholder value with actual API key from Firebase Console:
```bash
# ❌ Wrong
FIREBASE_API_KEY = your_firebase_api_key_here

# ✅ Correct
FIREBASE_API_KEY = AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXX
```

### Issue: Analytics not working

**Check:**
1. Are you in DEBUG mode? Analytics is disabled in DEBUG
2. Is `GoogleService-Info.plist` added correctly?
3. Are xcconfig values correct in Info.plist?

**Verify:**
```bash
# Check if keys are set
defaults read /Users/.../Info.plist FIREBASE_API_KEY
```

### Issue: Crashlytics not reporting crashes

**Check:**
1. Are you in DEBUG mode? Crashlytics is disabled in DEBUG (Sentry is used)
2. In RELEASE, is Firebase properly configured?
3. Check Xcode build phases for Crashlytics script

---

## Firebase Console

### Analytics Dashboard
- Go to: Firebase Console → Analytics → Dashboard
- View: Events, User properties, Audiences

### Crashlytics Dashboard
- Go to: Firebase Console → Crashlytics
- View: Crashes, Non-fatals, ANRs

---

## Privacy & GDPR

### Data Collection

**Analytics (RELEASE only):**
- User behavior events
- Screen views
- User properties
- Device info

**Crashlytics (RELEASE only):**
- Crash logs
- Non-fatal errors
- Device state
- Custom keys

### User Consent

If you need GDPR compliance:

```swift
// Disable analytics until consent
Analytics.setAnalyticsCollectionEnabled(false)

// After user consent
Analytics.setAnalyticsCollectionEnabled(true)
```

### Data Deletion

Firebase automatically respects Apple's data deletion requirements. You can also implement:

```swift
Analytics.resetAnalyticsData()
```

---

## Best Practices

### 1. Event Naming
```swift
// ✅ Good - snake_case, descriptive
FirebaseService.logEvent("sound_played", parameters: [...])
FirebaseService.logEvent("timer_completed", parameters: [...])

// ❌ Bad - unclear, inconsistent
FirebaseService.logEvent("event1", parameters: [...])
FirebaseService.logEvent("SoundPlayed", parameters: [...])
```

### 2. Parameter Limits
- Event name: max 40 characters
- Parameter name: max 40 characters
- Parameter value: max 100 characters
- Max 25 parameters per event

### 3. Custom Events
```swift
// Track important user actions
FirebaseService.logEvent("premium_purchase", parameters: [
    "product_id": productID,
    "price": price,
    "currency": "USD"
])

FirebaseService.logEvent("sound_favorite", parameters: [
    "sound_name": soundName,
    "category": category
])
```

### 4. Error Tracking
```swift
// Use Crashlytics for production
#if !DEBUG
FirebaseService.recordError(error, userInfo: context)
#endif

// Always use Sentry in DEBUG
TelemetryService.captureNonFatal(error: error)
```

---

## Testing

### Test Configuration

1. **With plist:**
   - Add `GoogleService-Info.plist`
   - Run app
   - Check console for: `🔥 Using GoogleService-Info.plist`

2. **Without plist:**
   - Remove plist (or don't add it)
   - Set xcconfig values
   - Run app
   - Check console for: `🔥 Using manual configuration`

### Test Analytics (RELEASE only)

```swift
#if !DEBUG
FirebaseService.logEvent("test_event", parameters: [
    "test_param": "test_value"
])
#endif
```

Check Firebase Console → Analytics → DebugView for real-time events.

### Test Crashlytics (RELEASE only)

```swift
#if !DEBUG
// Force a test crash
fatalError("Test crash for Crashlytics")
#endif
```

Check Firebase Console → Crashlytics after restarting app.

---

## Migration from Existing Analytics

If you're migrating from another analytics service:

1. **Identify key events** to track
2. **Map event names** to Firebase conventions
3. **Update tracking calls** to use `FirebaseService`
4. **Test thoroughly** in DEBUG/RELEASE
5. **Monitor both services** during transition
6. **Deprecate old service** after verification

---

## Performance Considerations

### DEBUG Mode
- Analytics: **OFF** ✅ No performance impact
- Crashlytics: **OFF** ✅ No performance impact
- Only console logging

### RELEASE Mode
- Analytics: Minimal impact (~0.1% CPU)
- Crashlytics: Negligible impact
- Automatic batching and throttling

---

## Security

### API Keys
- Firebase API keys are **safe to include** in client apps
- They identify your Firebase project, not authenticate
- Real security comes from Firebase Security Rules

### Sensitive Data
- **Never log:** Passwords, credit cards, PII
- **Be careful with:** User IDs, email addresses
- **Safe to log:** Anonymous usage patterns

```swift
// ❌ Don't log sensitive data
FirebaseService.logEvent("login", parameters: [
    "password": password  // ❌ NEVER!
])

// ✅ Log anonymous patterns
FirebaseService.logEvent("login", parameters: [
    "method": "email",
    "success": true
])
```

---

## Support & Resources

- **Firebase Documentation:** https://firebase.google.com/docs/ios/setup
- **Analytics Guide:** https://firebase.google.com/docs/analytics
- **Crashlytics Guide:** https://firebase.google.com/docs/crashlytics
- **Sentry Dashboard:** https://ruslanpopesku.sentry.io/
- **Firebase Console:** https://console.firebase.google.com/

---

## Summary

### Configuration Options
1. ✅ **GoogleService-Info.plist** (easiest)
2. ✅ **Manual xcconfig** (more control)

### What's Integrated
- ✅ Firebase SDK via SPM
- ✅ FirebaseService.swift
- ✅ Configuration in xcconfig/Info.plist
- ✅ Initialization in WhiteNoiseApp
- ✅ Error tracking to Sentry
- ✅ DEBUG/RELEASE differences
- ✅ Helper methods for Analytics/Crashlytics

### Next Steps
1. Add `GoogleService-Info.plist` OR set xcconfig values
2. Clean build project
3. Run app and verify console logs
4. Check Firebase Console for data

---

**Last Updated:** 2025-11-01
**Firebase SDK Version:** Latest (via SPM)
**Minimum iOS:** Check project deployment target
