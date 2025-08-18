//
//  WhiteNoisesState.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 2025-08-14.
//

import Foundation

// MARK: - Screen State
struct WhiteNoisesState: Equatable {
    var playbackState: PlaybackState = .idle
    var timerState: ScreenTimerState = ScreenTimerState()
    var sounds: [SoundState] = []
    var isLoading: Bool = false
    var error: String?
    var canAcceptInput: Bool = true
    var lastActionTime: Date = Date()
    
    var isPlaying: Bool {
        switch playbackState {
        case .playing, .fadingIn:
            return true
        default:
            return false
        }
    }
    
    var activeSounds: [SoundState] {
        sounds.filter { $0.volume > 0 }
    }
}

// MARK: - Playback State
enum PlaybackState: Equatable {
    case idle
    case preparingToPlay
    case playing
    case fadingIn(progress: Double)
    case fadingOut(progress: Double)
    case preparingToPause
    case paused
    case error(String)
    
    var isTransitioning: Bool {
        switch self {
        case .preparingToPlay, .preparingToPause, .fadingIn, .fadingOut:
            return true
        default:
            return false
        }
    }
}

// MARK: - Timer State
struct ScreenTimerState: Equatable {
    var mode: TimerService.TimerMode = .off
    var startTime: Date?
    var pausedTime: TimeInterval = 0
    var remainingSeconds: Int = 0
    var isActive: Bool = false
    
    var displayTime: String {
        guard remainingSeconds > 0 else { return "" }
        
        let hours = remainingSeconds / 3600
        let minutes = (remainingSeconds % 3600) / 60
        let seconds = remainingSeconds % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Sound State
struct SoundState: Equatable, Identifiable {
    let id: UUID
    let name: String
    let iconName: String
    var volume: Float
    var selectedVariant: Sound.SoundVariant
    let availableVariants: [Sound.SoundVariant]
    var isPlaying: Bool = false
    var isFading: Bool = false
}