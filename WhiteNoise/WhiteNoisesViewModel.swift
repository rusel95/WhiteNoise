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

        case off, oneMinute, twoMinutes, threeMinutes, fiveMinutes, tenMinutes, fifteenMinutes, thirtyMinutes, sixtyMinutes

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
            case .fifteenMinutes:
                return 15
            case .thirtyMinutes:
                return 30
            case .sixtyMinutes:
                return 60
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
            case .fifteenMinutes:
                return "in 15 minutes"
            case .thirtyMinutes:
                return "in 30 minutes"
            case .sixtyMinutes:
                return "in 60 minutes"
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

#if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Setting category to AVAudioSessionCategoryPlayback failed.")
        }
#endif

        soundsViewModels = SoundFactory.getSavedSounds().map { SoundViewModel(sound: $0) }

        soundsViewModels.forEach { soundViewModel in
            let volumeCancellable = soundViewModel.$volume
                .dropFirst()
                .sink { [weak self] volume in
                    guard let self else { return }
                    
                    if volume > 0 {
                        if self.isPlaying {
                            soundViewModel.playSound()
                        } else if self.isPlaying == false {
                            self.playSounds()
                        }
                    } else {
                        soundViewModel.pauseSound()
                    }
                }
            cancellables.append(volumeCancellable)
            
            let selectedSoundVariantCancellable = soundViewModel.$selectedSoundVariant
                .dropFirst() // Skip the first value
                .sink { [weak self] _ in
                    guard let self else { return }
                    
                    if self.isPlaying {
                        self.playSounds()
                    }
                }
            cancellables.append(selectedSoundVariantCancellable)
        }

        let cancellable = $timerMode.sink { [weak self] timerMode in
            switch timerMode {
            case .off:
                self?.timerRemainingSeconds = 0
                self?.timer?.invalidate()
            default:
                self?.timerRemainingSeconds = timerMode.minutes * 60
                self?.restartTimer()
            }
        }
        cancellables.append(cancellable)
    }

    // MARK: Methods

    func playSounds() {
        if timerMode != .off {
            restartTimer()
        }

        for soundViewModel in soundsViewModels where soundViewModel.volume > 0 {
            soundViewModel.playSound()
        }
        DispatchQueue.main.async {
            self.isPlaying = true
        }
    }

    func pauseSounds(with fadeDuration: Double? = nil) {
        timer?.invalidate()
        timer = nil

        for soundViewModel in soundsViewModels where soundViewModel.volume > 0 {
            soundViewModel.pauseSound(with: fadeDuration)
        }
        DispatchQueue.main.async {
            self.isPlaying = false
        }
    }

}

private extension WhiteNoisesViewModel {

    func restartTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self else { return }

            if self.timerRemainingSeconds > 0 {
                self.timerRemainingSeconds -= 1
            } else {
                pauseSounds(with: 5)
                self.timerRemainingSeconds = timerMode.minutes * 60
            }
        }
    }

}
