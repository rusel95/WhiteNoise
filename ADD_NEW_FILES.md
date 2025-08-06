# Instructions to Add New Files to Xcode Project

## Build Errors to Fix

The following files were created but need to be added to the Xcode project to resolve build errors:

### 1. Constants Group
Create a "Constants" group in Xcode and add:
- `/WhiteNoise/Constants/AppConstants.swift`

### 2. New Services Files
The Services group already exists. Add these new files to it:
- `/WhiteNoise/Services/SoundPersistenceService.swift`
- `/WhiteNoise/Services/HapticFeedbackService.swift`
- `/WhiteNoise/Services/SoundConfigurationLoader.swift`

### 3. Resources
Add to the Resources group:
- `/WhiteNoise/Resources/SoundConfiguration.json`
  - **Important**: Make sure this file is added to "Copy Bundle Resources" in Build Phases

## How to Add Files in Xcode

1. Open WhiteNoise.xcodeproj in Xcode
2. Right-click on the WhiteNoise folder in Xcode's navigator
3. Select "Add Files to WhiteNoise..."
4. Navigate to each file/folder listed above
5. Make sure:
   - "Copy items if needed" is **unchecked** (files are already in place)
   - "Create groups" is selected
   - "Add to targets: WhiteNoise" is **checked**
6. Click "Add"

## Special Instructions for JSON File

After adding `SoundConfiguration.json`:
1. Select your project in the navigator
2. Select the WhiteNoise target
3. Go to "Build Phases" tab
4. Expand "Copy Bundle Resources"
5. Verify `SoundConfiguration.json` is listed there
6. If not, click the "+" button and add it manually

## Sentry Package Issue

If you're seeing Sentry package errors:
1. In Xcode, go to File → Add Package Dependencies
2. Add: https://github.com/getsentry/sentry-cocoa.git
3. Select the latest version
4. Add these products to your target:
   - Sentry
   - SentrySwiftUI
   - Sentry-Dynamic (if needed)

## After Adding Files

Once all files are added, the build should succeed. The refactoring includes:
- ✅ Configuration-based sound loading from JSON
- ✅ Centralized constants for all UI values
- ✅ Dedicated services following SOLID principles
- ✅ No more duplicate code
- ✅ No more magic numbers
- ✅ Safe code without force unwrapping