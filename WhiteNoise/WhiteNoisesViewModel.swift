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

    @Published var soundsViewModels: [SoundViewModel] = [
        SoundViewModel(
            sound: Sound(
                name: "Rain falling in forest with occasional birds",
                fileName: "Rain falling in forest with occasional birds"
            ),
            volume: 0.3,
            isActive: true
        ),
        SoundViewModel(
            sound: Sound(
                name: "Medium light constant rain with a rumble of thunder",
                fileName: "Medium light constant rain with a rumble of thunder"
            ),
            volume: 0.3,
            isActive: false
        ),
        SoundViewModel(
            sound: Sound(
                name: "Medium heavy constant rain with some thunder rumbles",
                fileName: "Medium heavy constant rain with some thunder rumbles"
            ),
            volume: 0.3,
            isActive: false
        ),
        SoundViewModel(
            sound: Sound(
                name: "Medium heavy constant rain with drips",
                fileName: "Medium heavy constant rain with drips"
            ),
            volume: 0.3,
            isActive: false
        ),
        SoundViewModel(
            sound: Sound(
                name: "Springtime rain and thunder and lightning",
                fileName: "Springtime rain and thunder and lightning"
            ),
            volume: 0.3,
            isActive: false
        ),
        SoundViewModel(
            sound: Sound(
                name: "Gentle ocean waves on sandy beach, distant surf, low tide, winter",
                fileName: "Gentle ocean waves on sandy beach, distant surf, low tide, winter"
            ),
            volume: 0.3,
            isActive: false
        ),
        SoundViewModel(
            sound: Sound(
                name: "Mediterranean sea, calm ocean waves splashing on rocks pebbles and sand",
                fileName: "Mediterranean sea, calm ocean waves splashing on rocks pebbles and sand"
            ),
            volume: 0.3,
            isActive: false
        ),
        SoundViewModel(
            sound: Sound(
                name: "Small cascading waterfall, water trickle between rocks",
                fileName: "Small cascading waterfall, water trickle between rocks"
            ),
            volume: 0.3,
            isActive: false
        ),
        SoundViewModel(
            sound: Sound(
                name: "River or stream, water flowing, running",
                fileName: "River or stream, water flowing, running"
            ),
            volume: 0.3,
            isActive: false
        ),
        SoundViewModel(
            sound: Sound(
                name: "River, French Alps, Binaural, Close perspective, Water, Flow, Mountain, Forest",
                fileName: "River, French Alps, Binaural, Close perspective, Water, Flow, Mountain, Forest"
            ),
            volume: 0.3,
            isActive: false
        ),
        SoundViewModel(
            sound: Sound(
                name: "Summer forest loop, insects, birds",
                fileName: "Summer forest loop, insects, birds"
            ),
            volume: 0.3,
            isActive: false
        ),
        SoundViewModel(
            sound: Sound(
                name: "Designed forest, woodland ambience loop, several birds including the American goldfinch",
                fileName: "Designed forest, woodland ambience loop, several birds including the American goldfinch"
            ),
            volume: 0.3,
            isActive: false
        )
    ]

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
