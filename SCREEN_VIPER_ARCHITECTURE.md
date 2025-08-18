# Screen-Level VIPER Architecture with Reducer Pattern

## Overview
This implementation provides a **screen-level VIPER architecture** for the WhiteNoisesView screen, not an app-wide architecture. Each screen in the app can have its own VIPER module with its own state management and reducer.

## Architecture Structure

```
WhiteNoise/
├── Modules/
│   └── WhiteNoises/                    # Screen Module
│       ├── WhiteNoisesModuleBuilder.swift   # Module Builder/Assembler
│       ├── WhiteNoisesProtocols.swift       # VIPER Protocols
│       ├── WhiteNoisesState.swift           # Screen State Model
│       ├── WhiteNoisesAction.swift          # Actions & Side Effects
│       ├── WhiteNoisesReducer.swift         # State Reducer
│       ├── WhiteNoisesInteractor.swift      # Business Logic
│       ├── WhiteNoisesPresenter.swift       # Presentation Logic
│       ├── WhiteNoisesRouter.swift          # Navigation
│       └── WhiteNoisesViewVIPER.swift       # View Implementation
```

## Key Components

### 1. Module Builder (`WhiteNoisesModuleBuilder.swift`)
- **Purpose**: Assembles all VIPER components for the screen
- **Responsibility**: Wire up dependencies and return a ready-to-use View
- **Usage**: `WhiteNoisesModuleBuilder.build()` returns a SwiftUI View

### 2. Screen State (`WhiteNoisesState.swift`)
- **PlaybackState**: Detailed playback states (idle, playing, fadingIn, fadingOut, etc.)
- **ScreenTimerState**: Timer state specific to this screen
- **SoundState**: Individual sound states
- **UI State**: Loading, errors, input control

### 3. Reducer (`WhiteNoisesReducer.swift`)
- **Pure Function**: Takes state + action → new state + side effects
- **Screen-Scoped**: Only manages state for WhiteNoisesView screen
- **Side Effects**: Returns list of effects to be executed by Interactor

### 4. Interactor (`WhiteNoisesInteractor.swift`)
- **Business Logic**: Handles all business rules for the screen
- **Service Coordination**: Manages audio services, timer, etc.
- **State Management**: Dispatches actions to reducer
- **Side Effect Processing**: Executes side effects returned by reducer

### 5. Presenter (`WhiteNoisesPresenter.swift`)
- **View Updates**: Transforms state for view presentation
- **User Input**: Handles user interactions from view
- **Coordination**: Bridges between View and Interactor

### 6. Router (`WhiteNoisesRouter.swift`)
- **Navigation**: Handles screen transitions
- **Modal Presentation**: Timer picker, sound variant picker
- **Screen-Specific**: Only manages navigation from this screen

### 7. View (`WhiteNoisesViewVIPER.swift`)
- **SwiftUI View**: The actual UI implementation
- **View Model**: Internal ObservableObject for SwiftUI binding
- **Protocol Conformance**: Implements WhiteNoisesViewProtocol

## Data Flow

```
User Action → View → Presenter → Interactor → Reducer
                ↑                     ↓
                ←── State Update ←────┘
```

1. User taps play button
2. View calls `presenter.playPauseTapped()`
3. Presenter calls `interactor.togglePlayPause()`
4. Interactor dispatches `.userTappedPlayPause` action
5. Reducer returns new state + side effects
6. Interactor processes side effects (play audio, start timer, etc.)
7. State update flows back through Presenter to View
8. View updates UI based on new state

## State Management

### Actions
```swift
enum WhiteNoisesAction {
    case userTappedPlayPause
    case userSelectedTimer(mode: TimerService.TimerMode)
    case userChangedVolume(soundId: UUID, volume: Float)
    // ... more actions
}
```

### Side Effects
```swift
enum WhiteNoisesSideEffect {
    case playSounds(ids: [UUID], fadeDuration: Double?)
    case pauseSounds(ids: [UUID], fadeDuration: Double?)
    case startTimer(seconds: Int)
    // ... more effects
}
```

### Reducer Logic
```swift
func reduce(state: State, action: Action) -> (State, [SideEffect]) {
    switch action {
    case .userTappedPlayPause:
        // Return new state and effects
    }
}
```

## Benefits of Screen-Level VIPER

1. **Modularity**: Each screen is completely self-contained
2. **Testability**: Each component can be tested in isolation
3. **Reusability**: Screens can be reused in different contexts
4. **Clear Separation**: Business logic, presentation, and navigation are separated
5. **State Management**: Redux-style reducer provides predictable state updates
6. **Debugging**: All state changes go through reducer with logging

## Usage

### Enable VIPER for Screen
```swift
// In FeatureFlags.swift
static let useVIPERScreenArchitecture = true
```

### Create New Screen Module
1. Create a new folder under `Modules/`
2. Copy the VIPER template files
3. Implement screen-specific logic
4. Use the builder to instantiate the screen

### Example: Adding a New Screen
```swift
// Modules/Settings/SettingsModuleBuilder.swift
final class SettingsModuleBuilder {
    static func build() -> some View {
        // Wire up VIPER components
        // Return the view
    }
}

// Usage in navigation
SettingsModuleBuilder.build()
```

## Testing Strategy

### Unit Tests
- **Reducer**: Test state transitions and side effects
- **Interactor**: Test business logic with mock services
- **Presenter**: Test view updates with mock interactor

### Integration Tests
- **Module**: Test complete flow through all components
- **State Management**: Test complex state transitions

## Migration Path

The app supports both architectures:
1. **MVVM**: Current implementation (legacy)
2. **VIPER**: New screen-level architecture

Toggle between them using `FeatureFlags.useVIPERScreenArchitecture`.

## Key Differences from App-Level VIPER

| Aspect | App-Level VIPER | Screen-Level VIPER |
|--------|----------------|-------------------|
| Scope | Entire app | Single screen |
| State | Global app state | Screen-specific state |
| Reducer | App-wide reducer | Screen reducer |
| Builder | App builder | Screen module builder |
| Services | Shared globally | Injected per screen |

## Conclusion

This screen-level VIPER architecture provides a robust, testable, and maintainable structure for individual screens while keeping them completely independent and reusable. The reducer pattern ensures predictable state management with comprehensive logging for debugging.