//
//  SoundViewModel.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 31.05.2023.
//

import Foundation
import AVFoundation
import Combine

class SoundViewModel: ObservableObject, Identifiable {
    
    @Published var isActive: Bool {
        didSet {
            sound.isActive = isActive
            saveSound()
        }
    }
    @Published var volume: Double {
        didSet {
            player?.volume = Float(volume)
            sound.volume = volume
            saveSound()
        }
    }
    @Published var selectedSoundVariant: Sound.SoundVariant
    
    private var player: AVAudioPlayer? = AVAudioPlayer()
    private var fadeTimer: Timer?
    
    private(set) var sound: Sound
    
    private var cancellables: [AnyCancellable] = []
    
    init(sound: Sound) {
        self.sound = sound
        
        self.isActive = sound.isActive
        self.volume = sound.volume
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
        
        prepareSound(fileName: self.sound.selectedSoundVariant.filename)
    }
    
    func playSound() {
        player?.play()
    }
    
    func pauseSound(with fadeDuration: Double? = nil) {
        if let fadeDuration = fadeDuration {
            fadeTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { [weak self] timer in
                // decrease volume
                self?.player?.volume -= Float(0.02 / fadeDuration)
                
                // stop timer and player when volume is 0
                if self?.player?.volume ?? 0 <= 0 {
                    self?.fadeTimer?.invalidate()
                    self?.player?.pause()
                }
            }
        } else {
            player?.pause()
        }
    }
}

private extension SoundViewModel {
    
    func prepareSound(fileName: String) {
        do {
            guard let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") else {
                print("Unable to find sound file")
                return
            }
            
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.numberOfLoops = -1
            player?.volume = Float(self.sound.volume)
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
