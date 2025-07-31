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
    
    @Published var volume: Float {
        didSet {
            Task {
                await updatePlayerVolume(volume)
                sound.volume = volume
                saveSound()
            }
        }
    }
    @Published var selectedSoundVariant: Sound.SoundVariant
    @Published var sliderWidth: CGFloat = 0.0
    @Published var sliderHeight: CGFloat = 0.0
    @Published var lastDragValue: CGFloat = 0.0
    
    var maxWidth: CGFloat = 0 {
        didSet {
            withAnimation(.spring(duration: 1)) {
                self.sliderWidth = CGFloat(sound.volume) * self.maxWidth
            }
        }
    }
    
    var maxHeight: CGFloat = 0 {
        didSet {
            withAnimation(.spring(duration: 1)) {
                self.sliderHeight = CGFloat(sound.volume) * self.maxHeight
            }
        }
    }
    
    private var player: AVAudioPlayer?
    private var fadeTask: Task<Void, Never>?
    
    private(set) var sound: Sound
    
    private var cancellables = Set<AnyCancellable>()
    
    init(sound: Sound) {
        self.sound = sound
        self.volume = sound.volume
        self.lastDragValue = CGFloat(sound.volume) * maxWidth
        self.selectedSoundVariant = sound.selectedSoundVariant
        
        setupSoundVariantObserver()
        // Defer audio loading to high priority queue for faster loading
        Task.detached(priority: .userInitiated) { [weak self] in
            await self?.prepareSound(fileName: sound.selectedSoundVariant.filename)
        }
    }
    
    deinit {
        fadeTask?.cancel()
    }
    
    // MARK: Public Methods
    
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
        lastDragValue = sliderWidth // For horizontal slider
    }
    
    func playSound(fadeDuration: Double? = nil) async {
        print("🎵 \(sound.name): playSound called with fade: \(fadeDuration ?? 0)")
        
        // Cancel any existing fade
        fadeTask?.cancel()
        
        guard let player = player else {
            print("❌ \(sound.name): No player available")
            return
        }
        
        if let fadeDuration = fadeDuration, fadeDuration > 0 {
            fadeTask = Task { [weak self] in
                guard let self = self else { return }
                
                // Start from 0 volume
                await self.updatePlayerVolume(0)
                
                if !player.isPlaying {
                    let success = player.play()
                    print("\(success ? "✅" : "❌") \(sound.name): Started playing with fade (success: \(success))")
                }
                
                let steps = Int(fadeDuration * 50) // 50 updates per second
                let volumeIncrement = self.sound.volume / Float(steps)
                
                for _ in 0..<steps {
                    guard !Task.isCancelled else { break }
                    
                    let currentVolume = await self.getPlayerVolume()
                    let newVolume = min(currentVolume + volumeIncrement, self.sound.volume)
                    await self.updatePlayerVolume(newVolume)
                    
                    try? await Task.sleep(nanoseconds: 20_000_000) // 20ms
                }
                
                // Ensure we reach the target volume
                if !Task.isCancelled {
                    await self.updatePlayerVolume(self.sound.volume)
                }
            }
        } else {
            await updatePlayerVolume(sound.volume)
            if !player.isPlaying {
                let success = player.play()
                print("\(success ? "✅" : "❌") \(sound.name): Started playing (success: \(success))")
            }
        }
    }
    
    func pauseSound(fadeDuration: Double? = nil) async {
        print("🎵 \(sound.name): pauseSound called with fade: \(fadeDuration ?? 0)")
        
        // Cancel any existing fade
        fadeTask?.cancel()
        
        guard let player = player else {
            print("❌ \(sound.name): No player to pause")
            return
        }
        
        if let fadeDuration = fadeDuration, fadeDuration > 0 {
            fadeTask = Task { [weak self] in
                guard let self = self else { return }
                
                let startVolume = await self.getPlayerVolume()
                let steps = Int(fadeDuration * 50) // 50 updates per second
                let volumeDecrement = startVolume / Float(steps)
                
                for _ in 0..<steps {
                    guard !Task.isCancelled else { break }
                    
                    let currentVolume = await self.getPlayerVolume()
                    let newVolume = max(currentVolume - volumeDecrement, 0)
                    await self.updatePlayerVolume(newVolume)
                    
                    if newVolume <= 0 {
                        break
                    }
                    
                    try? await Task.sleep(nanoseconds: 20_000_000) // 20ms
                }
                
                // Ensure volume is 0 and pause
                if !Task.isCancelled {
                    await self.updatePlayerVolume(0)
                    player.pause()
                    print("✅ \(self.sound.name): Paused with fade")
                }
            }
        } else {
            player.pause()
            print("✅ \(sound.name): Paused immediately")
        }
    }
    
    // MARK: Private Methods
    
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
        saveSound()
        
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
            guard let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") else {
                print("❌ Unable to find sound file \(fileName)")
                return
            }
            
            // Create player on high priority queue for faster loading
            let newPlayer = try await Task.detached(priority: .userInitiated) {
                let player = try AVAudioPlayer(contentsOf: url)
                // Prepare on background thread
                player.prepareToPlay()
                return player
            }.value
            
            await MainActor.run {
                newPlayer.numberOfLoops = -1
                newPlayer.volume = self.sound.volume
                self.player = newPlayer
            }
            
            let loadTime = CFAbsoluteTimeGetCurrent() - startTime
            if loadTime > 0.1 {
                print("⚠️ Slow audio load for \(fileName): \(String(format: "%.2f", loadTime))s")
            } else {
                print("✅ \(sound.name): Audio loaded successfully")
            }
        } catch {
            print("❌ \(sound.name): Error loading audio player: \(error)")
        }
    }
    
    private func updatePlayerVolume(_ volume: Float) async {
        player?.volume = volume
    }
    
    private func getPlayerVolume() async -> Float {
        return player?.volume ?? 0
    }
    
    private func saveSound() {
        Task.detached(priority: .background) { [sound] in
            do {
                let soundData = try JSONEncoder().encode(sound)
                UserDefaults.standard.set(soundData, forKey: String(sound.id))
            } catch {
                print("Failed to save sound: \(error)")
            }
        }
    }
}
