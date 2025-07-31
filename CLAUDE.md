# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

WhiteNoise is a native iOS application built with SwiftUI that provides ambient sounds and white noise for relaxation, focus, or sleep. The app allows users to play multiple sounds simultaneously with individual volume controls.

## Build Commands

```bash
# Build for Debug
xcodebuild -project WhiteNoise.xcodeproj -scheme WhiteNoise -configuration Debug build

# Build for Release
xcodebuild -project WhiteNoise.xcodeproj -scheme WhiteNoise -configuration Release build

# Run tests
xcodebuild test -project WhiteNoise.xcodeproj -scheme WhiteNoise -destination 'platform=iOS Simulator,name=iPhone 15'

# Clean build folder
xcodebuild clean -project WhiteNoise.xcodeproj -scheme WhiteNoise

# Build and run on simulator (opens Xcode)
open WhiteNoise.xcodeproj
```

## Architecture

The app follows a simple MVVM (Model-View-ViewModel) pattern:

### Core Components

- **Views** (`/WhiteNoise/Views/`): SwiftUI views
  - `ContentView.swift`: Root view controller
  - `WhiteNoisesView.swift`: Main list view showing all available sounds
  - `SoundView.swift`: Individual sound control component

- **ViewModels** (`/WhiteNoise/ViewModels/`): Business logic and state management
  - `WhiteNoisesViewModel.swift`: Manages the list of sounds and playback state
  - `SoundViewModel.swift`: Controls individual sound playback and volume

- **Models** (`/WhiteNoise/Models/`):
  - `Sound.swift`: Sound data model with enum for different sound types
  - `SoundFactory.swift`: Factory pattern for creating sound instances

### Key Features

1. **Audio Playback**: Uses AVFoundation for audio playback with background audio capability
2. **State Persistence**: UserDefaults stores user preferences for sound states and volumes
3. **Multiple Sound Support**: Can play multiple ambient sounds simultaneously
4. **Background Audio**: Configured to continue playing when app is in background
5. **Modern Concurrency**: Uses async/await and Combine for timer and fade operations
6. **Thread Safety**: All UI updates marked with @MainActor for thread safety

### Sound Resources

Audio files are organized in `/WhiteNoise/Resources/` by category:
- Rain sounds (soft rain, hard rain, rain on leaves, rain on car)
- Fireplace sounds
- Nature sounds (forest, birds, sea, river, waterfall)

### Timer Implementation

The timer system has been refactored to use modern Swift concurrency:

1. **Task-based Timer**: Uses `Task` with `Task.sleep` instead of `Timer` for better memory management
2. **Cancellation Support**: Properly cancels running tasks to prevent memory leaks
3. **Thread Safety**: All timer operations run on MainActor to prevent race conditions
4. **Fade Operations**: Audio fades use Task-based approach with proper cancellation
5. **Edge Case Handling**: Prevents multiple timers/fades from running simultaneously
- Weather sounds (thunder, snow)
- White noise variants

## Development Guidelines

When modifying this codebase:

1. **SwiftUI Best Practices**: Use `@StateObject` for view models, `@Published` for observable properties
2. **Audio Management**: Always handle audio session configuration and interruptions properly
3. **State Persistence**: Save user preferences immediately when changed
4. **Resource Management**: Audio files should be properly loaded and released
5. **Testing**: Add unit tests for view models and UI tests for critical user flows

## Important Configuration

- **Minimum iOS Version**: Check `project.pbxproj` for deployment target
- **Background Modes**: Audio background mode is enabled in Info.plist
- **Device Support**: Universal app supporting iPhone and iPad