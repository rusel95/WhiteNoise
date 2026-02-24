//
//  AudioSessionService.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 2025-08-03.
//

import AVFoundation
import Combine

// MARK: - Protocol

/// Protocol for managing audio session
@MainActor
protocol AudioSessionManaging: AnyObject {
    var isInterrupted: Bool { get }
    var onInterruptionChanged: ((Bool) -> Void)? { get set }
    func setupAudioSession()
    func ensureActive() async
    func reconfigure() async
}

@MainActor
class AudioSessionService: ObservableObject, AudioSessionManaging {
    @Published private(set) var isInterrupted = false {
        didSet { onInterruptionChanged?(isInterrupted) }
    }
    var onInterruptionChanged: ((Bool) -> Void)?

    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupAudioSession()
        setupInterruptionHandling()
    }
    
    func setupAudioSession() {
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            LoggingService.logError("Failed to set audio session: \(error.localizedDescription)")
            TelemetryService.captureNonFatal(
                error: error,
                message: "AudioSessionService.setupAudioSession failed"
            )
        }
        #endif
    }
    
    func ensureActive() async {
        #if os(iOS)
        do {
            let session = AVAudioSession.sharedInstance()
            if !session.isOtherAudioPlaying {
                try session.setActive(true)
            }
        } catch {
            LoggingService.logError("Failed to activate audio session: \(error.localizedDescription)")
            TelemetryService.captureNonFatal(
                error: error,
                message: "AudioSessionService.ensureActive failed"
            )
        }
        #endif
    }
    
    func reconfigure() async {
        #if os(iOS)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        } catch {
            LoggingService.logError("Failed to reconfigure audio session: \(error.localizedDescription)")
            TelemetryService.captureNonFatal(
                error: error,
                message: "AudioSessionService.reconfigure failed"
            )
        }
        #endif
    }
    
    private func setupInterruptionHandling() {
        #if os(iOS)
        NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)
            .sink { [weak self] notification in
                self?.handleInterruption(notification)
            }
            .store(in: &cancellables)
        #endif
    }
    
    private func handleInterruption(_ notification: Notification) {
        #if os(iOS)
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            TelemetryService.captureNonFatal(
                message: "AudioSessionService.handleInterruption missing interruption type",
                extra: ["userInfo": notification.userInfo ?? [:]]
            )
            return
        }
        
        switch type {
        case .began:
            isInterrupted = true
        case .ended:
            isInterrupted = false
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    Task {
                        await ensureActive()
                    }
                }
            }
        @unknown default:
            TelemetryService.captureNonFatal(
                message: "AudioSessionService.handleInterruption encountered unknown type",
                extra: ["rawValue": type.rawValue]
            )
            break
        }
        #endif
    }
}
