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
protocol SoundPlaybackControl: AnyObject {
    var sound: Sound { get }
    var isPlaying: Bool { get }
    
    func playSound(fadeDuration: Double?) async
    func pauseSound(fadeDuration: Double?) async
    func stop() async
    func refreshAudioPlayer() async
}

/// Protocol for fade operations
protocol FadeOperations: AnyObject {
    func fadeIn(duration: Double) async
    func fadeOut(duration: Double) async
    func performFade(from startVolume: Float, to endVolume: Float, duration: Double) async
}

@MainActor
class SoundViewModel: ObservableObject, Identifiable, @preconcurrency VolumeControlWithGestures, @preconcurrency SoundPlaybackControl, FadeOperations {
    
    // MARK: - Computed Properties for Protocols
    var isPlaying: Bool {
        player?.isPlaying ?? false
    }
    
    // MARK: - Published Properties
    @Published var volume: Float {
        didSet {
            let oldValue = oldValue
            print("🔊 SoundVM.\(sound.name) - VOLUME CHANGE: \(String(format: "%.2f", oldValue))→\(String(format: "%.2f", volume))")
            
            Task {
                await updatePlayerVolume(volume)
                sound.volume = volume
                persistenceService.save(sound)
                print("💾 SoundVM.\(sound.name) - VOLUME SAVED: \(String(format: "%.2f", volume))")
            }
        }
    }
    @Published var selectedSoundVariant: Sound.SoundVariant
    @Published var sliderWidth: CGFloat
    @Published var sliderHeight: CGFloat
    @Published var lastDragValue: CGFloat
    
    // MARK: - Public Properties
    var maxWidth: CGFloat = 0 {
        didSet {
            withAnimation(.spring(duration: AppConstants.Animation.springDuration)) {
                self.sliderWidth = CGFloat(volume) * self.maxWidth
            }
            self.lastDragValue = self.sliderWidth
        }
    }
    
    var maxHeight: CGFloat = 0 {
        didSet {
            withAnimation(.spring(duration: AppConstants.Animation.springDuration)) {
                self.sliderHeight = CGFloat(volume) * self.maxHeight
            }
            self.lastDragValue = self.sliderHeight
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
    
    // MARK: - Initialization
    init(
        sound: Sound,
        playerFactory: AudioPlayerFactoryProtocol = AVAudioPlayerFactory(),
        persistenceService: SoundPersistenceServiceProtocol = SoundPersistenceService(),
        fadeType: FadeType = .linear) {
        self.sound = sound
        self.volume = sound.volume
        self.selectedSoundVariant = sound.selectedSoundVariant
        self.playerFactory = playerFactory
        self.persistenceService = persistenceService
        self.fadeOperation = FadeOperation(fadeType: fadeType)
        
        // Initialize slider properties with estimated default width
        // This will be updated when maxWidth is set, but provides immediate visual feedback
        let estimatedWidth: CGFloat = 150 // Reasonable default for initial display
        let initialSliderWidth = CGFloat(sound.volume) * estimatedWidth
        self.sliderWidth = initialSliderWidth
        self.sliderHeight = CGFloat(sound.volume) * estimatedWidth
        self.lastDragValue = initialSliderWidth
        
        setupSoundVariantObserver()
        // Don't load audio in init - let it load lazily when needed
    }
    
    deinit {
        fadeTask?.cancel()
        audioLoadingTask?.cancel()
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
        let newWidth = newTranslationWidth + lastDragValue
        sliderWidth = min(max(0, newWidth), maxWidth)
        
        let progress = maxWidth > 0 ? sliderWidth / maxWidth : 0
        volume = Float(min(max(0, progress), 1.0))
    }
    
    func dragDidChangeVertical(newTranslationHeight: CGFloat) {
        let newHeight = newTranslationHeight + lastDragValue
        sliderHeight = min(max(0, newHeight), maxHeight)
        
        let progress = maxHeight > 0 ? sliderHeight / maxHeight : 0
        volume = Float(min(max(0, progress), 1.0))
    }
    
    func dragDidEnded() {
        sliderWidth = min(max(0, sliderWidth), maxWidth)
        sliderHeight = min(max(0, sliderHeight), maxHeight)
        lastDragValue = sliderWidth
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
        
        // Ensure audio is loaded before playing
        if !isAudioLoaded {
            print("🎵 SoundVM.\(sound.name) - LOADING: Audio not loaded, loading now...")
        }
        await ensureAudioLoaded()
        
        guard let player = player else {
            print("❌ SoundVM.\(sound.name).playSound - FAILED: No player available after loading")
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
        
        audioLoadingTask = Task.detached(priority: .userInitiated) { [weak self] in
            await self?.prepareSound(fileName: self?.sound.selectedSoundVariant.filename ?? "")
            await MainActor.run { [weak self] in
                self?.isAudioLoaded = true
                self?.audioLoadingTask = nil
            }
        }
    }
    
    private func ensureAudioLoaded() async {
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
        guard let player = player else { return }
        await fadeOperation.fadeIn(player: player, targetVolume: sound.volume, duration: duration)
    }
    
    func fadeOut(duration: Double) async {
        guard let player = player else { return }
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