//
//  SoundViewModel.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 31.05.2023.
//

import Foundation
import AVFoundation
import Observation

@Observable @MainActor
final class SoundViewModel: Identifiable {

    // MARK: - Computed Properties
    var isPlaying: Bool {
        player?.isPlaying ?? false
    }
    
    // MARK: - Observable Properties
    var volume: Float {
        didSet {
            // Coalesce rapid writes — only the final value gets persisted
            volumePersistenceTask?.cancel()

            volumePersistenceTask = Task { [weak self] in
                guard let self = self else { return }
                await self.updatePlayerVolume(volume)
                self.sound.volume = volume
                self.persistenceService.save(self.sound)
            }

            onVolumeChanged?(self, volume)
        }
    }
    var selectedSoundVariant: Sound.SoundVariant {
        didSet {
            guard selectedSoundVariant != oldValue else { return }
            Task { await handleSoundVariantChange(selectedSoundVariant) }
        }
    }
    /// Called by WhiteNoisesViewModel to observe volume changes
    @ObservationIgnored
    var onVolumeChanged: ((SoundViewModel, Float) -> Void)?

    private(set) var sound: Sound
    
    // MARK: - Private Properties
    @ObservationIgnored
    private var player: AudioPlayerProtocol?
    @ObservationIgnored
    private let fadeOperation: FadeOperation
    @ObservationIgnored
    private let playerFactory: AudioPlayerFactoryProtocol
    @ObservationIgnored
    private let persistenceService: SoundPersistenceServiceProtocol
    @ObservationIgnored
    private nonisolated(unsafe) var fadeTask: Task<Void, Never>?
    @ObservationIgnored
    private var isAudioLoaded = false
    @ObservationIgnored
    private nonisolated(unsafe) var audioLoadingTask: Task<Void, Never>?
    @ObservationIgnored
    private nonisolated(unsafe) var volumePersistenceTask: Task<Void, Never>?
    
    // MARK: - Initialization
    init(
        sound: Sound,
        playerFactory: AudioPlayerFactoryProtocol,
        persistenceService: SoundPersistenceServiceProtocol,
        fadeType: FadeType = .linear
    ) {
        self.sound = sound
        self.volume = sound.volume
        self.selectedSoundVariant = sound.selectedSoundVariant
        self.playerFactory = playerFactory
        self.persistenceService = persistenceService
        self.fadeOperation = FadeOperation(fadeType: fadeType)
    }

    /// Convenience factory for production use
    static func make(sound: Sound) -> SoundViewModel {
        SoundViewModel(
            sound: sound,
            playerFactory: AVAudioPlayerFactory(),
            persistenceService: SoundPersistenceService()
        )
    }
    
    deinit {
        fadeTask?.cancel()
        audioLoadingTask?.cancel()
        volumePersistenceTask?.cancel()
    }
    
    // MARK: - Public Methods
    func refreshAudioPlayer() async {
        LoggingService.logAudio("\(sound.name): Refreshing audio player")
        let wasPlaying = player?.isPlaying ?? false
        player?.stop()
        player = nil
        isAudioLoaded = false
        audioLoadingTask?.cancel()
        audioLoadingTask = nil
        
        if wasPlaying {
            // playSound will load the audio
            await playSound()
        }
    }
    
    /// Starts playback of the sound with an optional fade-in effect.
    ///
    /// This method ensures the audio is loaded before starting playback. If a fade duration
    /// is specified, the sound will fade in from silence to the target volume over the
    /// specified duration.
    ///
    /// - Parameter fadeDuration: The duration in seconds for the fade-in effect.
    ///   If `nil`, the sound will start immediately at its set volume.
    ///
    /// - Note: This method is idempotent - calling it multiple times while already
    ///   playing will not cause issues.
    ///
    /// - Important: The method ensures audio is loaded before playback, which may
    ///   cause a slight delay on first play.
    func playSound(fadeDuration: Double? = nil) async {
        fadeOperation.cancel()

        await ensureAudioLoaded()

        // Retry once if player is nil (edge case: audio load failed silently)
        if player == nil {
            LoggingService.logWarning("\(sound.name): Player nil after first load, retrying")
            isAudioLoaded = false
            await ensureAudioLoaded()
        }

        guard let player = player else {
            LoggingService.logError("\(sound.name): No player available after loading (tried 2x)")
            TelemetryService.captureNonFatal(
                message: "SoundViewModel.playSound missing player after load",
                level: .error,
                extra: [
                    "soundName": sound.name,
                    "audioLoaded": isAudioLoaded,
                    "variantFilename": sound.selectedSoundVariant.filename
                ]
            )
            return
        }

        if let fadeDuration = fadeDuration, fadeDuration > 0 {
            await fadeOperation.fadeIn(
                player: player,
                targetVolume: sound.volume,
                duration: fadeDuration
            )
        } else {
            player.volume = sound.volume
            if !player.isPlaying {
                let success = player.play()

                // If play() fails, the player may have been invalidated after long background
                if !success {
                    LoggingService.logWarning("\(sound.name): Play failed, reloading audio")
                    self.player = nil
                    isAudioLoaded = false
                    await ensureAudioLoaded()
                    if let newPlayer = self.player {
                        newPlayer.volume = sound.volume
                        let retrySuccess = newPlayer.play()
                        if !retrySuccess {
                            LoggingService.logError("\(sound.name): Retry play also failed")
                        }
                    }
                }
            }
        }
    }
    
