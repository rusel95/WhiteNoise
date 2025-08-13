//
//  AudioSessionFacade.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 2025-08-11.
//

import Foundation
import AVFoundation
import UIKit

// MARK: - Audio Session Facade

@MainActor
final class AudioSessionFacade {
    
    // MARK: - Properties
    
    private var audioSessionService: AudioSessionManaging?
    private var remoteCommandService: RemoteCommandHandling?
    private var isConfigured = false
    
    // MARK: - Initialization
    
    init(
        audioSessionService: AudioSessionManaging? = nil,
        remoteCommandService: RemoteCommandHandling? = nil
    ) {
        self.audioSessionService = audioSessionService
        self.remoteCommandService = remoteCommandService
    }
    
    // MARK: - Public Methods
    
    /// Simple one-call setup for audio session
    func setupAudioEnvironment() async throws {
        guard !isConfigured else { return }
        
        // Lazy initialize services if needed
        if audioSessionService == nil {
            audioSessionService = AudioSessionService()
        }
        if remoteCommandService == nil {
            remoteCommandService = RemoteCommandService()
        }
        
        // Configure audio session
        audioSessionService?.setupAudioSession()
        
        // Setup remote commands
        setupRemoteCommands()
        
        // Ensure session is active
        await audioSessionService?.ensureActive()
        
        isConfigured = true
        print("✅ Audio environment configured successfully")
    }
    
    /// Handle app entering background
    func handleAppBackground() {
        // Audio session automatically continues in background
        // due to background mode configuration
        print("📱 App entering background - audio will continue")
    }
    
    /// Handle app entering foreground
    func handleAppForeground() async {
        await audioSessionService?.ensureActive()
        print("📱 App entering foreground - audio session reactivated")
    }
    
    /// Handle audio interruption
    func handleInterruption(type: AVAudioSession.InterruptionType, options: AVAudioSession.InterruptionOptions) {
        switch type {
        case .began:
            print("🔇 Audio interruption began")
            // Playback automatically pauses
            
        case .ended:
            if options.contains(.shouldResume) {
                print("🔊 Audio interruption ended - should resume")
                // ViewModels will handle resume logic
            } else {
                print("🔊 Audio interruption ended - should not resume")
            }
            
        @unknown default:
            break
        }
    }
    
    /// Handle route change
    func handleRouteChange(reason: AVAudioSession.RouteChangeReason) {
        switch reason {
        case .newDeviceAvailable:
            print("🎧 New audio device available")
            
        case .oldDeviceUnavailable:
            print("🎧 Audio device disconnected")
            // Playback will pause automatically
            
        case .categoryChange:
            print("🎵 Audio category changed")
            
        default:
            break
        }
    }
    
    /// Clean up audio environment
    func teardownAudioEnvironment() async {
        // Audio session cleanup is handled automatically
        isConfigured = false
        print("✅ Audio environment cleaned up")
    }
    
    // MARK: - Private Methods
    
    private func setupRemoteCommands() {
        // Setup command handlers to post notifications
        remoteCommandService?.onPlayCommand = { [weak self] in
            guard self != nil else { return }
            await MainActor.run {
                NotificationCenter.default.post(name: .remoteCommandPlay, object: nil)
            }
        }
        
        remoteCommandService?.onPauseCommand = { [weak self] in
            guard self != nil else { return }
            await MainActor.run {
                NotificationCenter.default.post(name: .remoteCommandPause, object: nil)
            }
        }
        
        remoteCommandService?.onToggleCommand = { [weak self] in
            guard self != nil else { return }
            NotificationCenter.default.post(name: .remoteCommandPlayPause, object: nil)
        }
    }
}

// MARK: - Error Types

enum AudioEnvironmentError: Error {
    case setupFailed(Error)
    case activationFailed
    case deactivationFailed
}

// MARK: - Notification Names

extension Notification.Name {
    static let remoteCommandPlayPause = Notification.Name("remoteCommandPlayPause")
    static let remoteCommandPlay = Notification.Name("remoteCommandPlay")
    static let remoteCommandPause = Notification.Name("remoteCommandPause")
    static let remoteCommandStop = Notification.Name("remoteCommandStop")
}

// MARK: - Audio Environment Manager (Singleton)

@MainActor
final class AudioEnvironmentManager {
    static let shared = AudioEnvironmentManager()
    
    private var facade: AudioSessionFacade?
    
    private init() {
        setupNotificationObservers()
    }
    
    private func ensureFacade() async -> AudioSessionFacade {
        if let facade = facade {
            return facade
        }
        let newFacade = AudioSessionFacade()
        self.facade = newFacade
        return newFacade
    }
    
    func setup() async throws {
        let facade = await ensureFacade()
        try await facade.setupAudioEnvironment()
    }
    
    func teardown() async {
        guard let facade = facade else { return }
        await facade.teardownAudioEnvironment()
    }
    
    private func setupNotificationObservers() {
        // App lifecycle
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        // Audio session
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
    }
    
    @objc private func handleAppBackground() {
        facade?.handleAppBackground()
    }
    
    @objc private func handleAppForeground() {
        Task {
            if let facade = facade {
                await facade.handleAppForeground()
            }
        }
    }
    
    @objc private func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        let options = (userInfo[AVAudioSessionInterruptionOptionKey] as? UInt)
            .flatMap { AVAudioSession.InterruptionOptions(rawValue: $0) } ?? []
        
        facade?.handleInterruption(type: type, options: options)
    }
    
    @objc private func handleRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        facade?.handleRouteChange(reason: reason)
    }
}