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
    
    private static var activeInstance: WhiteNoisesViewModel?
    
    enum TimerMode: Int, CaseIterable {
        case off = 0
        case oneMinute = 60
        case twoMinutes = 120
        case threeMinutes = 180
        case fiveMinutes = 300
        case tenMinutes = 600
        case fifteenMinutes = 900
        case thirtyMinutes = 1800
        case sixtyMinutes = 3600
        case twoHours = 7200
        case threeHours = 10800
        case fourHours = 14400
        case fiveHours = 18000
        case sixHours = 21600
        case sevenHours = 25200
        case eightHours = 28800
        
        var description: String {
            switch self {
            case .off: return "Off"
            case .oneMinute: return "1 minute"
            case .twoMinutes: return "2 minutes"
            case .threeMinutes: return "3 minutes"
            case .fiveMinutes: return "5 minutes"
            case .tenMinutes: return "10 minutes"
            case .fifteenMinutes: return "15 minutes"
            case .thirtyMinutes: return "30 minutes"
            case .sixtyMinutes: return "1 hour"
            case .twoHours: return "2 hours"
            case .threeHours: return "3 hours"
            case .fourHours: return "4 hours"
            case .fiveHours: return "5 hours"
            case .sixHours: return "6 hours"
            case .sevenHours: return "7 hours"
            case .eightHours: return "8 hours"
            }
        }
        
        var seconds: Int { rawValue }
        var minutes: Int { rawValue / 60 }
    }

    // MARK: Properties
    
    @Published var soundsViewModels: [SoundViewModel] = []
    @Published var isPlaying: Bool = false
    @Published var timerMode: TimerMode = .off
    @Published var remainingTimerTime: String = ""
    
    private var timerRemainingSeconds: Int = 0
    private var timerTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    private var wasPlayingBeforeInterruption = false
    private var appLifecycleObservers: [NSObjectProtocol] = []

    // MARK: Init
    
    init() {
        print("🎵 WhiteNoisesViewModel: Initializing")
        
        // Clean up any previous instance
        if let previousInstance = Self.activeInstance {
            print("⚠️ Cleaning up previous WhiteNoisesViewModel instance")
            previousInstance.timerTask?.cancel()
            previousInstance.appLifecycleObservers.forEach {
                NotificationCenter.default.removeObserver($0)
            }
            previousInstance.appLifecycleObservers.removeAll()
        }
        
        Self.activeInstance = self
        
        setupAudioSession()
        setupTimerModeObserver()
        setupRemoteCommands()
        setupAudioInterruptionHandling()
        setupAppLifecycleObservers()
        
        // Create placeholders immediately for UI responsiveness
        createPlaceholderSoundViewModels()
        
        // Load actual sounds asynchronously
        Task {
            await loadAndUpdateSoundViewModels()
        }
        
        // Register for cleanup
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
    
    deinit {
        print("🎵 WhiteNoisesViewModel: Deinitializing")
        // Cancel timer synchronously
        timerTask?.cancel()
        
        // Remove observers synchronously
        appLifecycleObservers.forEach {
            NotificationCenter.default.removeObserver($0)
        }
        appLifecycleObservers.removeAll()
    }

    // MARK: Public Methods
    
    func playingButtonSelected() {
        print("🎵 Playing button selected - current state: \(isPlaying)")
        Task {
            if isPlaying {
                await pauseSounds(fadeDuration: 2.0)
            } else {
                await ensureAudioSessionActive()
                await playSounds(fadeDuration: 2.0)
            }
        }
    }

    // MARK: Private Methods - Setup
    
    private func setupAudioSession() {
        #if os(iOS)
        Task { @MainActor in
            do {
                print("🎵 Setting up audio session")
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
                print("✅ Audio session activated successfully")
            } catch {
                print("❌ Failed to set audio session: \(error)")
            }
        }
        #endif
    }
    
    private func createPlaceholderSoundViewModels() {
        // Create sound view models with default data immediately for UI responsiveness
        let placeholderSounds = SoundFactory.createSounds()
        
        soundsViewModels = placeholderSounds.map { sound in
            let viewModel = SoundViewModel(sound: sound)
            
            // Setup observers immediately
            viewModel.$volume
                .dropFirst()
                .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
                .sink { [weak self, weak viewModel] volume in
                    guard let viewModel = viewModel else { return }
                    Task { [weak self] in
                        await self?.handleVolumeChange(for: viewModel, volume: volume)
                    }
                }
                .store(in: &cancellables)
            
            return viewModel
        }
    }
    
    private func loadAndUpdateSoundViewModels() async {
        let soundFactory = SoundFactory()
        let savedSounds = await soundFactory.getSavedSoundsAsync()
        
        // Replace view models with saved versions
        var newViewModels: [SoundViewModel] = []
        
        for (index, savedSound) in savedSounds.enumerated() {
            let viewModel = SoundViewModel(sound: savedSound)
            newViewModels.append(viewModel)
            
            // Setup observers
            viewModel.$volume
                .dropFirst()
                .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
                .sink { [weak self, weak viewModel] volume in
                    guard let viewModel = viewModel else { return }
                    Task { [weak self] in
                        await self?.handleVolumeChange(for: viewModel, volume: volume)
                    }
                }
                .store(in: &cancellables)
            
            // Yield periodically for better performance
            if index % 3 == 2 {
                await Task.yield()
            }
        }
        
        // Replace all view models at once
        soundsViewModels = newViewModels
    }
    
    private func setupTimerModeObserver() {
        $timerMode
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] newMode in
                self?.handleTimerModeChange(newMode)
            }
            .store(in: &cancellables)
    }
    
    private func setupRemoteCommands() {
        #if os(iOS)
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Play command
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            Task { @MainActor in
                if !self.isPlaying {
                    await self.playSounds(fadeDuration: 5.0)
                }
            }
            return .success
        }
        
        // Pause command
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            Task { @MainActor in
                if self.isPlaying {
                    await self.pauseSounds(fadeDuration: 5.0)
                }
            }
            return .success
        }
        
        // Toggle play/pause command
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            Task { @MainActor in
                self.playingButtonSelected()
            }
            return .success
        }
        
        // Disable other commands
        commandCenter.nextTrackCommand.isEnabled = false
        commandCenter.previousTrackCommand.isEnabled = false
        commandCenter.changePlaybackRateCommand.isEnabled = false
        commandCenter.seekBackwardCommand.isEnabled = false
        commandCenter.seekForwardCommand.isEnabled = false
        commandCenter.skipBackwardCommand.isEnabled = false
        commandCenter.skipForwardCommand.isEnabled = false
        commandCenter.changePlaybackPositionCommand.isEnabled = false
        
        updateNowPlayingInfo()
        #endif
    }
    
    private func setupAudioInterruptionHandling() {
        #if os(iOS)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
        #endif
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
            Task { @MainActor [weak self] in
                self?.handleAppDidEnterBackground()
            }
        }
        appLifecycleObservers.append(backgroundObserver)
        
        let foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("🎵 App will enter foreground")
            Task { [weak self] in
                await self?.handleAppWillEnterForeground()
            }
        }
        appLifecycleObservers.append(foregroundObserver)
        #endif
    }

    // MARK: Private Methods - Playback
    
    private func ensureAudioSessionActive() async {
        #if os(iOS)
        do {
            let session = AVAudioSession.sharedInstance()
            if !session.isOtherAudioPlaying {
                try session.setActive(true)
                print("✅ Audio session activated before playing")
            }
        } catch {
            print("❌ Failed to activate audio session: \(error)")
        }
        #endif
    }
    
    private func playSounds(fadeDuration: Double? = nil) async {
        print("🎵 Playing sounds with fade duration: \(fadeDuration ?? 0)")
        
        // Start timer if needed
        if timerMode != .off && timerTask == nil {
            startTimer()
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
        timerTask?.cancel()
        timerTask = nil
        
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
    
    private func fadeOutSounds(duration: Double) async {
        print("🎵 Fading out sounds over \(duration) seconds")
        
        // Fade out all sounds without pausing immediately
        let soundsToFade = soundsViewModels.filter { $0.volume > 0 }
        
        await withTaskGroup(of: Void.self) { group in
            for soundViewModel in soundsToFade {
                group.addTask { [weak soundViewModel] in
                    await soundViewModel?.pauseSound(fadeDuration: duration)
                }
            }
        }
    }

    // MARK: Private Methods - Event Handlers
    
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
    
    private func handleTimerModeChange(_ newMode: TimerMode) {
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
                Task {
                    await playSounds(fadeDuration: 5.0)
                }
            }
            
            // Always start the timer when a time is selected
            startTimer()
        }
    }
    
    private func startTimer() {
        timerTask?.cancel()
        
        timerTask = Task { [weak self] in
            var fadeStarted = false
            
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                
                guard let self = self else { break }
                
                if self.timerRemainingSeconds > 0 {
                    self.timerRemainingSeconds -= 1
                    self.updateRemainingTimeDisplay()
                    
                    // Start fade out when 10 seconds remain
                    if self.timerRemainingSeconds == 10 && !fadeStarted {
                        fadeStarted = true
                        print("🎵 Starting 10-second fade out for timer end")
                        Task {
                            await self.fadeOutSounds(duration: 10.0)
                        }
                    }
                    
                    // Update Now Playing info every 10 seconds to show timer progress
                    if self.timerRemainingSeconds % 10 == 0 {
                        self.updateNowPlayingInfo()
                    }
                } else {
                    // Timer reached 0, pause without additional fade (already fading)
                    if !fadeStarted {
                        await self.pauseSounds(fadeDuration: 10.0)
                    } else {
                        // Just update state since fade is already in progress
                        self.isPlaying = false
                        self.updateNowPlayingInfo()
                    }
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
    
    @objc private func handleAudioSessionInterruption(notification: Notification) {
        #if os(iOS)
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        Task { @MainActor in
            switch type {
            case .began:
                // Interruption began - pause if playing
                if isPlaying {
                    wasPlayingBeforeInterruption = true
                    await pauseSounds(fadeDuration: 5.0)
                }
            case .ended:
                // Interruption ended - resume if we were playing before
                if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                    let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                    if options.contains(.shouldResume) && wasPlayingBeforeInterruption {
                        await playSounds(fadeDuration: 5.0)
                        wasPlayingBeforeInterruption = false
                    }
                }
            @unknown default:
                break
            }
        }
        #endif
    }
    
    private func handleAppDidBecomeActive() async {
        print("🎵 Handling app did become active")
        
        #if os(iOS)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            
            if isPlaying || soundsViewModels.contains(where: { $0.volume > 0 }) {
                try session.setActive(true)
                print("✅ Audio session reactivated on app active")
                
                // Refresh audio players
                await withTaskGroup(of: Void.self) { group in
                    for soundViewModel in soundsViewModels {
                        group.addTask { [weak soundViewModel] in
                            await soundViewModel?.refreshAudioPlayer()
                        }
                    }
                }
                
                // Resume playing
                if isPlaying {
                    for soundViewModel in soundsViewModels where soundViewModel.volume > 0 {
                        await soundViewModel.playSound()
                    }
                }
            }
        } catch {
            print("❌ Failed to reactivate audio session: \(error)")
        }
        #endif
    }
    
    private func handleAppDidEnterBackground() {
        print("🎵 App entered background - current playing state: \(isPlaying)")
    }
    
    private func handleAppWillEnterForeground() async {
        print("🎵 Handling app will enter foreground")
        
        #if os(iOS)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
            print("✅ Audio session configured on foreground")
        } catch {
            print("❌ Failed to configure audio session on foreground: \(error)")
        }
        #endif
    }
    
    private func updateNowPlayingInfo() {
        #if os(iOS)
        var nowPlayingInfo = [String: Any]()
        
        // Get active sounds
        let activeSounds = soundsViewModels
            .filter { $0.volume > 0 }
            .map { $0.sound.name }
        
        let title = activeSounds.isEmpty ? "White Noise" : activeSounds.joined(separator: ", ")
        nowPlayingInfo[MPMediaItemPropertyTitle] = title
        nowPlayingInfo[MPMediaItemPropertyArtist] = "WhiteNoise App"
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = "Ambient Sounds"
        
        // Set playback state
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        
        // Add timer info if active
        if timerMode != .off && timerRemainingSeconds > 0 {
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = Double(timerMode.minutes * 60)
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = Double(timerMode.minutes * 60 - timerRemainingSeconds)
        }
        
        // Use app icon for lock screen artwork
        if let image = UIImage(named: "LaunchScreenIcon") {
            let artwork = MPMediaItemArtwork(boundsSize: CGSize(width: 300, height: 300)) { size in
                // Resize image to fit the requested size while maintaining aspect ratio
                let renderer = UIGraphicsImageRenderer(size: size)
                return renderer.image { _ in
                    image.draw(in: CGRect(origin: .zero, size: size))
                }
            }
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        #endif
    }
}