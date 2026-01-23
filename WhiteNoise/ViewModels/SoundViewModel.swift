//
//  SoundViewModel.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 31.05.2023.
//

import Foundation
import AVFoundation
import Combine
import SwiftUI

// MARK: - Protocols

/// Protocol for volume control with drag gesture handling
@MainActor
protocol VolumeControlWithGestures: AnyObject {
    var volume: Float { get set }
    var sliderWidth: CGFloat { get set }
    var sliderHeight: CGFloat { get set }
    var lastDragValue: CGFloat { get set }
    var maxWidth: CGFloat { get set }
    var maxHeight: CGFloat { get set }

    func updateVolume(_ volume: Float) async
    func dragDidChange(newTranslationWidth: CGFloat)
    func dragDidChangeVertical(newTranslationHeight: CGFloat)
    func dragDidEnded()
}

/// Protocol for sound playback control
@MainActor
protocol SoundPlaybackControl: AnyObject {
    var sound: Sound { get }
    var isPlaying: Bool { get }

    func playSound(fadeDuration: Double?) async
    func pauseSound(fadeDuration: Double?) async
    func stop() async
    func refreshAudioPlayer() async
}

/// Protocol for fade operations
@MainActor
protocol FadeOperations: AnyObject {
    func fadeIn(duration: Double) async
    func fadeOut(duration: Double) async
    func performFade(from startVolume: Float, to endVolume: Float, duration: Double) async
}

@MainActor
class SoundViewModel: ObservableObject, Identifiable, VolumeControlWithGestures, SoundPlaybackControl, FadeOperations {
    
    // MARK: - Computed Properties for Protocols
    var isPlaying: Bool {
        player?.isPlaying ?? false
    }
    
    // MARK: - Published Properties
    @Published var volume: Float {
        didSet {
            let oldValue = oldValue
            print("🔊 SoundVM.\(sound.name) - VOLUME CHANGE: \(String(format: "%.2f", oldValue))→\(String(format: "%.2f", volume))")

            // CONCURRENCY & PERFORMANCE FIX: Cancel previous persistence task
            // This coalesces rapid writes - only the final value gets persisted
            volumePersistenceTask?.cancel()

            volumePersistenceTask = Task { [weak self] in
                guard let self = self else { return }
                await self.updatePlayerVolume(volume)
                self.sound.volume = volume
                self.persistenceService.save(self.sound)
                print("💾 SoundVM.\(self.sound.name) - VOLUME SAVED: \(String(format: "%.2f", volume))")
            }
        }
    }
    @Published var selectedSoundVariant: Sound.SoundVariant
    @Published var sliderWidth: CGFloat
    @Published var sliderHeight: CGFloat
    @Published var lastDragValue: CGFloat
    @Published var isVolumeInteractive: Bool
    
    // MARK: - Public Properties
    var maxWidth: CGFloat = 0 {
        didSet {
            guard maxWidth > 0 else { return }
            if shouldRunInitialVolumeAnimation {
                sliderWidth = 0
                lastDragValue = 0
            } else if !isRunningInitialVolumeAnimation {
                withAnimation(.spring(duration: AppConstants.Animation.springDuration)) {
                    sliderWidth = CGFloat(volume) * maxWidth
                }
                lastDragValue = sliderWidth
            }
            runInitialVolumeAnimationIfNeeded()
        }
    }
    
    var maxHeight: CGFloat = 0 {
        didSet {
            guard maxHeight > 0 else { return }
            if shouldRunInitialVolumeAnimation {
                sliderHeight = 0
            } else if !isRunningInitialVolumeAnimation {
                withAnimation(.spring(duration: AppConstants.Animation.springDuration)) {
                    sliderHeight = CGFloat(volume) * maxHeight
                }
                lastDragValue = sliderHeight
            }
            runInitialVolumeAnimationIfNeeded()
        }
    }
    
