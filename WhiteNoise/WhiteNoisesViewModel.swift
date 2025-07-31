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
    private var wasPlayingBeforeInterruption = false
    private var appDidBecomeActiveObserver: NSObjectProtocol?
    private var appWillResignActiveObserver: NSObjectProtocol?
    private var appDidEnterBackgroundObserver: NSObjectProtocol?
    private var appWillEnterForegroundObserver: NSObjectProtocol?

    // MARK: Init

    init() {
        print("🎵 WhiteNoisesViewModel: Initializing")
        
        // Clean up any previous instance
        if let previousInstance = Self.activeInstance {
            print("⚠️ Cleaning up previous WhiteNoisesViewModel instance")
            previousInstance.cleanup()
        }
        
        Self.activeInstance = self
        
        setupAudioSession()
        setupTimerModeObserver()
        setupRemoteCommands()
        setupAudioInterruptionHandling()
        setupAppLifecycleObservers()
        
        // Load sounds asynchronously to avoid blocking UI
        Task {
            await setupSoundViewModels()
        }
        
        // Register for cleanup when the view model will be deallocated
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
        
        // Cancel timer task (doesn't require main actor)
        timerTask?.cancel()
        
        // Remove observers (doesn't require main actor)
        if let observer = appDidBecomeActiveObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = appWillResignActiveObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = appDidEnterBackgroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = appWillEnterForegroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    private func cleanup() {
        timerTask?.cancel()
        
        // Remove app lifecycle observers
        if let observer = appDidBecomeActiveObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = appWillResignActiveObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = appDidEnterBackgroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = appWillEnterForegroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: Public Methods
    
    func playingButtonSelected() {
        print("🎵 Playing button selected - current state: \(isPlaying)")
        Task {
            if isPlaying {
                await pauseSounds(fadeDuration: 0.5)
            } else {
                // Ensure audio session is active before playing
                await ensureAudioSessionActive()
                await playSounds(fadeDuration: 1.0)
            }
        }
    }
    
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

    // MARK: Private Methods
    
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
    
    private func setupSoundViewModels() async {
        // Load sounds on background queue
        let sounds = await SoundFactory.getSavedSoundsAsync()
        
        // Create view models on main thread with staggered loading
        soundsViewModels = []
        
        // Create view models in batches to prevent UI hang
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
            
            // Yield to main thread every 3 sounds to prevent blocking
            if index % 3 == 2 {
                await Task.yield()
            }
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
        
        // Update Now Playing info to reflect active sounds
        if isPlaying {
            updateNowPlayingInfo()
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
                    
                    // Update Now Playing info every 10 seconds to show timer progress
                    if self.timerRemainingSeconds % 10 == 0 {
                        self.updateNowPlayingInfo()
                    }
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
    
    private func setupRemoteCommands() {
        #if os(iOS)
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Play command
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            Task { @MainActor in
                if !self.isPlaying {
                    await self.playSounds(fadeDuration: 0.5)
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
                    await self.pauseSounds(fadeDuration: 0.5)
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
        
        // Disable other commands that we don't support
        commandCenter.nextTrackCommand.isEnabled = false
        commandCenter.previousTrackCommand.isEnabled = false
        commandCenter.changePlaybackRateCommand.isEnabled = false
        commandCenter.seekBackwardCommand.isEnabled = false
        commandCenter.seekForwardCommand.isEnabled = false
        commandCenter.skipBackwardCommand.isEnabled = false
        commandCenter.skipForwardCommand.isEnabled = false
        commandCenter.changePlaybackPositionCommand.isEnabled = false
        
        // Update Now Playing info
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
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
        #endif
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
                    await pauseSounds(fadeDuration: 0.1)
                }
            case .ended:
                // Interruption ended - resume if we were playing before
                if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                    let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                    if options.contains(.shouldResume) && wasPlayingBeforeInterruption {
                        await playSounds(fadeDuration: 0.5)
                        wasPlayingBeforeInterruption = false
                    }
                }
            @unknown default:
                break
            }
        }
        #endif
    }
    
    @objc private func handleAudioSessionRouteChange(notification: Notification) {
        #if os(iOS)
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        Task { @MainActor in
            switch reason {
            case .oldDeviceUnavailable:
                // Headphones were unplugged, pause playback
                if isPlaying {
                    await pauseSounds(fadeDuration: 0.1)
                }
            default:
                break
            }
        }
        #endif
    }
    
    private func setupAppLifecycleObservers() {
        #if os(iOS)
        appDidBecomeActiveObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("🎵 App did become active")
            Task { @MainActor [weak self] in
                await self?.handleAppDidBecomeActive()
            }
        }
        
        appWillResignActiveObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("🎵 App will resign active")
            Task { @MainActor [weak self] in
                self?.handleAppWillResignActive()
            }
        }
        
        appDidEnterBackgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("🎵 App did enter background")
            Task { @MainActor [weak self] in
                self?.handleAppDidEnterBackground()
            }
        }
        
        appWillEnterForegroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("🎵 App will enter foreground")
            Task { @MainActor [weak self] in
                await self?.handleAppWillEnterForeground()
            }
        }
        #endif
    }
    
    private func handleAppDidBecomeActive() async {
        #if os(iOS)
        print("🎵 Handling app did become active")
        
        // Always ensure audio session is properly configured
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            
            // Only activate if we're playing or about to play
            if isPlaying || soundsViewModels.contains(where: { $0.volume > 0 }) {
                try session.setActive(true)
                print("✅ Audio session reactivated on app active")
                
                // Refresh all audio players to ensure they're ready
                await withTaskGroup(of: Void.self) { group in
                    for soundViewModel in soundsViewModels {
                        group.addTask { [weak soundViewModel] in
                            await soundViewModel?.refreshAudioPlayer()
                        }
                    }
                }
                
                // Resume playing sounds if we were playing
                if isPlaying {
                    // Re-play all sounds that should be playing
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
    
    private func handleAppWillResignActive() {
        print("🎵 App will resign active - current playing state: \(isPlaying)")
    }
    
    private func handleAppDidEnterBackground() {
        print("🎵 App entered background - current playing state: \(isPlaying)")
    }
    
    private func handleAppWillEnterForeground() async {
        #if os(iOS)
        print("🎵 Handling app will enter foreground")
        
        // Always try to reactivate audio session when coming to foreground
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
