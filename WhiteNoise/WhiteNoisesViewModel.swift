//
//  WhiteNoisesViewModel.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 30.05.2023.
//

import Foundation
import AVFAudio

class WhiteNoisesViewModel: ObservableObject {

    @Published var soundsViewModels: [SoundViewModel] = [
        SoundViewModel(sound: Sound(name: "Birds", fileName: "birds"), volume: 0.3, isActive: true),
        SoundViewModel(sound: Sound(name: "Whitenoise", fileName: "whitenoise"), volume: 0.3, isActive: false),
        SoundViewModel(sound: Sound(name: "Jungle", fileName: "jungle"), volume: 0.3, isActive: false),
        SoundViewModel(sound: Sound(name: "Sea", fileName: "sea"), volume: 0.3, isActive: false),
        SoundViewModel(sound: Sound(name: "Wind", fileName: "wind"), volume: 0.3, isActive: false),
        SoundViewModel(sound: Sound(name: "Windstorm", fileName: "windstorm"), volume: 0.3, isActive: false)
    ]

    @Published var isPlaying: Bool

    // Initialize your sounds
    init() {
        self.isPlaying = false

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Setting category to AVAudioSessionCategoryPlayback failed.")
        }
    }

    func startTimer() {
        // Add your timer logic here
        // For example, you can use Timer.scheduledTimer to start a timer and stop the sounds when the timer expires
    }

    func playSounds() {
        // Go through each sound, and if it is active, create an AVAudioPlayer for it and play it
        for soundViewModel in soundsViewModels where soundViewModel.isActive {
            soundViewModel.playSound()
        }
        self.isPlaying = true
    }

    func stopSounds() {
        // Stop all sounds by going through each AVAudioPlayer and calling its stop method
        // Go through each sound, and if it is active, create an AVAudioPlayer for it and play it
        for soundViewModel in soundsViewModels where soundViewModel.isActive {
            soundViewModel.stopSound()
        }
        self.isPlaying = false
    }

}
