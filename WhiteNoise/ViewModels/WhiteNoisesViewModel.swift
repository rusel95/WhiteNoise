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

// MARK: - Protocols

/// Protocol for managing a collection of sounds
@MainActor
protocol SoundCollectionManager: AnyObject {
    var soundsViewModels: [SoundViewModel] { get set }
    var isPlaying: Bool { get set }
    var playingSounds: [SoundViewModel] { get }
    
    func playSounds(fadeDuration: Double?) async
    func pauseSounds(fadeDuration: Double?) async
    func stopAllSounds() async
}

/// Protocol for timer integration
@MainActor
protocol TimerIntegration: AnyObject {
    var timerMode: TimerService.TimerMode { get set }
    var remainingTimerTime: String { get }
    
    func handleTimerModeChange(_ newMode: TimerService.TimerMode)
    func handleTimerExpired() async
}

@MainActor
class WhiteNoisesViewModel: ObservableObject, SoundCollectionManager, TimerIntegration {
    
    // MARK: - Computed Properties for Protocols
    var playingSounds: [SoundViewModel] {
        soundsViewModels.filter { $0.volume > 0 }
    }
    
    // MARK: - Published Properties
    @Published var soundsViewModels: [SoundViewModel] = []
    @Published var isPlaying: Bool = false
    @Published var remainingTimerTime: String = ""
    
    var timerMode: TimerService.TimerMode {
        get { timerService.mode }
        set { handleTimerModeChange(newValue) }
    }
    
    // MARK: - Services
    private let audioSessionService: AudioSessionManaging
    private let timerService: TimerServiceProtocol
    private let remoteCommandService: RemoteCommandHandling
    private let soundFactory: SoundFactoryProtocol
    
    // MARK: - Private Properties
    private static var activeInstance: WhiteNoisesViewModel?
    private var cancellables = Set<AnyCancellable>()
    private var wasPlayingBeforeInterruption = false
    private var appLifecycleObservers: [NSObjectProtocol] = []

    // MARK: - Initialization
    init(
        soundFactory: SoundFactoryProtocol? = nil,
        audioSessionService: AudioSessionManaging? = nil,
        timerService: TimerServiceProtocol? = nil,
        remoteCommandService: RemoteCommandHandling? = nil
    ) {
        print("🎵 WhiteNoisesViewModel: Initializing")
        self.soundFactory = soundFactory ?? SoundFactory()
        self.audioSessionService = audioSessionService ?? AudioSessionService()
        self.timerService = timerService ?? TimerService()
        self.remoteCommandService = remoteCommandService ?? RemoteCommandService()
        
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
        
        // Update state immediately for instant UI feedback
        let wasPlaying = isPlaying
        isPlaying = !wasPlaying
        
        Task {
            do {
                if wasPlaying {
                    await pauseSounds(fadeDuration: AppConstants.Animation.fadeStandard, updateState: false)
                } else {
                    try await audioSessionService.ensureActive()
                    await playSounds(fadeDuration: AppConstants.Animation.fadeStandard, updateState: false)
                }
            } catch {
                // Revert state on error
                isPlaying = wasPlaying
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
            guard let self = self else { return }
            // Update the remaining time display
            self.remainingTimerTime = self.timerService.remainingTime
            // Update Now Playing info periodically
            if remainingSeconds % AppConstants.Timer.nowPlayingUpdateInterval == 0 {
                self.updateNowPlayingInfo()
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
        if let audioService = audioSessionService as? AudioSessionService {
            audioService.$isInterrupted
                .sink { [weak self] isInterrupted in
                    Task { @MainActor [weak self] in
                        await self?.handleAudioInterruption(isInterrupted)
                    }
                }
                .store(in: &cancellables)
        }
        
        setupAppLifecycleObservers()
    }
    
    private func loadSounds() {
        // Load sounds synchronously to show UI immediately
        let sounds = soundFactory.getSavedSounds()
        soundsViewModels = []
        
        for sound in sounds {
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
        }
        
        // Preload audio for favorite sounds after UI is shown
        Task.detached(priority: .background) { [weak self] in
            // Wait a bit for UI to settle
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
            
            guard let self = self else { return }
            
            // Preload sounds with volume > 0 in background
            await MainActor.run {
                for soundViewModel in self.soundsViewModels where soundViewModel.sound.volume > 0 {
                    soundViewModel.loadAudioAsync()
                }
            }
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
    
    // Protocol conformance - calls the internal version with updateState: true
    func playSounds(fadeDuration: Double? = nil) async {
        await playSounds(fadeDuration: fadeDuration, updateState: true)
    }
    
    // Protocol conformance - calls the internal version with updateState: true
    func pauseSounds(fadeDuration: Double? = nil) async {
        await pauseSounds(fadeDuration: fadeDuration, updateState: true)
    }
    
    // Internal implementation with state control
    private func playSounds(fadeDuration: Double? = nil, updateState: Bool = true) async {
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
        
        // Update state if requested (not when called from playingButtonSelected)
        if updateState && !isPlaying {
            isPlaying = true
        }
        updateNowPlayingInfo()
        print("✅ All sounds started playing")
    }
    
    private func pauseSounds(fadeDuration: Double? = nil, updateState: Bool = true) async {
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
        
        // Update state if requested (not when called from playingButtonSelected)
        if updateState && isPlaying {
            isPlaying = false
        }
        updateNowPlayingInfo()
        print("✅ All sounds paused")
    }

    // MARK: - Event Handlers
    private func handleVolumeChange(for soundViewModel: SoundViewModel, volume: Float) async {
        // Only handle audio playback if we're already playing
        if isPlaying {
            if volume > 0 {
                await soundViewModel.playSound()
            } else {
                await soundViewModel.pauseSound()
            }
            updateNowPlayingInfo()
        }
    }
    
    func handleTimerModeChange(_ newMode: TimerService.TimerMode) {
        if newMode != .off {
            // Only start playing if not already playing
            if !isPlaying {
                Task {
                    await playSounds(fadeDuration: AppConstants.Animation.fadeLong)
                }
            }
            
            // Start the timer
            timerService.start(mode: newMode)
            remainingTimerTime = timerService.remainingTime
            updateNowPlayingInfo()
        } else {
            timerService.stop()
            remainingTimerTime = ""
            updateNowPlayingInfo()
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
        
        // Only refresh audio if we were actually playing
        // Don't refresh on initial app launch
        if isPlaying {
            // Resume playing sounds that were playing
            for soundViewModel in soundsViewModels where soundViewModel.volume > 0 {
                await soundViewModel.playSound()
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

// MARK: - Protocol Conformance

extension WhiteNoisesViewModel {
    /// Stop all sounds immediately
    func stopAllSounds() async {
        await withTaskGroup(of: Void.self) { group in
            for soundViewModel in soundsViewModels {
                group.addTask {
                    await soundViewModel.stop()
                }
            }
        }
    }
    
    /// Handle timer expiration
    func handleTimerExpired() async {
        await pauseSounds(fadeDuration: AppConstants.Animation.fadeOut)
        remainingTimerTime = ""
    }
}