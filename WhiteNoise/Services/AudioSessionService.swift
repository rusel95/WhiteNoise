//
//  AudioSessionService.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 2025-08-03.
//

import AVFoundation
import Combine

@MainActor
class AudioSessionService: ObservableObject {
    @Published private(set) var isInterrupted = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupAudioSession()
        setupInterruptionHandling()
    }
    
    func setupAudioSession() {
        #if os(iOS)
        do {
            print("🎵 Setting up audio session")
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            print("✅ Audio session activated successfully")
        } catch {
            print("❌ Failed to set audio session: \(error)")
        }
        #endif
    }
    
    func ensureActive() async {
        #if os(iOS)
        do {
            let session = AVAudioSession.sharedInstance()
            if !session.isOtherAudioPlaying {
                try session.setActive(true)
                print("✅ Audio session activated")
            }
        } catch {
            print("❌ Failed to activate audio session: \(error)")
        }
        #endif
    }
    
    func reconfigure() async {
        #if os(iOS)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
            print("✅ Audio session reconfigured")
        } catch {
            print("❌ Failed to reconfigure audio session: \(error)")
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
            break
        }
        #endif
    }
}