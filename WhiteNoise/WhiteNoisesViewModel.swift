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
    @Published var timerMode: TimerMode = .off {
        didSet {
            switch timerMode {
            case .off:
                timerRemainingSeconds = 0
                timer?.invalidate()
            default:
                timerRemainingSeconds = timerMode.minutes * 60
                setRemainingTimerTime(with: timerRemainingSeconds)
                playSounds(fadeDuration: 1)
            }
        }
    }

    @Published var remainingTimerTime: String = ""
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
        }
    }

    // MARK: Methods
    
    func playingButtonSelected() {
        if isPlaying {
            pauseSounds(fadeDuration: 0.5)
        } else {
            playSounds(fadeDuration: 1)
        }
    }

}

private extension WhiteNoisesViewModel {

    private func playSounds(fadeDuration: Double? = nil) {
        if timerMode != .off {
            restartTimer()
        }

        for soundViewModel in soundsViewModels where soundViewModel.volume > 0 {
            soundViewModel.playSound(fadeDuration: fadeDuration)
        }
        isPlaying = true
    }

    private func pauseSounds(fadeDuration: Double? = nil) {
        timer?.invalidate()
        timer = nil

        for soundViewModel in soundsViewModels where soundViewModel.volume > 0 {
            soundViewModel.pauseSound(fadeDuration: fadeDuration)
        }
        isPlaying = false
    }
    
    func restartTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self else { return }

            if self.timerRemainingSeconds > 0 {
                self.timerRemainingSeconds -= 1
                self.setRemainingTimerTime(with: self.timerRemainingSeconds)
            } else {
                self.pauseSounds(fadeDuration: 5)
                self.timerMode = .off
            }
        }
    }
    
    func setRemainingTimerTime(with seconds: Int) {
        let minutes = Int(self.timerRemainingSeconds) / 60 % 60
        let seconds = Int(self.timerRemainingSeconds) % 60
        remainingTimerTime = String(format:"%02i:%02i", minutes, seconds)
    }

}
