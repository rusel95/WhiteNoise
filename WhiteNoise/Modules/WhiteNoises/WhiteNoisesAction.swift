//
//  WhiteNoisesAction.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 2025-08-14.
//

import Foundation

// MARK: - Screen Actions
enum WhiteNoisesAction {
    // User Actions
    case userTappedPlayPause
    case userSelectedTimer(mode: TimerService.TimerMode)
    case userChangedVolume(soundId: UUID, volume: Float)
    case userSelectedSoundVariant(soundId: UUID, variant: Sound.SoundVariant)
    
    // System Actions
    case loadSounds([SoundState])
    case startPlayback
    case pausePlayback
    case updatePlaybackState(PlaybackState)
    case startFadeIn
    case fadeInProgress(Double)
    case fadeInCompleted
    case startFadeOut
    case fadeOutProgress(Double)
    case fadeOutCompleted
    
    // Timer Actions
    case startTimer
    case pauseTimer
    case resumeTimer
    case timerTick
    case timerExpired
    
    // Error Actions
    case setError(String)
    case clearError
    
    // Loading Actions
    case setLoading(Bool)
}

// MARK: - Side Effects
enum WhiteNoisesSideEffect {
    case playSounds(ids: [UUID], fadeDuration: Double?)
    case pauseSounds(ids: [UUID], fadeDuration: Double?)
    case updateSoundVolume(id: UUID, volume: Float)
    case updateSoundVariant(id: UUID, variant: Sound.SoundVariant)
    case startTimer(seconds: Int)
    case stopTimer
    case saveState
    case log(level: LogLevel, message: String)
    
    enum LogLevel {
        case debug, info, warning, error
    }
}