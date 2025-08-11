//
//  SoundState.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 2025-08-11.
//

import Foundation

// MARK: - State Protocol

protocol SoundState {
    var name: String { get }
    func play(context: SoundStateContext) async
    func pause(context: SoundStateContext) async
    func stop(context: SoundStateContext) async
    func togglePlayPause(context: SoundStateContext) async
}

// MARK: - State Context

@MainActor
final class SoundStateContext {
    private(set) var currentState: SoundState {
        didSet {
            print("🔄 State changed from \(oldValue.name) to \(currentState.name)")
        }
    }
    
    let player: AudioPlayerProtocol
    let viewModel: SoundViewModel
    let fadeOperation: FadeOperation
    
    init(
        player: AudioPlayerProtocol,
        viewModel: SoundViewModel,
        fadeOperation: FadeOperation,
        initialState: SoundState? = nil
    ) {
        self.player = player
        self.viewModel = viewModel
        self.fadeOperation = fadeOperation
        self.currentState = initialState ?? StoppedState()
    }
    
    func setState(_ state: SoundState) async {
        currentState = state
    }
    
    func play() async {
        await currentState.play(context: self)
    }
    
    func pause() async {
        await currentState.pause(context: self)
    }
    
    func stop() async {
        await currentState.stop(context: self)
    }
    
    func togglePlayPause() async {
        await currentState.togglePlayPause(context: self)
    }
}

// MARK: - Concrete States

@MainActor
struct PlayingState: SoundState {
    let name = "Playing"
    
    func play(context: SoundStateContext) async {
        // Already playing, do nothing
        print("⚠️ Already in playing state")
    }
    
    func pause(context: SoundStateContext) async {
        context.fadeOperation.cancel()
        
        let fadeDuration = AppConstants.Animation.fadeOut
        await context.fadeOperation.fadeOut(
            player: context.player,
            duration: fadeDuration
        )
        
        await context.setState(PausedState())
    }
    
    func stop(context: SoundStateContext) async {
        context.fadeOperation.cancel()
        context.player.stop()
        await context.setState(StoppedState())
    }
    
    func togglePlayPause(context: SoundStateContext) async {
        await pause(context: context)
    }
}

@MainActor
struct PausedState: SoundState {
    let name = "Paused"
    
    func play(context: SoundStateContext) async {
        context.fadeOperation.cancel()
        
        let fadeDuration = AppConstants.Animation.fadeStandard
        await context.fadeOperation.fadeIn(
            player: context.player,
            targetVolume: context.viewModel.sound.volume,
            duration: fadeDuration
        )
        
        await context.setState(PlayingState())
    }
    
    func pause(context: SoundStateContext) async {
        // Already paused, do nothing
        print("⚠️ Already in paused state")
    }
    
    func stop(context: SoundStateContext) async {
        context.player.stop()
        await context.setState(StoppedState())
    }
    
    func togglePlayPause(context: SoundStateContext) async {
        await play(context: context)
    }
}

@MainActor
struct StoppedState: SoundState {
    let name = "Stopped"
    
    func play(context: SoundStateContext) async {
        // Check if player is ready
        guard context.player.isPlaying || context.player.volume >= 0 else {
            print("⚠️ Audio not loaded, cannot play")
            return
        }
        
        context.fadeOperation.cancel()
        
        let fadeDuration = AppConstants.Animation.fadeStandard
        await context.fadeOperation.fadeIn(
            player: context.player,
            targetVolume: context.viewModel.sound.volume,
            duration: fadeDuration
        )
        
        await context.setState(PlayingState())
    }
    
    func pause(context: SoundStateContext) async {
        // Can't pause when stopped
        print("⚠️ Cannot pause from stopped state")
    }
    
    func stop(context: SoundStateContext) async {
        // Already stopped
        print("⚠️ Already in stopped state")
    }
    
    func togglePlayPause(context: SoundStateContext) async {
        await play(context: context)
    }
}

@MainActor
struct LoadingState: SoundState {
    let name = "Loading"
    
    func play(context: SoundStateContext) async {
        print("⏳ Audio is loading, please wait...")
    }
    
    func pause(context: SoundStateContext) async {
        print("⏳ Cannot pause while loading")
    }
    
    func stop(context: SoundStateContext) async {
        await context.setState(StoppedState())
    }
    
    func togglePlayPause(context: SoundStateContext) async {
        print("⏳ Cannot toggle while loading")
    }
}

@MainActor
struct ErrorState: SoundState {
    let name = "Error"
    let error: Error
    
    func play(context: SoundStateContext) async {
        print("❌ Cannot play due to error: \(error.localizedDescription)")
    }
    
    func pause(context: SoundStateContext) async {
        print("❌ Cannot pause due to error state")
    }
    
    func stop(context: SoundStateContext) async {
        await context.setState(StoppedState())
    }
    
    func togglePlayPause(context: SoundStateContext) async {
        print("❌ Cannot toggle due to error state")
    }
}