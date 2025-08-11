//
//  FadeOperation.swift
//  WhiteNoise
//
//  Handles fade operations using Strategy pattern
//

import Foundation

@MainActor
final class FadeOperation {
    
    // MARK: - Properties
    
    private let fadeContext: FadeContext
    private var fadeTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    init(fadeType: FadeType = .linear) {
        self.fadeContext = FadeContext(fadeType: fadeType)
    }
    
    // MARK: - Public Methods
    
    func fadeIn(
        player: AudioPlayerProtocol,
        targetVolume: Float,
        duration: Double
    ) async {
        cancel()
        
        fadeTask = Task { [weak self] in
            guard let self = self else { return }
            
            player.volume = 0
            if !player.isPlaying {
                _ = player.play()
            }
            
            await self.performFade(
                player: player,
                from: 0,
                to: targetVolume,
                duration: duration
            )
        }
        
        await fadeTask?.value
    }
    
    func fadeOut(
        player: AudioPlayerProtocol,
        duration: Double
    ) async {
        cancel()
        
        fadeTask = Task { [weak self] in
            guard let self = self else { return }
            
            let startVolume = player.volume
            
            await self.performFade(
                player: player,
                from: startVolume,
                to: 0,
                duration: duration
            )
            
            if !Task.isCancelled {
                player.pause()
            }
        }
        
        await fadeTask?.value
    }
    
    func cancel() {
        fadeTask?.cancel()
        fadeTask = nil
    }
    
    // MARK: - Private Methods
    
    private func performFade(
        player: AudioPlayerProtocol,
        from startVolume: Float,
        to endVolume: Float,
        duration: Double
    ) async {
        let steps = Int(duration * Double(AppConstants.Animation.fadeSteps))
        let stepDuration = duration / Double(steps)
        
        for step in 0...steps {
            guard !Task.isCancelled else { break }
            
            let progress = Double(step) / Double(steps)
            let volume = fadeContext.calculateVolume(
                at: progress,
                from: startVolume,
                to: endVolume
            )
            
            player.volume = volume
            
            if step < steps {
                try? await Task.sleep(nanoseconds: UInt64(stepDuration * 1_000_000_000))
            }
        }
        
        if !Task.isCancelled {
            player.volume = endVolume
        }
    }
}