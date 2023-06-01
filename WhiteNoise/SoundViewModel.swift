//
//  SoundViewModel.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 31.05.2023.
//

import Foundation
import AVFoundation

class SoundViewModel: ObservableObject, Identifiable {

    @Published var sound: Sound
    @Published var volume: Double
    @Published var isActive: Bool

    private var player: AVAudioPlayer?

    init(sound: Sound, volume: Double, isActive: Bool) {
        self.sound = sound
        self.volume = volume
        self.isActive = isActive
        
        do {
            guard let url = Bundle.main.url(forResource: sound.fileName, withExtension: "mp3") else {
                print("Unable to find sound file")
                return
            }
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.numberOfLoops = -1
            player?.volume = Float(self.volume)
        } catch {
            print("Error loading audio player: \(error)")
        }
    }

    func adjustVolume(to volume: Double) {
        self.volume = volume
        player?.volume = Float(volume)
    }

    func playSound() {
        player?.play()
    }

    func pauseSound() {
        player?.pause()
    }
}