    /// Pauses playback of the sound with an optional fade-out effect.
    ///
    /// This method stops the sound playback. If a fade duration is specified, the sound
    /// will fade out from its current volume to silence over the specified duration
    /// before pausing.
    ///
    /// - Parameter fadeDuration: The duration in seconds for the fade-out effect.
    ///   If `nil`, the sound will pause immediately.
    ///
    /// - Note: Any ongoing fade operations will be cancelled before starting the pause.
    func pauseSound(fadeDuration: Double? = nil) async {
        fadeOperation.cancel()

        guard let player = player else {
            TelemetryService.captureNonFatal(
                message: "SoundViewModel.pauseSound missing player",
                level: .warning,
                extra: ["soundName": sound.name]
            )
            return
        }

        if let fadeDuration = fadeDuration, fadeDuration > 0 {
            await fadeOperation.fadeOut(player: player, duration: fadeDuration)
        } else if player.isPlaying {
            player.pause()
        }
    }
    
    // MARK: - Audio Loading Methods

    /// Preloads audio for this sound and waits for completion.
    /// Use this for sequential preloading to avoid I/O contention.
    func preloadAudio() async {
        await ensureAudioLoaded()
    }

    func loadAudioAsync() {
        guard !isAudioLoaded && audioLoadingTask == nil else { return }

        // Capture values before Task to avoid Sendable issues
        let filename = sound.selectedSoundVariant.filename
        let soundName = sound.name

        audioLoadingTask = Task { [weak self] in
            await self?.prepareSound(fileName: filename)

            // Check cancellation after async work to avoid stale state modifications
            guard !Task.isCancelled else { return }

            if self?.player != nil {
                self?.isAudioLoaded = true
            } else {
                self?.isAudioLoaded = false
                LoggingService.logError("\(soundName): Audio load completed without player")
                TelemetryService.captureNonFatal(
                    message: "SoundViewModel.loadAudioAsync completed without player",
                    level: .error,
                    extra: [
                        "soundName": soundName,
                        "variant": filename
                    ]
                )
            }
            self?.audioLoadingTask = nil
        }
    }
    
    private func ensureAudioLoaded() async {
        // Check if we already have a working player
        // Also verify the player's duration is valid (> 0) as a health check
        // after long background periods the player might be invalidated
        if let existingPlayer = player, isAudioLoaded, existingPlayer.duration > 0 {
            return
        }

        if let existingPlayer = player, existingPlayer.duration <= 0 {
            LoggingService.logWarning("\(sound.name): Player invalidated, reloading")
            player = nil
            isAudioLoaded = false
        }

        if !isAudioLoaded {
            loadAudioAsync()
            // Wait for audio to load
            if let task = audioLoadingTask {
                await task.value
            }
        }
    }
    
    private func handleSoundVariantChange(_ newVariant: Sound.SoundVariant) async {
        sound.selectedSoundVariant = newVariant
        persistenceService.save(sound)
        
        let wasPlaying = player?.isPlaying ?? false
        player?.stop()
        player = nil
        isAudioLoaded = false
        audioLoadingTask?.cancel()
        audioLoadingTask = nil
        
        if wasPlaying {
            // playSound will load the new audio
            await playSound()
        }
    }
    
    private func prepareSound(fileName: String) async {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            player = try await playerFactory.createPlayer(for: fileName)
            player?.volume = sound.volume

            let loadTime = CFAbsoluteTimeGetCurrent() - startTime
            if loadTime > AppConstants.Audio.slowLoadThreshold {
                LoggingService.logWarning("\(sound.name): Slow audio load \(String(format: "%.2f", loadTime))s")
            }
        } catch {
            LoggingService.logError("\(sound.name): Failed to load audio - \(error.localizedDescription)")
            TelemetryService.captureNonFatal(
                error: error,
                message: "SoundViewModel.prepareSound failed",
                extra: [
                    "soundName": sound.name,
                    "fileName": fileName
                ]
            )
        }
    }
    
    private func updatePlayerVolume(_ volume: Float) async {
        player?.volume = volume
    }
    
    // Fade operations are now handled by FadeOperation class using Strategy pattern
}

// MARK: - Fade & Control

extension SoundViewModel {
    func fadeIn(duration: Double) async {
        guard let player = player else {
            TelemetryService.captureNonFatal(
                message: "SoundViewModel.fadeIn missing player",
                extra: ["soundName": sound.name, "duration": duration]
            )
            return
        }
        await fadeOperation.fadeIn(player: player, targetVolume: sound.volume, duration: duration)
    }

    func fadeOut(duration: Double) async {
        guard let player = player else {
            TelemetryService.captureNonFatal(
                message: "SoundViewModel.fadeOut missing player",
                extra: ["soundName": sound.name, "duration": duration]
            )
            return
        }
        await fadeOperation.fadeOut(player: player, duration: duration)
    }

    func stop() async {
        fadeOperation.cancel()
        player?.stop()
    }

    func cancelFade() {
        fadeOperation.cancel()
    }
}
