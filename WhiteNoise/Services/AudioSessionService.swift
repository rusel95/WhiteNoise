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
    @discardableResult func ensureActive() async -> Bool
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
    
    @discardableResult
    func ensureActive() async -> Bool {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        if session.isOtherAudioPlaying {
            return true
        }

        let maxRetries = 3
        for attempt in 1...maxRetries {
            do {
                try session.setActive(true)
                return true
            } catch {
                LoggingService.logWarning("Audio session activation attempt \(attempt)/\(maxRetries) failed: \(error.localizedDescription)")

                if attempt < maxRetries {
                    try? await Task.sleep(for: .milliseconds(100 * attempt))
                } else {
                    LoggingService.logError("Audio session activation failed after \(maxRetries) attempts")
                    TelemetryService.captureNonFatal(
                        error: error,
                        message: "AudioSessionService.ensureActive failed after \(maxRetries) retries"
                    )
                    return false
                }
            }
        }
        #endif
        return true
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
