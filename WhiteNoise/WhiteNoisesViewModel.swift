//
//  WhiteNoisesViewModel.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 30.05.2023.
//

import Foundation
import AVFAudio
import Combine
import SwiftUI

final class WhiteNoisesViewModel: ObservableObject {

    // MARK: Properties

    @Published var soundsViewModels: [SoundViewModel] = []

    @Published var isPlaying: Bool = false {
        didSet {
            shouldAutoplayWhileStart = isPlaying
        }
    }
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
    
    @AppStorage("shouldAutoplayWhileStart") private var shouldAutoplayWhileStart: Bool = true
    
    private var audioEngine: AVAudioEngine = AVAudioEngine()
    private var timer: Timer?
    private var cancellables: [AnyCancellable] = []
    private var isFadeInProgress: Bool = false
    
    private let maxVolume: Float = 1.0
    
    // MARK: Init

    init() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Setting category to AVAudioSessionCategoryPlayback failed.")
        }

        soundsViewModels = SoundFactory.getSavedSounds().map { SoundViewModel(sound: $0) }

        setupAudio()
        
        soundsViewModels.forEach { soundViewModel in
            let volumeCancellable = soundViewModel.$volume
                .dropFirst()
                .sink { [weak self] volume in
                    guard let self else { return }
                    
                    if volume > 0 {
                        if self.isPlaying {
                            if soundViewModel.isPlaying == false {
                                soundViewModel.startRepeatingPlayback()
                            }
                        } else {
                            self.playSounds(fadeDuration: 1)
                        }
                    } else {
                        soundViewModel.pause()
                    }
                }
            cancellables.append(volumeCancellable)
        }
    }

    // MARK: Methods
    
    func playingButtonSelected() {
        if isPlaying {
            shouldAutoplayWhileStart = true
            pauseSounds(fadeDuration: 0.5)
        } else {
            shouldAutoplayWhileStart = false
            playSounds(fadeDuration: 1)
        }
    }
    
    func handleAutoStart() {
        if shouldAutoplayWhileStart {
            playSounds(fadeDuration: 5)
        }
    }

}

// MARK: - Helpers

private extension WhiteNoisesViewModel {

    func setupAudio() {
        // Load your audio files
        soundsViewModels
            .forEach { soundViewModel in
                guard let processingFormat = soundViewModel.processingFormat else { return }
                
                audioEngine.attach(soundViewModel.playerNode)
                audioEngine.connect(
                    soundViewModel.playerNode,
                    to: audioEngine.mainMixerNode,
                    format: processingFormat
                )
            }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("Error starting audio engine: \(error)")
        }
    }
    
    func playSounds(fadeDuration: TimeInterval) {
        soundsViewModels
            .forEach { soundViewModel in
                guard soundViewModel.volume > 0 else { return }
                
                soundViewModel.startRepeatingPlayback()
            }
        
        let fadeInStep: Float = maxVolume / Float(fadeDuration * 10) // Adjust step for smoother fading
        var currentVolume: Float = 0.0

        isFadeInProgress = true
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            
            if currentVolume < self.maxVolume {
                currentVolume += fadeInStep
                self.audioEngine.mainMixerNode.outputVolume = currentVolume
            } else {
                self.audioEngine.mainMixerNode.outputVolume = 1.0
                timer.invalidate()
                isFadeInProgress = false
            }
        }
        
        isPlaying = true
    }

    func pauseSounds(fadeDuration: Double) {
        let fadeInStep: Float = maxVolume / Float(fadeDuration * 10) // Adjust step for smoother fading
        var currentVolume: Float = maxVolume

        isFadeInProgress = true
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            
            if currentVolume > 0 {
                currentVolume -= fadeInStep
                self.audioEngine.mainMixerNode.outputVolume = currentVolume
            } else {
                self.audioEngine.mainMixerNode.outputVolume = 0
                timer.invalidate()
                isFadeInProgress = false
            }
        }
        
        soundsViewModels
            .forEach { soundViewModel in
                soundViewModel.pause()
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
