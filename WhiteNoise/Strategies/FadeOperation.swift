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
    private var operationId: UInt64 = 0  // Track current operation to detect cancellation
    
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
        operationId &+= 1
        let currentOperationId = operationId

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

        // STABILITY FIX: Ensure player is in correct state after fade (completed or cancelled)
        // Only apply if this operation wasn't superseded by a newer one
        guard currentOperationId == operationId else { return }

        if !player.isPlaying {
            _ = player.play()
        }
        player.volume = targetVolume
    }
    
    func fadeOut(
        player: AudioPlayerProtocol,
        duration: Double
    ) async {
        cancel()
        operationId &+= 1
        let currentOperationId = operationId

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

        // STABILITY FIX: Ensure player is paused after fade-out (completed or cancelled)
        // Only apply if this operation wasn't superseded by a newer one
        guard currentOperationId == operationId else { return }

        if player.isPlaying {
            player.pause()
        }
        player.volume = 0
    }
    
    func cancel() {
        fadeTask?.cancel()
        fadeTask = nil
        operationId &+= 1  // Invalidate any pending post-await state updates
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