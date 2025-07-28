//
//  WhiteNoisesViewModel.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 30.05.2023.
//

import Foundation
import AVFAudio
import Combine

@MainActor
class WhiteNoisesViewModel: ObservableObject {

    enum TimerMode: CaseIterable, Identifiable {

        var id: Self { self }

        case off, oneMinute, twoMinutes, threeMinutes, fiveMinutes, tenMinutes, fifteenMinutes, thirtyMinutes, sixtyMinutes, twoHours, threeHours, fourHours, fiveHours, sixHours, sevenHours, eightHours

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
            case .twoHours:
                return 120
            case .threeHours:
                return 180
            case .fourHours:
                return 240
            case .fiveHours:
                return 300
            case .sixHours:
                return 360
            case .sevenHours:
                return 420
            case .eightHours:
                return 480
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
            case .twoHours:
                return "in 2 hours"
            case .threeHours:
                return "in 3 hours"
            case .fourHours:
                return "in 4 hours"
            case .fiveHours:
                return "in 5 hours"
            case .sixHours:
                return "in 6 hours"
            case .sevenHours:
                return "in 7 hours"
            case .eightHours:
                return "in 8 hours"
            }
        }
    }

    // MARK: Properties

    @Published var soundsViewModels: [SoundViewModel] = []
    @Published var isPlaying: Bool = false
    @Published var timerMode: TimerMode = .off
    @Published var remainingTimerTime: String = ""
    
    private var timerRemainingSeconds: Int = 0
    private var timerTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    // MARK: Init

    init() {
        setupAudioSession()
        setupSoundViewModels()
        setupTimerModeObserver()
    }
    
    deinit {
        timerTask?.cancel()
    }

    // MARK: Public Methods
    
    func playingButtonSelected() {
        Task {
            if isPlaying {
                await pauseSounds(fadeDuration: 0.5)
            } else {
                await playSounds(fadeDuration: 1.0)
            }
        }
    }

    // MARK: Private Methods
    
    private func setupAudioSession() {
        #if os(iOS)
        Task { @MainActor in
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print("Failed to set audio session: \(error)")
            }
        }
        #endif
    }
    
    private func setupSoundViewModels() {
        soundsViewModels = SoundFactory.getSavedSounds().map { SoundViewModel(sound: $0) }
        
        // Observe volume changes
        soundsViewModels.forEach { soundViewModel in
            soundViewModel.$volume
                .dropFirst()
                .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
                .sink { [weak self] volume in
                    Task { [weak self] in
                        await self?.handleVolumeChange(for: soundViewModel, volume: volume)
                    }
                }
                .store(in: &cancellables)
        }
    }
    
    private func setupTimerModeObserver() {
        $timerMode
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] newMode in
                Task { [weak self] in
                    await self?.handleTimerModeChange(newMode)
                }
            }
            .store(in: &cancellables)
    }
    
    private func handleVolumeChange(for soundViewModel: SoundViewModel, volume: Float) async {
        if volume > 0 {
            if isPlaying {
                await soundViewModel.playSound()
            } else {
                await playSounds()
            }
        } else {
            await soundViewModel.pauseSound()
        }
    }
    
    private func handleTimerModeChange(_ newMode: TimerMode) async {
        // Cancel any existing timer
        timerTask?.cancel()
        timerTask = nil
        
        switch newMode {
        case .off:
            timerRemainingSeconds = 0
            remainingTimerTime = ""
        default:
            timerRemainingSeconds = newMode.minutes * 60
            updateRemainingTimeDisplay()
            
            // Only start playing if not already playing
            if !isPlaying {
                await playSounds(fadeDuration: 1.0)
            }
            
            // Always start the timer when a time is selected
            startTimer()
        }
    }
    
    private func startTimer() {
        timerTask?.cancel()
        
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                
                guard let self = self else { break }
                
                if self.timerRemainingSeconds > 0 {
                    self.timerRemainingSeconds -= 1
                    self.updateRemainingTimeDisplay()
                } else {
                    await self.pauseSounds(fadeDuration: 5.0)
                    self.timerMode = .off
                    break
                }
            }
        }
    }
    
    private func updateRemainingTimeDisplay() {
        let hours = timerRemainingSeconds / 3600
        let minutes = (timerRemainingSeconds % 3600) / 60
        let seconds = timerRemainingSeconds % 60
        
        if hours > 0 {
            remainingTimerTime = String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            remainingTimerTime = String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    private func playSounds(fadeDuration: Double? = nil) async {
        // Start timer if needed
        if timerMode != .off && timerTask == nil {
            startTimer()
        }
        
        // Play all sounds with volume > 0
        await withTaskGroup(of: Void.self) { group in
            for soundViewModel in soundsViewModels where soundViewModel.volume > 0 {
                group.addTask { [weak soundViewModel] in
                    await soundViewModel?.playSound(fadeDuration: fadeDuration)
                }
            }
        }
        
        isPlaying = true
    }
    
    private func pauseSounds(fadeDuration: Double? = nil) async {
        // Stop timer
        timerTask?.cancel()
        timerTask = nil
        
        // Pause all sounds
        await withTaskGroup(of: Void.self) { group in
            for soundViewModel in soundsViewModels where soundViewModel.volume > 0 {
                group.addTask { [weak soundViewModel] in
                    await soundViewModel?.pauseSound(fadeDuration: fadeDuration)
                }
            }
        }
        
        isPlaying = false
    }
}
