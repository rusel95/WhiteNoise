# WhiteNoise Technical Stack

## Platform & Requirements
- **Platform**: iOS 15.0+
- **Language**: Swift 5.0+
- **UI Framework**: SwiftUI
- **Build System**: Xcode project (.xcodeproj)
- **Architecture**: MVVM with Protocol-Oriented Programming

## Core Frameworks
- **SwiftUI**: Primary UI framework
- **AVFoundation**: Audio playback and session management
- **Combine**: Reactive programming and data binding
- **MediaPlayer**: Remote control and Now Playing integration
- **Foundation**: Core system services

## Key Technologies
- **Audio Engine**: AVAudioPlayer for sound playback
- **Persistence**: UserDefaults for sound preferences
- **Configuration**: JSON-based sound configuration
- **Concurrency**: async/await with @MainActor for UI updates
- **Dependency Injection**: Protocol-based service injection

## Common Build Commands

### Building & Running
```bash
# Open project in Xcode
open WhiteNoise.xcodeproj

# Build from command line (if needed)
xcodebuild -project WhiteNoise.xcodeproj -scheme WhiteNoise -configuration Debug build

# Run tests
xcodebuild test -project WhiteNoise.xcodeproj -scheme WhiteNoise -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Project Structure Commands
```bash
# Clean derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/WhiteNoise-*

# Clean build folder
rm -rf build/

# Reset simulator
xcrun simctl erase all
```

## Development Tools
- **Xcode**: Primary IDE
- **iOS Simulator**: Testing and development
- **Instruments**: Performance profiling
- **Swift Package Manager**: Dependency management (if needed)

## Audio File Management
- **Format**: MP3 files for compatibility and size
- **Organization**: Categorized in `WhiteNoise/Sounds/` subfolders
- **Naming**: Descriptive filenames matching configuration
- **Loading**: Lazy loading with background preloading for favorites

## Build Configuration
- **Bundle ID**: Configured in project settings
- **Entitlements**: Background audio playback capabilities
- **Info.plist**: Audio session configuration
- **Assets**: App icons and launch screens in xcassets

## Performance Considerations
- Background audio session management
- Memory-efficient audio loading
- Fade operations using async/await
- Timer precision with nanosecond intervals