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

@MainActor
class SoundViewModel: ObservableObject, Identifiable {
    
    // MARK: - Published Properties
    @Published var volume: Float {
        didSet {
            Task {
                await updatePlayerVolume(volume)
                sound.volume = volume
                await persistenceService.save(sound)
            }
        }
    }
    @Published var selectedSoundVariant: Sound.SoundVariant
    @Published var sliderWidth: CGFloat = 0.0
    @Published var sliderHeight: CGFloat = 0.0
    @Published var lastDragValue: CGFloat = 0.0
    
    // MARK: - Public Properties
    var maxWidth: CGFloat = 0 {
        didSet {
            withAnimation(.spring(duration: AppConstants.Animation.springDuration)) {
                self.sliderWidth = CGFloat(sound.volume) * self.maxWidth
            }
        }
    }
    
    var maxHeight: CGFloat = 0 {
        didSet {
            withAnimation(.spring(duration: AppConstants.Animation.springDuration)) {
                self.sliderHeight = CGFloat(sound.volume) * self.maxHeight
            }
        }
    }
    
    private(set) var sound: Sound
    
    // MARK: - Private Properties
    private var player: AudioPlayerProtocol?
    private var fadeTask: Task<Void, Never>?
    private let playerFactory: AudioPlayerFactoryProtocol
    private let persistenceService: SoundPersistenceService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(
        sound: Sound,
        playerFactory: AudioPlayerFactoryProtocol = AVAudioPlayerFactory(),
        persistenceService: SoundPersistenceService = SoundPersistenceService()
    ) {
        self.sound = sound
        self.volume = sound.volume
        self.lastDragValue = CGFloat(sound.volume) * maxWidth
        self.selectedSoundVariant = sound.selectedSoundVariant
        self.playerFactory = playerFactory
        self.persistenceService = persistenceService
        
        setupSoundVariantObserver()
        loadAudioAsync()
    }
    
    deinit {
        fadeTask?.cancel()
    }
    
    // MARK: - Public Methods
    func refreshAudioPlayer() async {
        print("🎵 \(sound.name): Refreshing audio player")
        let wasPlaying = player?.isPlaying ?? false
        player?.stop()
        player = nil
        
        await prepareSound(fileName: sound.selectedSoundVariant.filename)
        
        if wasPlaying {
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
    
    func playSound(fadeDuration: Double? = nil) async {
        print("🎵 \(sound.name): playSound called with fade: \(fadeDuration ?? 0)")
        
        fadeTask?.cancel()
        
        guard let player = player else {
            print("❌ \(sound.name): No player available")
            return
        }
        
        if let fadeDuration = fadeDuration, fadeDuration > 0 {
            await fadeIn(duration: fadeDuration)
        } else {
            player.volume = sound.volume
            if !player.isPlaying {
                let success = player.play()
                print("\(success ? "✅" : "❌") \(sound.name): Started playing (success: \(success))")
            }
        }
    }
    
    func pauseSound(fadeDuration: Double? = nil) async {
        print("🎵 \(sound.name): pauseSound called with fade: \(fadeDuration ?? 0)")
        
        fadeTask?.cancel()
        
        guard let player = player else {
            print("❌ \(sound.name): No player to pause")
            return
        }
        
        if let fadeDuration = fadeDuration, fadeDuration > 0 {
            await fadeOut(duration: fadeDuration)
        } else {
            player.pause()
            print("✅ \(sound.name): Paused immediately")
        }
    }
    
    // MARK: - Private Methods
    private func loadAudioAsync() {
        Task.detached(priority: .userInitiated) { [weak self] in
            await self?.prepareSound(fileName: self?.sound.selectedSoundVariant.filename ?? "")
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
        await persistenceService.save(sound)
        
        let wasPlaying = player?.isPlaying ?? false
        player?.stop()
        
        await prepareSound(fileName: newVariant.filename)
        
        if wasPlaying {
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
    
    private func fadeIn(duration: Double) async {
        fadeTask = Task { [weak self] in
            guard let self = self, let player = self.player else { return }
            
            player.volume = 0
            if !player.isPlaying {
                let success = player.play()
                print("\(success ? "✅" : "❌") \(sound.name): Started playing with fade")
            }
            
            await performFade(
                from: 0,
                to: self.sound.volume,
                duration: duration
            )
        }
    }
    
    private func fadeOut(duration: Double) async {
        fadeTask = Task { [weak self] in
            guard let self = self, let player = self.player else { return }
            
            let startVolume = player.volume
            
            await performFade(
                from: startVolume,
                to: 0,
                duration: duration
            )
            
            if !Task.isCancelled {
                player.pause()
                print("✅ \(self.sound.name): Paused with fade")
            }
        }
    }
    
    private func performFade(from startVolume: Float, to endVolume: Float, duration: Double) async {
        let steps = Int(duration * Double(AppConstants.Animation.fadeSteps))
        let volumeDelta = (endVolume - startVolume) / Float(steps)
        
        for step in 0..<steps {
            guard !Task.isCancelled else { break }
            
            let currentVolume = startVolume + (volumeDelta * Float(step))
            player?.volume = currentVolume
            
            try? await Task.sleep(nanoseconds: AppConstants.Animation.fadeStepDuration)
        }
        
        if !Task.isCancelled {
            player?.volume = endVolume
        }
    }
}

// MARK: - Sound Persistence Service
class SoundPersistenceService {
    func save(_ sound: Sound) async {
        await Task.detached(priority: .background) { [sound] in
            do {
                let soundData = try JSONEncoder().encode(sound)
                UserDefaults.standard.set(soundData, forKey: AppConstants.UserDefaults.soundPrefix + sound.id)
            } catch {
                print("Failed to save sound: \(error)")
            }
        }.value
    }
    
    func load(soundId: String) -> Sound? {
        guard let data = UserDefaults.standard.data(forKey: AppConstants.UserDefaults.soundPrefix + soundId) else {
            return nil
        }
        
        do {
            return try JSONDecoder().decode(Sound.self, from: data)
        } catch {
            print("Failed to load sound: \(error)")
            return nil
        }
    }
}