    private(set) var sound: Sound
    
    // MARK: - Private Properties
    private var player: AudioPlayerProtocol?
    private let fadeOperation: FadeOperation
    private let playerFactory: AudioPlayerFactoryProtocol
    private let persistenceService: SoundPersistenceServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private var fadeTask: Task<Void, Never>?
    private var isAudioLoaded = false
    private var audioLoadingTask: Task<Void, Never>?
    private var initialVolumeAnimationTask: Task<Void, Never>?
    private var volumePersistenceTask: Task<Void, Never>? // CONCURRENCY: Track volume save tasks
    private var shouldRunInitialVolumeAnimation = true
    private var isRunningInitialVolumeAnimation = false
    
    // MARK: - Initialization
    init(
        sound: Sound,
        playerFactory: AudioPlayerFactoryProtocol = AVAudioPlayerFactory(),
        persistenceService: SoundPersistenceServiceProtocol? = nil,
        fadeType: FadeType = .linear) {
        self.sound = sound
        self.volume = sound.volume
        self.selectedSoundVariant = sound.selectedSoundVariant
        self.playerFactory = playerFactory
        self.persistenceService = persistenceService ?? SoundPersistenceService()
        self.fadeOperation = FadeOperation(fadeType: fadeType)
        self.sliderWidth = 0
        self.sliderHeight = 0
        self.lastDragValue = 0
        self.shouldRunInitialVolumeAnimation = sound.volume > 0
        self.isVolumeInteractive = !shouldRunInitialVolumeAnimation
        
        setupSoundVariantObserver()
        // Don't load audio in init - let it load lazily when needed
    }
    
    deinit {
        fadeTask?.cancel()
        audioLoadingTask?.cancel()
        initialVolumeAnimationTask?.cancel()
        volumePersistenceTask?.cancel() // CONCURRENCY: Cancel pending volume saves
    }
    
