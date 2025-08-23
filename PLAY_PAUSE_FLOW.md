# Play/Pause Flow Documentation - WhiteNoise App

## Overview
This document describes the complete play/pause flow in the WhiteNoise app, including all components involved and their interactions.

## Flow Diagram

```
User Taps Play/Pause Button
         ↓
WhiteNoisesView (UI Layer)
         ↓
viewModel.playingButtonSelected()
         ↓
WhiteNoisesViewModel (State Management)
    ├── Updates isPlaying state immediately
    └── Creates async Task
              ↓
        [Was Playing?]
         /          \
       Yes           No
        ↓             ↓
   pauseSounds    playSounds
        ↓             ↓
   ┌────┴────┐   ┌────┴────┐
   │ Timer   │   │ Timer   │
   │ Pause   │   │ Resume  │
   └────┬────┘   └────┬────┘
        ↓             ↓
   ┌────┴────┐   ┌────┴────┐
   │ Pause   │   │ Play    │
   │ Sounds  │   │ Sounds  │
   └─────────┘   └─────────┘
```

## Components

### 1. UI Layer (WhiteNoisesView.swift)
- **Location**: Lines 52, 99
- **Trigger**: User taps play/pause button
- **Action**: Calls `viewModel.playingButtonSelected()`

### 2. State Management (WhiteNoisesViewModel.swift)

#### playingButtonSelected() - Lines 101-116
1. Logs current state
2. **Immediately toggles** `isPlaying` state for UI responsiveness
3. Creates async Task:
   - If was playing → calls `pauseSounds(updateState: false)`
   - If wasn't playing → calls `playSounds(updateState: false)`
   - Note: `updateState: false` prevents double state update

#### playSounds() - Lines 279-315
1. **Timer Handling**:
   - If timer has remaining time and not active → Resume
   - If no remaining time → Start new timer
2. **Sound Playback**:
   - Filters sounds with volume > 0
   - Concurrent playback via TaskGroup
3. **State Update**: Only if `updateState: true`
4. Updates Now Playing info

#### pauseSounds() - Lines 317-344
1. **Timer Handling**: Pauses timer if active
2. **Sound Pausing**: Concurrent pause via TaskGroup
3. **State Update**: Only if `updateState: true`
4. Updates Now Playing info

### 3. Individual Sound Control (SoundViewModel.swift)

#### playSound() - Lines 170-196
1. Cancels existing fade operations
2. Ensures audio is loaded
3. Applies fade if specified, or plays immediately

#### pauseSound() - Lines 198-215
1. Cancels existing fade operations
2. Applies fade if specified, or pauses immediately

### 4. Timer Service (TimerService.swift)
- **pause()**: Stops timer task, preserves remaining time
- **resume()**: Restarts timer from paused time
- **stop()**: Completely resets timer

## State Flow

### Playing State
```
isPlaying: false → true (immediate)
    ↓
Audio starts (async, ~100-500ms later)
    ↓
Timer starts/resumes (if enabled)
```

### Pausing State
```
isPlaying: true → false (immediate)
    ↓
Audio fades out (async, 2s fade)
    ↓
Timer pauses (preserves remaining time)
```

## Known Issues

### 1. State Synchronization
- **Problem**: UI state updates immediately, audio operations are async
- **Impact**: Potential UI/audio state mismatch during transitions

### 2. Duplicate Operations
- **Problem**: Multiple triggers can cause duplicate play/pause calls
- **Sources**:
  - User button presses
  - Timer expiry
  - Remote commands
  - Audio interruptions
  - Volume changes

### 3. Race Conditions
- **Problem**: Rapid play/pause can create overlapping operations
- **Impact**: Inconsistent state, duplicate logs

## Call Paths

### Primary Path (User Initiated)
```
Button → playingButtonSelected() → playSounds/pauseSounds(updateState: false)
```

### Secondary Paths
```
Timer Expiry → onTimerExpired → pauseSounds(updateState: true)
Remote Command → onPlayCommand → playSounds(updateState: true)
Audio Interruption → handleAudioInterruption → playSounds/pauseSounds
Volume Change → handleVolumeChange → playSound/pauseSound (individual)
```

## Fade Durations
- **Standard**: 2.0 seconds (button press)
- **Long**: 3.0 seconds (remote commands, interruptions)
- **Out**: 5.0 seconds (timer expiry)

## Timer Lifecycle

### Start
1. User selects timer duration
2. Timer starts when play begins
3. Updates every second

### Pause/Resume
1. Pause: Preserves remaining seconds, stops task
2. Resume: Creates new task with remaining time

### Stop
1. Resets all timer state
2. Only happens when timer is turned off or expires

## Audio Session Management
- Configured for background audio
- Handles interruptions (phone calls, etc.)
- Reconfigures when app becomes active

## Now Playing Info
- Updates on play/pause
- Shows active sounds
- Displays timer remaining time
- Enables remote control