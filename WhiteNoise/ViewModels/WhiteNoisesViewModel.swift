//
//  WhiteNoisesViewModel.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 30.05.2023.
//

import Foundation
import AVFAudio
import Combine
import MediaPlayer

@MainActor
class WhiteNoisesViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var soundsViewModels: [SoundViewModel] = []
    @Published var isPlaying: Bool = false
    
    var timerMode: TimerService.TimerMode {
        get { timerService.mode }
        set { handleTimerModeChange(newValue) }
    }
    
    var remainingTimerTime: String {
        timerService.remainingTime
    }
    
    // MARK: - Services
    private let audioSessionService = AudioSessionService()
    private let timerService = TimerService()
    private let remoteCommandService = RemoteCommandService()
    private let soundFactory: SoundFactoryProtocol
    
    // MARK: - Private Properties
    private static var activeInstance: WhiteNoisesViewModel?
    private var cancellables = Set<AnyCancellable>()
    private var wasPlayingBeforeInterruption = false
    private var appLifecycleObservers: [NSObjectProtocol] = []

    // MARK: - Initialization
    init(soundFactory: SoundFactoryProtocol = SoundFactory()) {
        print("🎵 WhiteNoisesViewModel: Initializing")
        self.soundFactory = soundFactory
        
        cleanupPreviousInstance()
        Self.activeInstance = self
        
        setupServices()
        setupObservers()
        loadSounds()
        
        registerForCleanup()
    }
    
    deinit {
        print("🎵 WhiteNoisesViewModel: Deinitializing")
        Task { @MainActor in
            timerService.stop()
        }
        
        appLifecycleObservers.forEach {
            NotificationCenter.default.removeObserver($0)
        }
        appLifecycleObservers.removeAll()
    }

    // MARK: - Public Methods
    func playingButtonSelected() {
        print("🎵 Playing button selected - current state: \(isPlaying)")
        Task {
            do {
                if isPlaying {
                    await pauseSounds(fadeDuration: AppConstants.Animation.fadeStandard)
                } else {
                    try await audioSessionService.ensureActive()
                    await playSounds(fadeDuration: AppConstants.Animation.fadeStandard)
                }
            } catch {
                // TODO: Add error tracking when available
                print("❌ Failed to toggle playback: \(error)")
            }
        }
    }

    // MARK: - Private Setup Methods
    private func cleanupPreviousInstance() {
        if let previousInstance = Self.activeInstance {
            print("⚠️ Cleaning up previous WhiteNoisesViewModel instance")
            previousInstance.timerService.stop()
            previousInstance.appLifecycleObservers.forEach {
                NotificationCenter.default.removeObserver($0)
            }
            previousInstance.appLifecycleObservers.removeAll()
        }
    }
    
    private func setupServices() {
        // Timer service callbacks
        timerService.onTimerExpired = { [weak self] in
            await self?.pauseSounds(fadeDuration: AppConstants.Animation.fadeOut)
        }
        
        timerService.onTimerTick = { [weak self] remainingSeconds in
            // Update Now Playing info periodically
            if remainingSeconds % AppConstants.Timer.nowPlayingUpdateInterval == 0 {
                self?.updateNowPlayingInfo()
            }
        }
        
        // Remote command callbacks
        remoteCommandService.onPlayCommand = { [weak self] in
            guard let self = self, !self.isPlaying else { return }
            await self.playSounds(fadeDuration: AppConstants.Animation.fadeLong)
        }
        
        remoteCommandService.onPauseCommand = { [weak self] in
            guard let self = self, self.isPlaying else { return }
            await self.pauseSounds(fadeDuration: AppConstants.Animation.fadeLong)
        }
        
        remoteCommandService.onToggleCommand = { [weak self] in
            self?.playingButtonSelected()
        }
    }
    
    private func setupObservers() {
        // Audio session interruption
        audioSessionService.$isInterrupted
            .sink { [weak self] isInterrupted in
                Task { @MainActor [weak self] in
                    await self?.handleAudioInterruption(isInterrupted)
                }
            }
            .store(in: &cancellables)
        
        setupAppLifecycleObservers()
    }
    
    private func loadSounds() {
        Task {
            await setupSoundViewModels()
        }
    }
    
    private func registerForCleanup() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                if let self = self, Self.activeInstance === self {
                    Self.activeInstance = nil
                }
            }
        }
    }
    
    private func setupSoundViewModels() async {
        let sounds = await soundFactory.getSavedSoundsAsync()
        soundsViewModels = []
        
        for (index, sound) in sounds.enumerated() {
            let soundViewModel = SoundViewModel(sound: sound)
            soundsViewModels.append(soundViewModel)
            
            // Observe volume changes
            soundViewModel.$volume
                .dropFirst()
                .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
                .sink { [weak self] volume in
                    Task { [weak self] in
                        await self?.handleVolumeChange(for: soundViewModel, volume: volume)
                    }
                }
                .store(in: &cancellables)
            
            // Yield periodically for better performance
            if index % 3 == 2 {
                await Task.yield()
            }
        }
    }
    
    private func setupAppLifecycleObservers() {
        #if os(iOS)
        let activeObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("🎵 App did become active")
            Task { [weak self] in
                await self?.handleAppDidBecomeActive()
            }
        }
        appLifecycleObservers.append(activeObserver)
        
        let backgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("🎵 App did enter background")
        }
        appLifecycleObservers.append(backgroundObserver)
        
        let foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("🎵 App will enter foreground")
            Task { [weak self] in
                await self?.audioSessionService.reconfigure()
            }
        }
        appLifecycleObservers.append(foregroundObserver)
        #endif
    }

    // MARK: - Playback Methods
    private func playSounds(fadeDuration: Double? = nil) async {
        print("🎵 Playing sounds with fade duration: \(fadeDuration ?? 0)")
        
        // Start timer if needed
        if timerService.mode != .off && !timerService.isActive {
            timerService.start(mode: timerService.mode)
        }
        
        // Play all sounds with volume > 0
        let soundsToPlay = soundsViewModels.filter { $0.volume > 0 }
        print("🎵 Playing \(soundsToPlay.count) sounds")
        
        await withTaskGroup(of: Void.self) { group in
            for soundViewModel in soundsToPlay {
                group.addTask { [weak soundViewModel] in
                    await soundViewModel?.playSound(fadeDuration: fadeDuration)
                }
            }
        }
        
        isPlaying = true
        updateNowPlayingInfo()
        print("✅ All sounds started playing")
    }
    
    private func pauseSounds(fadeDuration: Double? = nil) async {
        print("🎵 Pausing sounds with fade duration: \(fadeDuration ?? 0)")
        
        // Stop timer
        timerService.stop()
        
        // Pause all sounds
        let soundsToPause = soundsViewModels.filter { $0.volume > 0 }
        print("🎵 Pausing \(soundsToPause.count) sounds")
        
        await withTaskGroup(of: Void.self) { group in
            for soundViewModel in soundsToPause {
                group.addTask { [weak soundViewModel] in
                    await soundViewModel?.pauseSound(fadeDuration: fadeDuration)
                }
            }
        }
        
        isPlaying = false
        updateNowPlayingInfo()
        print("✅ All sounds paused")
    }

    // MARK: - Event Handlers
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
        
        if isPlaying {
            updateNowPlayingInfo()
        }
    }
    
    private func handleTimerModeChange(_ newMode: TimerService.TimerMode) {
        if newMode != .off {
            // Only start playing if not already playing
            if !isPlaying {
                Task {
                    await playSounds(fadeDuration: AppConstants.Animation.fadeLong)
                }
            }
            
            // Start the timer
            timerService.start(mode: newMode)
        } else {
            timerService.stop()
        }
    }
    
    private func handleAudioInterruption(_ isInterrupted: Bool) async {
        if isInterrupted {
            if isPlaying {
                wasPlayingBeforeInterruption = true
                await pauseSounds(fadeDuration: AppConstants.Animation.fadeLong)
            }
        } else if wasPlayingBeforeInterruption {
            await playSounds(fadeDuration: AppConstants.Animation.fadeLong)
            wasPlayingBeforeInterruption = false
        }
    }
    
    private func handleAppDidBecomeActive() async {
        print("🎵 Handling app did become active")
        
        await audioSessionService.reconfigure()
        
        // Refresh audio players if needed
        if isPlaying || soundsViewModels.contains(where: { $0.volume > 0 }) {
            await withTaskGroup(of: Void.self) { group in
                for soundViewModel in soundsViewModels {
                    group.addTask { [weak soundViewModel] in
                        await soundViewModel?.refreshAudioPlayer()
                    }
                }
            }
            
            // Resume playing if needed
            if isPlaying {
                for soundViewModel in soundsViewModels where soundViewModel.volume > 0 {
                    await soundViewModel.playSound()
                }
            }
        }
    }
    
    private func updateNowPlayingInfo() {
        let activeSounds = soundsViewModels
            .filter { $0.volume > 0 }
            .map { $0.sound.name }
        
        let title = activeSounds.isEmpty ? "White Noise" : activeSounds.joined(separator: ", ")
        
        var timerInfo: (duration: Int, elapsed: Int)?
        if timerService.mode != .off && timerService.isActive {
            let totalSeconds = timerService.mode.totalSeconds
            
            // Parse time string like "HH:MM:SS" or "MM:SS"
            let timeComponents = timerService.remainingTime.components(separatedBy: ":")
            let intComponents = timeComponents.compactMap { Int($0) }
            
            var remainingSeconds = 0
            for (index, value) in intComponents.enumerated() {
                let power = intComponents.count - index - 1
                remainingSeconds += value * Int(pow(60.0, Double(power)))
            }
            
            let elapsedSeconds = totalSeconds - remainingSeconds
            timerInfo = (duration: totalSeconds, elapsed: elapsedSeconds)
        }
        
        remoteCommandService.updateNowPlayingInfo(
            title: title,
            isPlaying: isPlaying,
            timerInfo: timerInfo
        )
    }
}