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

class SoundViewModel: ObservableObject, Identifiable {
    
    @Published var volume: Float {
        didSet {
            player.volume = volume
            sound.volume = volume
            saveSound()
        }
    }
    @Published var selectedSoundVariant: Sound.SoundVariant
    @Published var sliderWidth: CGFloat = 0.0
    @Published var lastDragValue: CGFloat = 0.0
    
    let maxWidth: CGFloat = 180
    
    private var player: AVAudioPlayer = AVAudioPlayer()
    private var fadeTimer: Timer?
    
    private(set) var sound: Sound
    
    private var cancellables: [AnyCancellable] = []
    
    init(sound: Sound) {
        self.sound = sound
        
        self.volume = sound.volume
        self.sliderWidth = 0
        self.lastDragValue = CGFloat(sound.volume) * maxWidth
        self.selectedSoundVariant = sound.selectedSoundVariant
        
        let cancellable = $selectedSoundVariant
            .dropFirst() // Skip the first value
            .sink { [weak self] selectedSoundVariant in
                guard let self else { return }
                
                self.sound.selectedSoundVariant = selectedSoundVariant
                self.saveSound()
                let wasPlaying = player.isPlaying
                if wasPlaying {
                    self.player.stop()
                }
                self.prepareSound(fileName: selectedSoundVariant.filename)
                if wasPlaying {
                    self.playSound()
                }
            }
        cancellables.append(cancellable)
        
        prepareSound(fileName: sound.selectedSoundVariant.filename)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring()) {
                self.sliderWidth = CGFloat(sound.volume) * self.maxWidth
            }
        }
    }
    
    func dragDidChange(newTranslationWidth: CGFloat) {
        sliderWidth = newTranslationWidth + lastDragValue
        
        sliderWidth = sliderWidth > maxWidth ? maxWidth : sliderWidth
        sliderWidth = sliderWidth >= 0 ? sliderWidth : 0
        
        let progress = sliderWidth / maxWidth
        volume = Float(progress) <= 1.0 ? Float(progress) : Float(1.0)
    }
    
    func dragDidEnded() {
        sliderWidth = sliderWidth > maxWidth ? maxWidth : sliderWidth
        sliderWidth = sliderWidth >= 0 ? sliderWidth : 0
        
        lastDragValue = sliderWidth
    }
    
    func playSound(fadeDuration: Double? = nil) {
        if let fadeDuration = fadeDuration {
            player.volume = 0
            fadeTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { [weak self] timer in
                guard let self else { return }
                
                self.player.volume += Float(0.02 / fadeDuration)
                if self.player.volume >= sound.volume {
                    self.fadeTimer?.invalidate()
                }
            }
            player.play()
        } else {
            player.volume = Float(sound.volume)
            player.play()
        }
    }
    
    func pauseSound(fadeDuration: Double? = nil) {
        if let fadeDuration = fadeDuration {
            fadeTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { [weak self] timer in
                guard let self else { return }
                // decrease volume
                self.player.volume -= Float(0.02 / fadeDuration)
                
                // stop timer and player when volume is 0
                if self.player.volume <= 0 {
                    self.fadeTimer?.invalidate()
                    self.player.pause()
                }
            }
        } else {
            player.pause()
        }
    }
}

private extension SoundViewModel {
    
    func prepareSound(fileName: String) {
        do {
            guard let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") else {
                print("Unable to find sound file \(fileName)")
                return
            }
            
            player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.numberOfLoops = -1
            player.volume = Float(self.sound.volume)
        } catch {
            print("Error loading audio player: \(error)")
        }
    }
    
    func saveSound() {
        do {
            let soundData = try JSONEncoder().encode(sound)
            UserDefaults.standard.set(soundData, forKey: String(sound.id))
            UserDefaults.standard.synchronize()
        } catch {
            print("Failed to save sound: \(error)")
        }
    }
    
}
