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
    
    @Published var volume: Double {
        didSet {
            player.volume = Float(volume)
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
        self.lastDragValue = sound.volume * maxWidth
        self.selectedSoundVariant = sound.selectedSoundVariant
        
        let cancellable = $selectedSoundVariant
            .dropFirst() // Skip the first value
            .sink { [weak self] selectedSoundVariant in
                guard let self else { return }
                
                self.sound.selectedSoundVariant = selectedSoundVariant
                self.saveSound()
                self.prepareSound(fileName: sound.selectedSoundVariant.filename)
            }
        cancellables.append(cancellable)
        
        prepareSound(fileName: sound.selectedSoundVariant.filename)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.bouncy) {
                self.sliderWidth = sound.volume * self.maxWidth
            }
        }
    }
    
    func playSound() {
        player.volume = Float(self.sound.volume)
        player.play()
    }
    
    func pauseSound(with fadeDuration: Double? = nil) {
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