    // MARK: - Public Methods
    func refreshAudioPlayer() async {
        print("🎵 \(sound.name): Refreshing audio player")
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
    
    func dragDidChange(newTranslationWidth: CGFloat) {
        guard isVolumeInteractive else { return }
        let newWidth = newTranslationWidth + lastDragValue
        sliderWidth = min(max(0, newWidth), maxWidth)
        
        let progress = maxWidth > 0 ? sliderWidth / maxWidth : 0
        volume = Float(min(max(0, progress), 1.0))
    }
    
    func dragDidChangeVertical(newTranslationHeight: CGFloat) {
        guard isVolumeInteractive else { return }
        let newHeight = newTranslationHeight + lastDragValue
        sliderHeight = min(max(0, newHeight), maxHeight)
        
        let progress = maxHeight > 0 ? sliderHeight / maxHeight : 0
        volume = Float(min(max(0, progress), 1.0))
    }
    
    func dragDidEnded() {
        guard isVolumeInteractive else { return }
        sliderWidth = min(max(0, sliderWidth), maxWidth)
        sliderHeight = min(max(0, sliderHeight), maxHeight)
        lastDragValue = sliderWidth
    }

    private func runInitialVolumeAnimationIfNeeded() {
        guard shouldRunInitialVolumeAnimation else { return }
        guard maxWidth > 0 || maxHeight > 0 else { return }

        shouldRunInitialVolumeAnimation = false

        let targetWidth = CGFloat(volume) * maxWidth
        let targetHeight = CGFloat(volume) * maxHeight

        guard targetWidth > 0 || targetHeight > 0 else {
            isVolumeInteractive = true
            return
        }

        isRunningInitialVolumeAnimation = true
        isVolumeInteractive = false
        sliderWidth = 0
        sliderHeight = 0
        lastDragValue = 0

        initialVolumeAnimationTask?.cancel()
        let duration = AppConstants.Animation.initialVolumeDuration
        initialVolumeAnimationTask = Task { [weak self] in
            guard let self = self else { return }

            withAnimation(.easeInOut(duration: duration)) {
                self.sliderWidth = targetWidth
                self.sliderHeight = targetHeight
            }

            let nanoseconds = UInt64(duration * 1_000_000_000)
            if nanoseconds > 0 {
                try? await Task.sleep(nanoseconds: nanoseconds)
            }

            // Check cancellation after sleep
            guard !Task.isCancelled else { return }

            let finalWidth = CGFloat(self.volume) * self.maxWidth
            let finalHeight = CGFloat(self.volume) * self.maxHeight
            self.sliderWidth = finalWidth
            self.sliderHeight = finalHeight

            if self.maxWidth > 0 {
                self.lastDragValue = self.sliderWidth
            } else {
                self.lastDragValue = self.sliderHeight
            }
            self.isRunningInitialVolumeAnimation = false
            self.isVolumeInteractive = true
            self.initialVolumeAnimationTask = nil
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
        print("🎯 SoundVM.\(sound.name).playSound - START: fade=\(fadeDuration ?? 0)s, volume=\(volume)")
        print("📊 SoundVM.\(sound.name) - PRE-STATE: isPlaying=\(isPlaying), audioLoaded=\(isAudioLoaded)")
        
        print("🔄 SoundVM.\(sound.name) - CANCELLING: Any previous fade operation")
        fadeOperation.cancel()
        
        // STABILITY FIX: Ensure audio is loaded before playing with retry logic
        if !isAudioLoaded {
            print("🎵 SoundVM.\(sound.name) - LOADING: Audio not loaded, loading now...")
        }
        await ensureAudioLoaded()

        // STABILITY FIX: Retry once if player is nil (edge case: audio load failed silently)
        if player == nil {
            print("⚠️ SoundVM.\(sound.name) - RETRY: Player nil after first load, retrying...")
            isAudioLoaded = false
            await ensureAudioLoaded()
        }

        guard let player = player else {
            print("❌ SoundVM.\(sound.name).playSound - FAILED: No player available after loading (tried 2x)")
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
        
        print("🎵 SoundVM.\(sound.name) - PLAYER STATE: isPlaying=\(player.isPlaying), volume=\(player.volume)")
        
        if let fadeDuration = fadeDuration, fadeDuration > 0 {
            print("🎚️ SoundVM.\(sound.name) - FADE IN: Starting \(fadeDuration)s fade to volume \(sound.volume)")
            await fadeOperation.fadeIn(
                player: player,
                targetVolume: sound.volume,
                duration: fadeDuration
            )
            print("✅ SoundVM.\(sound.name) - FADE IN COMPLETED")
        } else {
            player.volume = sound.volume
            if !player.isPlaying {
                print("🎵 SoundVM.\(sound.name) - PLAY: Starting immediate playback at volume \(sound.volume)")
                let success = player.play()
                print("\(success ? "✅" : "❌") SoundVM.\(sound.name) - PLAY \(success ? "SUCCESS" : "FAILED")")
            } else {
                print("🎵 SoundVM.\(sound.name) - ALREADY PLAYING: Skipping play call")
            }
        }
        
        print("✅ SoundVM.\(sound.name).playSound - COMPLETED: isPlaying=\(player.isPlaying)")
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
        print("🎯 SoundVM.\(sound.name).pauseSound - START: fade=\(fadeDuration ?? 0)s")
        print("📊 SoundVM.\(sound.name) - PRE-STATE: isPlaying=\(isPlaying)")
        
        print("🔄 SoundVM.\(sound.name) - CANCELLING: Any previous fade operation")
        fadeOperation.cancel()
        
        guard let player = player else {
            print("⚠️ SoundVM.\(sound.name).pauseSound - SKIPPED: No player to pause")
            TelemetryService.captureNonFatal(
                message: "SoundViewModel.pauseSound missing player",
                level: .warning,
                extra: ["soundName": sound.name]
            )
            return
        }
        
        print("🎵 SoundVM.\(sound.name) - PLAYER STATE: isPlaying=\(player.isPlaying), volume=\(player.volume)")
        
        if let fadeDuration = fadeDuration, fadeDuration > 0 {
            print("🎚️ SoundVM.\(sound.name) - FADE OUT: Starting \(fadeDuration)s fade out")
            await fadeOperation.fadeOut(player: player, duration: fadeDuration)
            print("✅ SoundVM.\(sound.name) - FADE OUT COMPLETED")
        } else {
            if player.isPlaying {
                print("🎵 SoundVM.\(sound.name) - PAUSE: Stopping playback immediately")
                player.pause()
                print("✅ SoundVM.\(sound.name) - PAUSED")
            } else {
                print("⚠️ SoundVM.\(sound.name) - ALREADY PAUSED: Skipping pause call")
            }
        }
        
        print("✅ SoundVM.\(sound.name).pauseSound - COMPLETED: isPlaying=\(player.isPlaying)")
    }
    
    // MARK: - Private Methods
    func loadAudioAsync() {
        guard !isAudioLoaded && audioLoadingTask == nil else { return }

        // Capture values before Task to avoid Sendable issues
        let filename = sound.selectedSoundVariant.filename
        let soundName = sound.name

        audioLoadingTask = Task { [weak self] in
            await self?.prepareSound(fileName: filename)
            // Only mark as loaded if we actually have a player
            if self?.player != nil {
                self?.isAudioLoaded = true
                print("✅ \(soundName) - AUDIO LOADED: Player available")
            } else {
                self?.isAudioLoaded = false
                print("❌ \(soundName) - AUDIO LOAD FAILED: No player created")
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
        if player != nil && isAudioLoaded {
            return
        }
        
        if !isAudioLoaded {
            loadAudioAsync()
            // Wait for audio to load
            if let task = audioLoadingTask {
                await task.value
            }
        }
    }
    
    private func setupSoundVariantObserver() {
        $selectedSoundVariant
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] selectedSoundVariant in
                Task { [weak self] in
                    await self?.handleSoundVariantChange(selectedSoundVariant)
                }
            }
            .store(in: &cancellables)
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
                print("⚠️ Slow audio load for \(fileName): \(String(format: "%.2f", loadTime))s")
            } else {
                print("✅ \(sound.name): Audio loaded successfully (\(String(format: "%.2f", loadTime))s)")
            }
        } catch {
            print("❌ \(sound.name): Error loading audio player: \(error)")
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

// MARK: - FadeOperations Protocol Implementation
extension SoundViewModel {
    func fadeIn(duration: Double) async {
        guard let player = player else {
            TelemetryService.captureNonFatal(
                message: "SoundViewModel.fadeIn missing player",
                extra: [
                    "soundName": sound.name,
                    "duration": duration
                ]
            )
            return
        }
        await fadeOperation.fadeIn(player: player, targetVolume: sound.volume, duration: duration)
    }

    func fadeOut(duration: Double) async {
        guard let player = player else {
            TelemetryService.captureNonFatal(
                message: "SoundViewModel.fadeOut missing player",
                extra: [
                    "soundName": sound.name,
                    "duration": duration
                ]
            )
            return
        }
        await fadeOperation.fadeOut(player: player, duration: duration)
    }
    
    func performFade(from startVolume: Float, to endVolume: Float, duration: Double) async {
        // This method is not needed with the new Strategy pattern implementation
        // but kept for protocol compliance. The actual fade logic is in FadeOperation.
    }
}

// MARK: - Protocol Conformance

extension SoundViewModel {
    /// Stop playback immediately
    func stop() async {
        fadeOperation.cancel()
        player?.stop()
    }
    
    /// Update volume on the player
    func updateVolume(_ volume: Float) async {
        await updatePlayerVolume(volume)
    }
}
