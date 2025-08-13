# WhiteNoise Project Structure

## Root Directory Organization
```
WhiteNoise/                 # Main app target
├── Assets.xcassets/        # App icons, colors, images
├── Commands/               # Command pattern implementations
├── Constants/              # App-wide constants and configurations
├── Extensions/             # Swift extensions for existing types
├── Facades/                # Facade pattern implementations
├── Factories/              # Factory pattern implementations
├── Models/                 # Data models and structures
├── Observers/              # Observer pattern implementations
├── Resources/              # JSON configurations and data files
├── Services/               # Business logic and external integrations
├── Sounds/                 # Audio files organized by category
├── States/                 # State management objects
├── Strategies/             # Strategy pattern implementations
├── ViewModels/             # MVVM ViewModels
├── Views/                  # SwiftUI Views
├── Preview Content/        # SwiftUI preview assets
├── Info.plist             # App configuration
├── LaunchScreen.storyboard # Launch screen
└── WhiteNoiseApp.swift    # App entry point
```

## Folder Conventions

### Models/
- Pure data structures
- Codable conformance for persistence
- No business logic
- Example: `Sound.swift`, `SoundVariant`

### ViewModels/
- MVVM ViewModels with `@Published` properties
- Business logic coordination
- Service dependency injection
- ObservableObject conformance
- Example: `WhiteNoisesViewModel.swift`, `SoundViewModel.swift`

### Views/
- SwiftUI Views only
- No business logic
- Inject ViewModels via `@StateObject` or `@ObservedObject`
- Extract reusable components
- Example: `ContentView.swift`, `SoundView.swift`

### Services/
- Protocol-based service implementations
- External API integrations
- System service wrappers
- Dependency injection targets
- Example: `AudioSessionService.swift`, `TimerService.swift`

### Sounds/
- Organized by sound category subfolders
- MP3 audio files
- Descriptive filenames matching JSON configuration
- Categories: `Birds/`, `fireplace/`, `forest/`, `rain/`, `river/`, `sea/`, `snow/`, `thunder/`, `voice/`, `waterfall/`

### Constants/
- App-wide constants in enums
- UI dimensions, colors, animations
- Audio settings and thresholds
- Example: `AppConstants.swift`

### Resources/
- JSON configuration files
- Static data files
- Example: `SoundConfiguration.json`

## Naming Conventions

### Files
- PascalCase for Swift files: `WhiteNoisesViewModel.swift`
- Descriptive names for audio files: `soft rain.mp3`
- Protocol suffix for protocols: `AudioPlayerProtocol.swift`
- Service suffix for services: `TimerService.swift`

### Classes & Structs
- PascalCase: `WhiteNoisesViewModel`, `SoundFactory`
- Protocol suffix for protocols: `SoundFactoryProtocol`
- Descriptive, single-responsibility names

### Methods & Properties
- camelCase: `playSounds()`, `isPlaying`
- Verb-based method names: `loadSounds()`, `handleTimerExpired()`
- Boolean properties with `is/has/can` prefix: `isPlaying`, `hasTimer`

## Architecture Patterns by Folder

### MVVM Implementation
- **Models/**: Data structures only
- **Views/**: SwiftUI Views with minimal logic
- **ViewModels/**: Business logic and state management

### Design Patterns
- **Commands/**: Command pattern for audio and timer operations
- **Factories/**: Factory pattern for sound creation
- **Strategies/**: Strategy pattern for fade operations
- **Observers/**: Observer pattern for sound state changes
- **Facades/**: Facade pattern for complex subsystems

### Service Layer
- **Services/**: Protocol-based services
- Dependency injection via initializers
- Single responsibility per service
- Protocol conformance for testability

## File Organization Rules

1. **One class per file** (except small related types)
2. **Group related functionality** in same folder
3. **Protocol + Implementation** in same folder
4. **Extensions** in dedicated Extensions/ folder
5. **Constants** centralized in Constants/ folder
6. **Assets** properly organized in xcassets bundles

## Import Guidelines
- Import only necessary frameworks
- Use `import Foundation` for basic types
- Use `import SwiftUI` for UI components
- Use `import AVFoundation` for audio functionality
- Use `import Combine` for reactive programming

## Code Organization Within Files
```swift
// MARK: - Imports
import SwiftUI
import Combine

// MARK: - Protocols (if any)
protocol SomeProtocol { }

// MARK: - Main Type
class SomeClass: ObservableObject {
    // MARK: - Published Properties
    @Published var someProperty: String = ""
    
    // MARK: - Private Properties
    private let service: SomeService
    
    // MARK: - Initialization
    init(service: SomeService) { }
    
    // MARK: - Public Methods
    func publicMethod() { }
    
    // MARK: - Private Methods
    private func privateMethod() { }
}

// MARK: - Extensions
extension SomeClass: SomeProtocol { }
```