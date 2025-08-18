//
//  WhiteNoisesReducer.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 2025-08-14.
//

import Foundation

@MainActor
final class WhiteNoisesReducer {
    
    func reduce(state: WhiteNoisesState, action: WhiteNoisesAction) -> (WhiteNoisesState, [WhiteNoisesSideEffect]) {
        var newState = state
        var sideEffects: [WhiteNoisesSideEffect] = []
        
        sideEffects.append(.log(level: .debug, message: "Action: \(action)"))
        
        switch action {
        case .userTappedPlayPause:
            return handlePlayPauseToggle(state: newState)
            
        case .userSelectedTimer(let mode):
            return handleTimerSelection(state: newState, mode: mode)
            
        case .userChangedVolume(let soundId, let volume):
            return handleVolumeChange(state: newState, soundId: soundId, volume: volume)
            
        case .userSelectedSoundVariant(let soundId, let variant):
            return handleSoundVariantChange(state: newState, soundId: soundId, variant: variant)
            
        case .loadSounds(let sounds):
            newState.sounds = sounds
            newState.isLoading = false
            sideEffects.append(.log(level: .info, message: "Loaded \(sounds.count) sounds"))
            
        case .startPlayback:
            newState.playbackState = .preparingToPlay
            newState.canAcceptInput = false
            sideEffects.append(.log(level: .info, message: "Starting playback"))
            sideEffects.append(.playSounds(ids: newState.activeSounds.map { $0.id }, fadeDuration: 1.0))
            
        case .pausePlayback:
            newState.playbackState = .preparingToPause
            newState.canAcceptInput = false
            sideEffects.append(.log(level: .info, message: "Pausing playback"))
            sideEffects.append(.pauseSounds(ids: newState.activeSounds.map { $0.id }, fadeDuration: 1.0))
            
        case .updatePlaybackState(let state):
            newState.playbackState = state
            newState.canAcceptInput = !state.isTransitioning
            
        case .startFadeIn:
            newState.playbackState = .fadingIn(progress: 0)
            sideEffects.append(.log(level: .debug, message: "Starting fade in"))
            
        case .fadeInProgress(let progress):
            newState.playbackState = .fadingIn(progress: progress)
            
        case .fadeInCompleted:
            newState.playbackState = .playing
            newState.canAcceptInput = true
            sideEffects.append(.log(level: .info, message: "Fade in completed"))
            if newState.timerState.mode != .off && !newState.timerState.isActive {
                sideEffects.append(.startTimer(seconds: newState.timerState.remainingSeconds))
                newState.timerState.isActive = true
            }
            
        case .startFadeOut:
            newState.playbackState = .fadingOut(progress: 0)
            sideEffects.append(.log(level: .debug, message: "Starting fade out"))
            
        case .fadeOutProgress(let progress):
            newState.playbackState = .fadingOut(progress: progress)
            
        case .fadeOutCompleted:
            newState.playbackState = .paused
            newState.canAcceptInput = true
            sideEffects.append(.log(level: .info, message: "Fade out completed"))
            if newState.timerState.isActive {
                newState.timerState.pausedTime = Date().timeIntervalSince(newState.timerState.startTime ?? Date())
                newState.timerState.isActive = false
                sideEffects.append(.stopTimer)
            }
            
        case .startTimer:
            newState.timerState.startTime = Date()
            newState.timerState.isActive = true
            sideEffects.append(.startTimer(seconds: newState.timerState.mode.totalSeconds))
            
        case .pauseTimer:
            newState.timerState.pausedTime = Date().timeIntervalSince(newState.timerState.startTime ?? Date())
            newState.timerState.isActive = false
            sideEffects.append(.stopTimer)
            
        case .resumeTimer:
            newState.timerState.startTime = Date().addingTimeInterval(-newState.timerState.pausedTime)
            newState.timerState.isActive = true
            sideEffects.append(.startTimer(seconds: newState.timerState.remainingSeconds))
            
        case .timerTick:
            if newState.timerState.isActive {
                newState.timerState.remainingSeconds = max(0, newState.timerState.remainingSeconds - 1)
            }
            
        case .timerExpired:
            newState.timerState = ScreenTimerState()
            sideEffects.append(.log(level: .info, message: "Timer expired"))
            sideEffects.append(.pauseSounds(ids: newState.activeSounds.map { $0.id }, fadeDuration: 2.0))
            
        case .setError(let message):
            newState.error = message
            newState.playbackState = .error(message)
            sideEffects.append(.log(level: .error, message: message))
            
        case .clearError:
            newState.error = nil
            
        case .setLoading(let loading):
            newState.isLoading = loading
        }
        
        newState.lastActionTime = Date()
        return (newState, sideEffects)
    }
    
