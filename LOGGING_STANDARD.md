# Logging Standard - WhiteNoise App

## Log Format

### Prefix Emojis
- 🎵 Audio/Sound operations
- ⏱️ Timer operations
- 🔘 Button/UI interactions
- 📱 App lifecycle events
- 🔊 Volume changes
- ✅ Success operations
- ❌ Errors/Failures
- ⚠️ Warnings/Skipped operations
- 🔄 State transitions
- 📊 State snapshots
- 🎯 Method entry points
- 🏁 Method exit points
- 📡 Remote commands
- 🎚️ Fade operations

### Log Structure
```
[Emoji] [Component].[Method] - [Action/State]: [Details]
```

### Examples
```
🎯 WhiteNoisesVM.playingButtonSelected - START: isPlaying=false, processing=false
🔄 WhiteNoisesVM.playingButtonSelected - STATE CHANGE: isPlaying false→true
⏱️ TimerService.resume - RESUMING: remainingSeconds=120, mode=twoMinutes
✅ WhiteNoisesVM.playSounds - COMPLETED: 4 sounds playing, timer active
```

## Component Abbreviations
- WhiteNoisesVM = WhiteNoisesViewModel
- SoundVM = SoundViewModel
- TimerSvc = TimerService
- AudioSession = AudioSessionService

## State Snapshot Format
For complex state debugging, use multi-line format:
```
📊 WhiteNoisesVM - STATE SNAPSHOT:
  - isPlaying: true
  - isProcessing: false
  - activeSounds: 4
  - timerMode: fiveMinutes
  - timerRemaining: 04:32
  - timerActive: true
```

## Critical Paths to Log
1. **Every method entry/exit**
2. **All state changes**
3. **Timer lifecycle events**
4. **Audio player creation/destruction**
5. **Fade operation start/completion**
6. **Error conditions**
7. **Skipped operations (with reason)**
8. **Async task creation/cancellation**