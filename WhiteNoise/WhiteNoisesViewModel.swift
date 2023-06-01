//
//  WhiteNoisesViewModel.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 30.05.2023.
//

import Foundation
import AVFAudio
import Combine

class WhiteNoisesViewModel: ObservableObject {

    // MARK: Properties

    @Published var soundsViewModels: [SoundViewModel] = [
        SoundViewModel(sound: Sound(name: "Birds", fileName: "birds"), volume: 0.3, isActive: true),
        SoundViewModel(sound: Sound(name: "Whitenoise", fileName: "whitenoise"), volume: 0.3, isActive: false),
        SoundViewModel(sound: Sound(name: "Jungle", fileName: "jungle"), volume: 0.3, isActive: false),
        SoundViewModel(sound: Sound(name: "Sea", fileName: "sea"), volume: 0.3, isActive: false),
        SoundViewModel(sound: Sound(name: "Wind", fileName: "wind"), volume: 0.3, isActive: false),
        SoundViewModel(sound: Sound(name: "Windstorm", fileName: "windstorm"), volume: 0.3, isActive: false)
    ]

    @Published var isPlaying: Bool

    @Published var selectedMinutes = 0
    @Published var timerRemainingSeconds: Int = 0

    private var timer: Timer?
    private var cancellables: [AnyCancellable] = []

    // MARK: Init

    init() {
        self.isPlaying = false

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Setting category to AVAudioSessionCategoryPlayback failed.")
        }

        soundsViewModels.forEach { soundViewModel in
            let cancellable = soundViewModel.$isActive
                .dropFirst()
                .sink { isActive in
                    if isActive {
                        soundViewModel.playSound()
                    } else {
                        soundViewModel.pauseSound()
                    }
                }
            cancellables.append(cancellable)
        }

        let cancellable = $selectedMinutes.dropFirst().sink { [weak self] selectedMinutes in
            self?.timerRemainingSeconds = selectedMinutes * 60
        }
        cancellables.append(cancellable)
    }

    // MARK: Methods

    func playSounds() {
        if selectedMinutes > 0 {
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
                guard let self else { return }

                if self.timerRemainingSeconds > 0 {
                    self.timerRemainingSeconds -= 1
                } else {
                    timer.invalidate()
                    self.pauseSounds()
                }
            }
        }

        for soundViewModel in soundsViewModels where soundViewModel.isActive {
            soundViewModel.playSound()
        }

        self.isPlaying = true
    }

    func pauseSounds() {
        timer?.invalidate()
        timer = nil

        for soundViewModel in soundsViewModels where soundViewModel.isActive {
            soundViewModel.pauseSound()
        }
        self.isPlaying = false
    }

}
