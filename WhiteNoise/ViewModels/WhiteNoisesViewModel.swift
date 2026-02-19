//
//  WhiteNoisesViewModel.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 30.05.2023.
//

import Foundation
@preconcurrency import AVFAudio
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
    
    /// Checks if any sounds are actually playing (based on real audio state, not UI state)
    private var actuallyPlayingAudio: Bool {
        soundsViewModels.contains { $0.isPlaying && $0.volume > 0 }
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
    // CONCURRENCY: Thread-safe singleton access using nonisolated(unsafe)
    // Safety invariant: Access only occurs within MainActor-isolated contexts
    // TODO: [Swift 6 Migration] Replace with actor-based singleton or proper synchronization
    private nonisolated(unsafe) static var activeInstance: WhiteNoisesViewModel?
    private var cancellables = Set<AnyCancellable>()
    private var wasPlayingBeforeInterruption = false
    // CONCURRENCY: Marked nonisolated(unsafe) to allow cleanup in deinit
    // Safety invariant: Only modified on MainActor, read in deinit after all async work completes
    // TODO: [Swift 6 Migration] Consider moving cleanup to a separate non-isolated method
    private nonisolated(unsafe) var appLifecycleObservers: [any NSObjectProtocol] = []
    private var playPauseTask: Task<Void, Never>?

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
        // Timer will stop on its own when deallocated
        playPauseTask?.cancel()
        
        appLifecycleObservers.forEach {
            NotificationCenter.default.removeObserver($0)
        }
        appLifecycleObservers.removeAll()
    }

    // MARK: - Public Methods
    
    /// Synchronizes the UI state (button, timer) with the actual audio playing state.
    ///
    /// This method checks if audio is actually playing and updates the UI state to match.
    /// It's called when the app becomes active to ensure consistency after lock screen
    /// control usage or other external state changes.
    private func syncStateWithActualAudio() {
        let wasUIPlaying = isPlaying
        let actuallyPlaying = actuallyPlayingAudio
        
        print("🔄 WhiteNoisesVM.syncStateWithActualAudio - CHECKING SYNC:")
        print("  - UI state (isPlaying): \(wasUIPlaying)")
        print("  - Actual audio state: \(actuallyPlaying)")
        print("  - Timer active: \(timerService.isActive)")
        print("  - Timer has remaining: \(timerService.hasRemainingTime)")
        
        if actuallyPlaying != wasUIPlaying {
            print("⚠️ WhiteNoisesVM.syncStateWithActualAudio - STATE MISMATCH DETECTED!")
            print("🔄 WhiteNoisesVM.syncStateWithActualAudio - SYNCING: UI state \(wasUIPlaying) → \(actuallyPlaying)")
            isPlaying = actuallyPlaying
            
            // Also sync timer state
            if actuallyPlaying && timerService.hasRemainingTime && !timerService.isActive {
                print("⏱️ WhiteNoisesVM.syncStateWithActualAudio - RESUMING TIMER to match playing state")
                timerService.resume()
                remainingTimerTime = timerService.remainingTime
            } else if !actuallyPlaying && timerService.isActive {
                print("⏱️ WhiteNoisesVM.syncStateWithActualAudio - PAUSING TIMER to match paused state")
                timerService.pause()
            }
            
            updateNowPlayingInfo()
            print("✅ WhiteNoisesVM.syncStateWithActualAudio - SYNC COMPLETED")
        } else {
            print("✅ WhiteNoisesVM.syncStateWithActualAudio - Already in sync")
        }
    }
    
    // MARK: - Public Methods
    
    /// Toggles the playback state between playing and paused.
    ///
    /// This method handles user interaction with the play/pause button. It provides immediate
    /// UI feedback by updating the `isPlaying` state synchronously, then performs the actual
    /// audio operations asynchronously.
    ///
    /// The method cancels any ongoing fade operations to allow immediate response to user input.
    ///
    /// - Important: This method updates the UI state immediately for responsiveness,
    ///   but the actual audio state change happens asynchronously.
    func playingButtonSelected() {
        print("🎯 WhiteNoisesVM.playingButtonSelected - START: isPlaying=\(isPlaying)")

        // Cancel any existing play/pause task and its fade operations
        if playPauseTask != nil {
            print("🔄 WhiteNoisesVM.playingButtonSelected - CANCELLING: Previous play/pause task")
            playPauseTask?.cancel()
            playPauseTask = nil

            // Cancel all ongoing fade operations on sounds
            for soundViewModel in soundsViewModels {
                soundViewModel.cancelFade()
            }
        }

        // Update state immediately for instant UI feedback
        let wasPlaying = isPlaying
        isPlaying = !wasPlaying

        print("🔄 WhiteNoisesVM.playingButtonSelected - STATE CHANGE: isPlaying \(wasPlaying)→\(!wasPlaying)")
        print("📊 WhiteNoisesVM.playingButtonSelected - STATE SNAPSHOT:")
        print("  - isPlaying: \(isPlaying)")
        print("  - activeSounds: \(soundsViewModels.filter { $0.volume > 0 }.count)")
        print("  - timerMode: \(timerService.mode)")
        print("  - timerActive: \(timerService.isActive)")

        playPauseTask = Task { [weak self] in
            guard let self = self else {
                print("❌ WhiteNoisesVM.playingButtonSelected - FAILED: Self deallocated")
                return
            }

            print("🔄 WhiteNoisesVM.playingButtonSelected - ASYNC START: wasPlaying=\(wasPlaying)")

            if wasPlaying {
                print("🔘 WhiteNoisesVM.playingButtonSelected - ACTION: Pausing sounds")
                await self.pauseSounds(fadeDuration: AppConstants.Animation.fadeStandard, updateState: false)
            } else {
                print("🔘 WhiteNoisesVM.playingButtonSelected - ACTION: Playing sounds")
                await self.audioSessionService.ensureActive()
                await self.playSounds(fadeDuration: AppConstants.Animation.fadeStandard, updateState: false)
            }

            print("✅ WhiteNoisesVM.playingButtonSelected - COMPLETED: Action finished")
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
        
        // Remote command callbacks - using @MainActor closures for proper isolation
        remoteCommandService.onPlayCommand = { [weak self] in
            guard let strongSelf = self else { return }
            await MainActor.run {
                print("📡 WhiteNoisesVM - REMOTE COMMAND: Play received")
                print("  - Current UI state: \(strongSelf.isPlaying)")
                print("  - Actual audio state: \(strongSelf.actuallyPlayingAudio)")

                // Check actual state first
                if !strongSelf.actuallyPlayingAudio {
                    print("📡 WhiteNoisesVM - REMOTE: Starting playback")
                    strongSelf.isPlaying = true

                    // Cancel existing task and track new one
                    strongSelf.playPauseTask?.cancel()
                    strongSelf.playPauseTask = Task {
                        await strongSelf.playSounds(fadeDuration: AppConstants.Animation.fadeLong, updateState: false)
                    }

                    // Resume timer if needed
                    if strongSelf.timerService.hasRemainingTime && !strongSelf.timerService.isActive {
                        print("📡 WhiteNoisesVM - REMOTE: Resuming timer")
                        strongSelf.timerService.resume()
                        strongSelf.remainingTimerTime = strongSelf.timerService.remainingTime
                    }
                } else {
                    print("📡 WhiteNoisesVM - REMOTE: Already playing, syncing UI state")
                    strongSelf.isPlaying = true
                }
            }
        }

        remoteCommandService.onPauseCommand = { [weak self] in
            guard let strongSelf = self else { return }
            await MainActor.run {
                print("📡 WhiteNoisesVM - REMOTE COMMAND: Pause received")
                print("  - Current UI state: \(strongSelf.isPlaying)")
                print("  - Actual audio state: \(strongSelf.actuallyPlayingAudio)")

                // Check actual state first
                if strongSelf.actuallyPlayingAudio {
                    print("📡 WhiteNoisesVM - REMOTE: Pausing playback")
                    strongSelf.isPlaying = false

                    // Cancel existing task and track new one
                    strongSelf.playPauseTask?.cancel()
                    strongSelf.playPauseTask = Task {
                        await strongSelf.pauseSounds(fadeDuration: AppConstants.Animation.fadeLong, updateState: false)
                    }

                    // Pause timer if active
                    if strongSelf.timerService.isActive {
                        print("📡 WhiteNoisesVM - REMOTE: Pausing timer")
                        strongSelf.timerService.pause()
                    }
                } else {
                    print("📡 WhiteNoisesVM - REMOTE: Already paused, syncing UI state")
                    strongSelf.isPlaying = false
                }
            }
        }

        remoteCommandService.onToggleCommand = { [weak self] in
            guard let strongSelf = self else { return }
            Task { @MainActor in
                print("📡 WhiteNoisesVM - REMOTE COMMAND: Toggle received")
                print("  - Current UI state: \(strongSelf.isPlaying)")
                print("  - Actual audio state: \(strongSelf.actuallyPlayingAudio)")

                // Sync state first, then toggle based on actual audio state
                if strongSelf.actuallyPlayingAudio != strongSelf.isPlaying {
                    print("📡 WhiteNoisesVM - REMOTE: State mismatch detected, syncing first")
                    strongSelf.syncStateWithActualAudio()
                }

                // playingButtonSelected already tracks its task via playPauseTask
                strongSelf.playingButtonSelected()
            }
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
        // Load sequentially to avoid disk I/O contention - faster than parallel on flash storage
        Task.detached(priority: .background) { [weak self] in
            // Wait for UI to settle
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms

            guard let self = self else { return }

            // Get sounds to preload
            let soundsToPreload = await MainActor.run {
                self.soundsViewModels.filter { $0.sound.volume > 0 }
            }

            // Load sounds one at a time - each completes before next starts
            // This avoids I/O contention and is faster than parallel loading
            for soundViewModel in soundsToPreload {
                await soundViewModel.preloadAudio()
            }
        }
    }
    
    private func registerForCleanup() {
        // MEMORY FIX: Store observer to allow proper cleanup
        let terminateObserver = NotificationCenter.default.addObserver(
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
        appLifecycleObservers.append(terminateObserver)
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
        ) { _ in
            print("🎵 App did enter background")
        }
        appLifecycleObservers.append(backgroundObserver)
        
        let foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("🎵 App will enter foreground")
            Task { @MainActor [weak self] in
                await self?.audioSessionService.reconfigure()
            }
        }
        appLifecycleObservers.append(foregroundObserver)
        #endif
    }

    // MARK: - Playback Methods
    
    /// Starts playback of all sounds with non-zero volume.
    ///
    /// This method coordinates the playback of multiple sounds simultaneously, manages
    /// the timer service if active, and updates the Now Playing information for system
    /// media controls.
    ///
    /// - Parameter fadeDuration: The duration in seconds for the fade-in effect.
    ///   If `nil`, sounds will start at their set volume immediately.
    ///
    /// - Note: This method is part of the `SoundCollectionManager` protocol conformance.
    func playSounds(fadeDuration: Double? = nil) async {
        await playSounds(fadeDuration: fadeDuration, updateState: true)
    }
    
    /// Pauses playback of all currently playing sounds.
    ///
    /// This method coordinates the pausing of multiple sounds simultaneously, pauses
    /// the timer service if active (preserving remaining time), and updates the Now
    /// Playing information.
    ///
    /// - Parameter fadeDuration: The duration in seconds for the fade-out effect.
    ///   If `nil`, sounds will pause immediately.
    ///
    /// - Note: This method is part of the `SoundCollectionManager` protocol conformance.
    func pauseSounds(fadeDuration: Double? = nil) async {
        await pauseSounds(fadeDuration: fadeDuration, updateState: true)
    }
    
    /// Internal implementation for starting sound playback.
    ///
    /// This private method handles the actual playback logic, including timer management,
    /// concurrent sound playback, and state updates. It includes duplicate call detection
    /// to prevent unnecessary operations.
    ///
    /// - Parameters:
    ///   - fadeDuration: The duration in seconds for the fade-in effect. If `nil`, sounds
    ///     will start at their set volume immediately.
    ///   - updateState: A Boolean value indicating whether to update the `isPlaying` state.
    ///     Set to `false` when called from `playingButtonSelected()` to avoid double updates.
    ///
    /// - Important: This method will return early if sounds are already playing and
    ///   `updateState` is `true` to prevent duplicate operations.
    private func playSounds(fadeDuration: Double? = nil, updateState: Bool = true) async {
        print("🎯 WhiteNoisesVM.playSounds - START: fade=\(fadeDuration ?? 0)s, updateState=\(updateState)")
        
        // Check if already in playing state
        let actuallyPlaying = soundsViewModels.contains { $0.isPlaying && $0.volume > 0 }
        if actuallyPlaying && isPlaying && updateState {
            print("⚠️ WhiteNoisesVM.playSounds - SKIPPED: Already playing (actuallyPlaying=\(actuallyPlaying), isPlaying=\(isPlaying))")
            return
        }
        
        print("📊 WhiteNoisesVM.playSounds - PRE-STATE:")
        print("  - isPlaying: \(isPlaying)")
        print("  - actuallyPlaying: \(actuallyPlaying)")
        print("  - sounds with volume>0: \(soundsViewModels.filter { $0.volume > 0 }.count)")
        
        // Resume or start timer if needed
        if timerService.mode != .off {
            print("⏱️ WhiteNoisesVM.playSounds - TIMER CHECK: mode=\(timerService.mode), hasRemaining=\(timerService.hasRemainingTime), isActive=\(timerService.isActive)")
            
            if timerService.hasRemainingTime && !timerService.isActive {
                // Resume from pause
                print("⏱️ WhiteNoisesVM.playSounds - TIMER ACTION: Resuming paused timer")
                timerService.resume()
                remainingTimerTime = timerService.remainingTime
                print("⏱️ WhiteNoisesVM.playSounds - TIMER RESUMED: remaining=\(remainingTimerTime)")
            } else if !timerService.hasRemainingTime {
                // Fresh start
                print("⏱️ WhiteNoisesVM.playSounds - TIMER ACTION: Starting new timer")
                timerService.start(mode: timerService.mode)
                remainingTimerTime = timerService.remainingTime
                print("⏱️ WhiteNoisesVM.playSounds - TIMER STARTED: duration=\(remainingTimerTime)")
            } else {
                print("⏱️ WhiteNoisesVM.playSounds - TIMER: Already active, no action needed")
            }
        } else {
            print("⏱️ WhiteNoisesVM.playSounds - TIMER: Off, skipping timer operations")
        }
        
        // Play all sounds with volume > 0
        let soundsToPlay = soundsViewModels.filter { $0.volume > 0 }
        print("🎵 WhiteNoisesVM.playSounds - PLAYING: \(soundsToPlay.count) sounds")
        for sound in soundsToPlay {
            print("  - \(sound.sound.name): volume=\(sound.volume)")
        }
        
        await withTaskGroup(of: Void.self) { group in
            for soundViewModel in soundsToPlay {
                group.addTask { [weak soundViewModel] in
                    await soundViewModel?.playSound(fadeDuration: fadeDuration)
                }
            }
        }
        
        // Update state if requested (not when called from playingButtonSelected)
        if updateState && !isPlaying {
            print("🔄 WhiteNoisesVM.playSounds - STATE UPDATE: isPlaying false→true")
            isPlaying = true
        } else {
            print("🔄 WhiteNoisesVM.playSounds - STATE: No update needed (updateState=\(updateState), isPlaying=\(isPlaying))")
        }
        
        updateNowPlayingInfo()
        
        print("📊 WhiteNoisesVM.playSounds - POST-STATE:")
        print("  - isPlaying: \(isPlaying)")
        print("  - activeSounds: \(soundsViewModels.filter { $0.isPlaying && $0.volume > 0 }.count)")
        print("  - timerActive: \(timerService.isActive)")
        print("✅ WhiteNoisesVM.playSounds - COMPLETED")
    }
    
    /// Internal implementation for pausing sound playback.
    ///
    /// This private method handles the actual pause logic, including timer pausing
    /// (preserving remaining time), concurrent sound pausing, and state updates.
    /// It includes duplicate call detection to prevent unnecessary operations.
    ///
    /// - Parameters:
    ///   - fadeDuration: The duration in seconds for the fade-out effect. If `nil`,
    ///     sounds will pause immediately.
    ///   - updateState: A Boolean value indicating whether to update the `isPlaying` state.
    ///     Set to `false` when called from `playingButtonSelected()` to avoid double updates.
    ///
    /// - Important: This method will return early if sounds are already paused and
    ///   `updateState` is `true` to prevent duplicate operations.
    ///
    /// - Note: The timer is paused (not stopped) to preserve the remaining time for resume.
    private func pauseSounds(fadeDuration: Double? = nil, updateState: Bool = true) async {
        print("🎯 WhiteNoisesVM.pauseSounds - START: fade=\(fadeDuration ?? 0)s, updateState=\(updateState)")
        
        // Check if already paused
        let actuallyPlaying = soundsViewModels.contains { $0.isPlaying && $0.volume > 0 }
        if !actuallyPlaying && !isPlaying && updateState {
            print("⚠️ WhiteNoisesVM.pauseSounds - SKIPPED: Already paused (actuallyPlaying=\(actuallyPlaying), isPlaying=\(isPlaying))")
            return
        }
        
        print("📊 WhiteNoisesVM.pauseSounds - PRE-STATE:")
        print("  - isPlaying: \(isPlaying)")
        print("  - actuallyPlaying: \(actuallyPlaying)")
        print("  - sounds with volume>0: \(soundsViewModels.filter { $0.volume > 0 }.count)")
        
        // Pause timer (don't stop it completely)
        if timerService.isActive {
            print("⏱️ WhiteNoisesVM.pauseSounds - TIMER ACTION: Pausing timer")
            print("⏱️ WhiteNoisesVM.pauseSounds - TIMER STATE: remaining=\(timerService.remainingTime), mode=\(timerService.mode)")
            timerService.pause()
            print("⏱️ WhiteNoisesVM.pauseSounds - TIMER PAUSED: Will resume from \(timerService.remainingTime)")
        } else {
            print("⏱️ WhiteNoisesVM.pauseSounds - TIMER: Not active, no pause needed")
        }
        
        // Pause all sounds
        let soundsToPause = soundsViewModels.filter { $0.volume > 0 }
        print("🎵 WhiteNoisesVM.pauseSounds - PAUSING: \(soundsToPause.count) sounds")
        for sound in soundsToPause {
            print("  - \(sound.sound.name): volume=\(sound.volume)")
        }
        
        await withTaskGroup(of: Void.self) { group in
            for soundViewModel in soundsToPause {
                group.addTask { [weak soundViewModel] in
                    await soundViewModel?.pauseSound(fadeDuration: fadeDuration)
                }
            }
        }
        
        // Update state if requested (not when called from playingButtonSelected)
        if updateState && isPlaying {
            print("🔄 WhiteNoisesVM.pauseSounds - STATE UPDATE: isPlaying true→false")
            isPlaying = false
        } else {
            print("🔄 WhiteNoisesVM.pauseSounds - STATE: No update needed (updateState=\(updateState), isPlaying=\(isPlaying))")
        }
        
        updateNowPlayingInfo()
        
        print("📊 WhiteNoisesVM.pauseSounds - POST-STATE:")
        print("  - isPlaying: \(isPlaying)")
        print("  - activeSounds: \(soundsViewModels.filter { $0.isPlaying && $0.volume > 0 }.count)")
        print("  - timerActive: \(timerService.isActive)")
        print("✅ WhiteNoisesVM.pauseSounds - COMPLETED")
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
        print("🎯 WhiteNoisesVM.handleTimerModeChange - START: newMode=\(newMode.displayText)")
        print("📊 WhiteNoisesVM.handleTimerModeChange - CURRENT STATE: isPlaying=\(isPlaying), timerActive=\(timerService.isActive)")
        
        if newMode != .off {
            print("⏱️ WhiteNoisesVM.handleTimerModeChange - ACTION: Starting timer with mode \(newMode.displayText)")
            
            // Start the timer
            timerService.start(mode: newMode)
            remainingTimerTime = timerService.remainingTime
            print("⏱️ WhiteNoisesVM.handleTimerModeChange - TIMER STARTED: \(remainingTimerTime)")
            
            // Only start playing if not already playing
            if !isPlaying {
                print("🎵 WhiteNoisesVM.handleTimerModeChange - TRIGGERING PLAY: Not currently playing")
                // Update state immediately for instant UI feedback
                isPlaying = true
                // STABILITY FIX: Use weak self to prevent retain cycle
                playPauseTask?.cancel()
                playPauseTask = Task { [weak self] in
                    await self?.playSounds(fadeDuration: AppConstants.Animation.fadeLong, updateState: false)
                }
            } else {
                print("🎵 WhiteNoisesVM.handleTimerModeChange - ALREADY PLAYING: No need to start")
            }
            updateNowPlayingInfo()
        } else {
            print("⏱️ WhiteNoisesVM.handleTimerModeChange - ACTION: Turning timer off")
            
            // Fully stop the timer when turned off
            timerService.stop()
            remainingTimerTime = ""
            updateNowPlayingInfo()
            
            print("⏱️ WhiteNoisesVM.handleTimerModeChange - TIMER STOPPED")
        }
        
        print("✅ WhiteNoisesVM.handleTimerModeChange - COMPLETED")
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
        print("📱 WhiteNoisesVM.handleAppDidBecomeActive - START")
        
        await audioSessionService.reconfigure()
        
        // CRITICAL: Sync UI state with actual audio state
        // This handles cases where lock screen controls changed the state
        syncStateWithActualAudio()
        
        // Only refresh audio if we were actually playing (after sync)
        if isPlaying && actuallyPlayingAudio {
            print("📱 WhiteNoisesVM.handleAppDidBecomeActive - Refreshing active audio")
            // Resume playing sounds that were playing
            for soundViewModel in soundsViewModels where soundViewModel.volume > 0 {
                await soundViewModel.playSound()
            }
        } else if isPlaying && !actuallyPlayingAudio {
            // UI says playing but audio is not - restart audio
            print("📱 WhiteNoisesVM.handleAppDidBecomeActive - UI says playing but audio stopped, restarting")
            await playSounds(fadeDuration: AppConstants.Animation.fadeLong, updateState: false)
        }
        
        print("📱 WhiteNoisesVM.handleAppDidBecomeActive - COMPLETED")
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