    // MARK: - Private Handlers
    
    private func handlePlayPauseToggle(state: WhiteNoisesState) -> (WhiteNoisesState, [WhiteNoisesSideEffect]) {
        var newState = state
        var sideEffects: [WhiteNoisesSideEffect] = []
        
        guard state.canAcceptInput else {
            sideEffects.append(.log(level: .warning, message: "Ignoring input - transition in progress"))
            return (state, sideEffects)
        }
        
        switch state.playbackState {
        case .idle, .paused:
            newState.playbackState = .preparingToPlay
            newState.canAcceptInput = false
            sideEffects.append(.log(level: .info, message: "Play button tapped"))
            sideEffects.append(.playSounds(ids: newState.activeSounds.map { $0.id }, fadeDuration: 1.0))
            
        case .playing:
            newState.playbackState = .preparingToPause
            newState.canAcceptInput = false
            sideEffects.append(.log(level: .info, message: "Pause button tapped"))
            sideEffects.append(.pauseSounds(ids: newState.activeSounds.map { $0.id }, fadeDuration: 1.0))
            
        case .fadingIn:
            // Cancel fade in and pause
            newState.playbackState = .preparingToPause
            newState.canAcceptInput = false
            sideEffects.append(.log(level: .info, message: "Pause during fade in"))
            sideEffects.append(.pauseSounds(ids: newState.activeSounds.map { $0.id }, fadeDuration: 0.5))
            
        case .fadingOut:
            // Cancel fade out and play
            newState.playbackState = .preparingToPlay
            newState.canAcceptInput = false
            sideEffects.append(.log(level: .info, message: "Play during fade out"))
            sideEffects.append(.playSounds(ids: newState.activeSounds.map { $0.id }, fadeDuration: 0.5))
            
        default:
            sideEffects.append(.log(level: .warning, message: "Invalid state for play/pause: \(state.playbackState)"))
        }
        
        return (newState, sideEffects)
    }
    
    private func handleTimerSelection(state: WhiteNoisesState, mode: TimerService.TimerMode) -> (WhiteNoisesState, [WhiteNoisesSideEffect]) {
        var newState = state
        var sideEffects: [WhiteNoisesSideEffect] = []
        
        newState.timerState.mode = mode
        newState.timerState.remainingSeconds = mode.totalSeconds
        
        if mode != .off {
            sideEffects.append(.log(level: .info, message: "Timer set to \(mode.description)"))
            
            if newState.isPlaying {
                newState.timerState.startTime = Date()
                newState.timerState.isActive = true
                sideEffects.append(.startTimer(seconds: mode.totalSeconds))
            }
        } else {
            newState.timerState = ScreenTimerState()
            sideEffects.append(.log(level: .info, message: "Timer cancelled"))
            sideEffects.append(.stopTimer)
        }
        
        return (newState, sideEffects)
    }
    
    private func handleVolumeChange(state: WhiteNoisesState, soundId: UUID, volume: Float) -> (WhiteNoisesState, [WhiteNoisesSideEffect]) {
        var newState = state
        var sideEffects: [WhiteNoisesSideEffect] = []
        
        if let index = newState.sounds.firstIndex(where: { $0.id == soundId }) {
            let previousVolume = newState.sounds[index].volume
            newState.sounds[index].volume = volume
            
            sideEffects.append(.updateSoundVolume(id: soundId, volume: volume))
            
            if previousVolume == 0 && volume > 0 && newState.isPlaying {
                sideEffects.append(.log(level: .info, message: "Sound enabled: \(newState.sounds[index].name)"))
                sideEffects.append(.playSounds(ids: [soundId], fadeDuration: 0.5))
            } else if previousVolume > 0 && volume == 0 && newState.isPlaying {
                sideEffects.append(.log(level: .info, message: "Sound disabled: \(newState.sounds[index].name)"))
                sideEffects.append(.pauseSounds(ids: [soundId], fadeDuration: 0.5))
            }
        }
        
        return (newState, sideEffects)
    }
    
    private func handleSoundVariantChange(state: WhiteNoisesState, soundId: UUID, variant: Sound.SoundVariant) -> (WhiteNoisesState, [WhiteNoisesSideEffect]) {
        var newState = state
        var sideEffects: [WhiteNoisesSideEffect] = []
        
        if let index = newState.sounds.firstIndex(where: { $0.id == soundId }) {
            newState.sounds[index].selectedVariant = variant
            sideEffects.append(.updateSoundVariant(id: soundId, variant: variant))
            sideEffects.append(.log(level: .info, message: "Sound variant changed: \(newState.sounds[index].name) -> \(variant.name)"))
        }
        
        return (newState, sideEffects)
    }
}