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
            sound.volume = volume
            saveSound()
        }
    }
    @Published var selectedSoundVariant: Sound.SoundVariant
    @Published var sliderWidth: CGFloat = 0.0
    @Published var lastDragValue: CGFloat = 0.0
    
    var isPlaying: Bool {
        playerNode.isPlaying
    }
    
    var processingFormat: AVAudioFormat? {
        audioFile?.processingFormat
    }
    
    var maxWidth: CGFloat = 0 {
        didSet {
            withAnimation(.smooth(duration: 5)) {
                self.sliderWidth = CGFloat(sound.volume) * self.maxWidth
            }
        }
    }
    
    private(set) var playerNode: AVAudioPlayerNode = AVAudioPlayerNode()
    private var audioFile: AVAudioFile?
    
    private var fadeTimer: Timer?
    
    private(set) var sound: Sound
    
    private var cancellables: [AnyCancellable] = []
    
    init(sound: Sound) {
        self.sound = sound
        
        self.volume = sound.volume
        self.lastDragValue = CGFloat(sound.volume) * maxWidth
        self.selectedSoundVariant = sound.selectedSoundVariant
            
        let cancellable = $selectedSoundVariant
            .dropFirst() // Skip the first value
            .sink { [weak self] selectedSoundVariant in
                guard let self else { return }
                
                self.playerNode.stop()
                self.sound.selectedSoundVariant = selectedSoundVariant
                self.saveSound()
               
                self.prepareSound(fileName: selectedSoundVariant.filename)
                if self.volume > 0 {
                    self.startRepeatingPlayback()
                }
            }
        
        cancellables.append(cancellable)
        
        prepareSound(fileName: sound.selectedSoundVariant.filename)
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
 
    func startRepeatingPlayback() {
        guard let audioFile = audioFile else { return }
        
        playerNode.scheduleFile(audioFile, at: nil) { [weak self] in
            // This completion handler is called when playback finishes
            self?.startRepeatingPlayback() // Reschedule the file to create a loop
        }
        playerNode.play()
    }
    
    func pause() {
        playerNode.pause()
    }
}

private extension SoundViewModel {
    
    func prepareSound(fileName: String) {
        do {
            guard let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") else {
                print("Unable to find sound file \(fileName)")
                return
            }
            
            audioFile = try AVAudioFile(forReading: url)
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
