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

    enum TimerMode: CaseIterable, Identifiable {

        var id: Self { self }

        case off, oneMinute, twoMinutes, threeMinutes, fiveMinutes, tenMinutes

        var minutes: Int {
            switch self {
            case .off:
                return 0
            case .oneMinute:
                return 1
            case .twoMinutes:
                return 2
            case .threeMinutes:
                return 3
            case .fiveMinutes:
                return 5
            case .tenMinutes:
                return 10
            }
        }

        var description: String {
            switch self {
            case .off:
                return "off"
            case .oneMinute:
                return "in 1 minute"
            case .twoMinutes:
                return "in 2 minutes"
            case .threeMinutes:
                return "in 3 minutes"
            case .fiveMinutes:
                return "in 5 minutes"
            case .tenMinutes:
                return "in 10 minutes"
            }
        }
    }

    // MARK: Properties

    @Published var soundsViewModels: [SoundViewModel] = []

    @Published var isPlaying: Bool
    @Published var timerMode: TimerMode = .off

    @Published private var timerRemainingSeconds: Int = 0

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

        soundsViewModels = SoundFactory.getSavedSounds().map { SoundViewModel(sound: $0) }

        soundsViewModels.forEach { soundViewModel in
            let cancellable = soundViewModel.$isActive
                .dropFirst()
                .sink { [weak self] isActive in
                    if isActive {
                        if self?.isPlaying ?? false {
                            soundViewModel.playSound()
                        }
                    } else {
                        soundViewModel.pauseSound()
                    }
                }
            cancellables.append(cancellable)
        }

        let cancellable = $timerMode.sink { [weak self] timerMode in
            self?.timerRemainingSeconds = timerMode.minutes * 60
        }
        cancellables.append(cancellable)
    }

    // MARK: Methods

    func playSounds() {
        if timerMode != .off {
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
                guard let self else { return }

                if self.timerRemainingSeconds > 0 {
                    self.timerRemainingSeconds -= 1
                } else {
                    timer.invalidate()
                    self.pauseSounds(with: 5)
                }
            }
        }

        for soundViewModel in soundsViewModels where soundViewModel.isActive {
            soundViewModel.playSound()
        }

        self.isPlaying = true
    }

    func pauseSounds(with fadeDuration: Double? = nil) {
        timer?.invalidate()
        timer = nil

        for soundViewModel in soundsViewModels where soundViewModel.isActive {
            soundViewModel.pauseSound(with: fadeDuration)
        }
        self.isPlaying = false
    }

}
