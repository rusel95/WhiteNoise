# Firebase Setup Checklist

Quick setup guide for Firebase in WhiteNoise.

## ✅ Already Done

- [x] Firebase SDK added via SPM (FirebaseAnalytics, FirebaseCrashlytics)
- [x] FirebaseService.swift created
- [x] Configuration keys added to xcconfig files
- [x] Info.plist updated with Firebase keys
- [x] Firebase initialized in WhiteNoiseApp.swift
- [x] Error tracking integrated with Sentry
- [x] DEBUG/RELEASE mode handling

## 🔧 Configuration Required (Choose One)

### Option A: Use GoogleService-Info.plist (Recommended)

1. **Get the plist file:**
   - [ ] Go to [Firebase Console](https://console.firebase.google.com/)
   - [ ] Select your project (or create one)
   - [ ] Go to Project Settings (⚙️ icon) → General
   - [ ] Scroll to "Your apps" section
   - [ ] If no iOS app exists, click "Add app" → iOS
   - [ ] Download `GoogleService-Info.plist`

2. **Add to Xcode:**
   - [ ] Open Xcode
   - [ ] Drag `GoogleService-Info.plist` into project navigator
   - [ ] Check "Copy items if needed"
   - [ ] Select WhiteNoise target
   - [ ] Click "Finish"

3. **Verify:**
   - [ ] File appears in Project Navigator
   - [ ] File is in WhiteNoise folder
   - [ ] Target membership is set to WhiteNoise

4. **Done!** Skip Option B.

---

### Option B: Manual Configuration via xcconfig

1. **Get Firebase configuration:**
   - [ ] Go to [Firebase Console](https://console.firebase.google.com/)
   - [ ] Select your project
   - [ ] Go to Project Settings → General
   - [ ] Find your iOS app
   - [ ] View Firebase config (looks like JSON)

2. **Update Local.xcconfig:**
   ```bash
   # Replace these with your actual values from Firebase Console
   FIREBASE_API_KEY = AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXX
   FIREBASE_GCM_SENDER_ID = 123456789012
   FIREBASE_PROJECT_ID = your-project-id
   FIREBASE_GOOGLE_APP_ID = 1:123456789012:ios:abcdef1234567890
   FIREBASE_STORAGE_BUCKET = your-project-id.appspot.com
   ```

3. **Mapping:**
   - [ ] `apiKey` → `FIREBASE_API_KEY`
   - [ ] `messagingSenderId` → `FIREBASE_GCM_SENDER_ID`
   - [ ] `projectId` → `FIREBASE_PROJECT_ID`
   - [ ] `appId` → `FIREBASE_GOOGLE_APP_ID`
   - [ ] `storageBucket` → `FIREBASE_STORAGE_BUCKET`

---

## 🧪 Testing

1. **Clean Build:**
   ```bash
   xcodebuild clean -project WhiteNoise.xcodeproj
   ```

2. **Run the app**

3. **Check Console Logs:**

   **Success (with plist):**
   ```
   🔥 FirebaseService.configure - Using GoogleService-Info.plist
   ℹ️ FirebaseService - Analytics disabled in DEBUG mode
   ℹ️ FirebaseService - Crashlytics disabled in DEBUG mode
   ✅ FirebaseService.configure - Firebase configured successfully
   ```

   **Success (manual):**
   ```
   🔥 FirebaseService.configure - Using manual configuration from xcconfig
   🔥 FirebaseService - Configured with manual options
     - Project ID: your-project-id
     - Bundle ID: ruslan.whiteNoise.WhiteNoise
   ✅ FirebaseService.configure - Firebase configured successfully
   ```

   **Error:**
   ```
   ⚠️ FirebaseService.configure - Missing Firebase configuration keys
   ℹ️ Add FIREBASE_API_KEY and FIREBASE_GCM_SENDER_ID to Local.xcconfig
   ```
   → Go back and complete Option A or B

4. **Verify in Firebase Console:**
   - [ ] Go to Firebase Console → Project Overview
   - [ ] Should see your iOS app listed
   - [ ] Click "Analytics" → Dashboard
   - [ ] May take 24-48 hours for first data

---

## 📊 Optional: Enable Analytics/Crashlytics in DEBUG

By default, Analytics and Crashlytics are **disabled in DEBUG** to:
- Save battery during development
- Avoid polluting analytics with test data
- Use Sentry for error tracking instead

**To enable for testing:**

Edit `FirebaseService.swift`:
```swift
#if DEBUG
// Change false to true to test
Analytics.setAnalyticsCollectionEnabled(true)
Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
#endif
```

---

## 🐛 Troubleshooting

### Firebase not initializing

**Check:**
1. Is `GoogleService-Info.plist` in the project?
2. Are xcconfig values set correctly?
3. Did you clean and rebuild?

**Solution:**
```bash
# Clean derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/WhiteNoise*

# Clean build
xcodebuild clean -project WhiteNoise.xcodeproj

# Rebuild
```

### "Missing Firebase configuration keys"

**Fix:**
- Add `GoogleService-Info.plist`, OR
- Set all 5 Firebase keys in `Local.xcconfig`

### Analytics not showing data

**Normal:**
- DEBUG mode disables analytics by default
- First data can take 24-48 hours
- Use DebugView for real-time testing

**Enable DebugView:**
```bash
# Terminal
adb shell setprop debug.firebase.analytics.app ruslan.whiteNoise.WhiteNoise
```

### Build errors about Firebase

**Fix:**
1. File → Packages → Reset Package Caches
2. File → Packages → Update to Latest Package Versions
3. Clean build folder
4. Rebuild

---

## 🎯 Quick Commands

```bash
# Clean build
xcodebuild clean -project WhiteNoise.xcodeproj

# Remove derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/WhiteNoise*

# Check if plist exists
ls WhiteNoise/GoogleService-Info.plist

# View current xcconfig
cat WhiteNoise/Configuration/Local.xcconfig
```

---

## 📚 Documentation

- [FIREBASE_INTEGRATION.md](FIREBASE_INTEGRATION.md) - Full integration guide
- [Firebase Console](https://console.firebase.google.com/)
- [Firebase iOS Setup](https://firebase.google.com/docs/ios/setup)

---

## ✨ Summary

### What You Need to Do

**Choose ONE:**
- [ ] Add `GoogleService-Info.plist` to Xcode (easiest)
- [ ] Set 5 Firebase keys in `Local.xcconfig`

**Then:**
- [ ] Clean build
- [ ] Run app
- [ ] Verify console logs show Firebase success

**Optional:**
- [ ] Enable analytics in DEBUG for testing
- [ ] Set up Firebase DebugView
- [ ] Configure Firebase Security Rules

---

**Setup Time:** 5-10 minutes
**Difficulty:** Easy
**Required:** For production analytics and crash reporting
**Optional:** Can skip if you only want Sentry
