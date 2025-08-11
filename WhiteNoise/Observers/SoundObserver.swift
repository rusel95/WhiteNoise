//
//  SoundObserver.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 2025-08-11.
//

import Foundation
import Combine

// MARK: - Observer Protocol

protocol SoundObserver: AnyObject {
    var id: String { get }
    func soundStateChanged(_ notification: SoundStateNotification)
    func soundVolumeChanged(_ notification: SoundVolumeNotification)
    func soundVariantChanged(_ notification: SoundVariantNotification)
}

// MARK: - Notification Types

struct SoundStateNotification {
    let soundId: String
    let soundName: String
    let previousState: String
    let newState: String
    let timestamp: Date
}

struct SoundVolumeNotification {
    let soundId: String
    let soundName: String
    let previousVolume: Float
    let newVolume: Float
    let timestamp: Date
}

struct SoundVariantNotification {
    let soundId: String
    let soundName: String
    let previousVariant: String
    let newVariant: String
    let timestamp: Date
}

// MARK: - Observable Protocol

protocol SoundObservable: AnyObject {
    func addObserver(_ observer: SoundObserver)
    func removeObserver(_ observer: SoundObserver)
    func notifyStateChange(from oldState: String, to newState: String)
    func notifyVolumeChange(from oldVolume: Float, to newVolume: Float)
    func notifyVariantChange(from oldVariant: String, to newVariant: String)
}

// MARK: - Observer Manager

@MainActor
final class SoundObserverManager: @preconcurrency SoundObservable {
    private var observers: [String: SoundObserver] = [:]
    private let soundId: String
    private let soundName: String
    
    init(soundId: String, soundName: String) {
        self.soundId = soundId
        self.soundName = soundName
    }
    
    func addObserver(_ observer: SoundObserver) {
        observers[observer.id] = observer
    }
    
    func removeObserver(_ observer: SoundObserver) {
        observers.removeValue(forKey: observer.id)
    }
    
    func notifyStateChange(from oldState: String, to newState: String) {
        let notification = SoundStateNotification(
            soundId: soundId,
            soundName: soundName,
            previousState: oldState,
            newState: newState,
            timestamp: Date()
        )
        
        observers.values.forEach { observer in
            observer.soundStateChanged(notification)
        }
    }
    
    func notifyVolumeChange(from oldVolume: Float, to newVolume: Float) {
        let notification = SoundVolumeNotification(
            soundId: soundId,
            soundName: soundName,
            previousVolume: oldVolume,
            newVolume: newVolume,
            timestamp: Date()
        )
        
        observers.values.forEach { observer in
            observer.soundVolumeChanged(notification)
        }
    }
    
    func notifyVariantChange(from oldVariant: String, to newVariant: String) {
        let notification = SoundVariantNotification(
            soundId: soundId,
            soundName: soundName,
            previousVariant: oldVariant,
            newVariant: newVariant,
            timestamp: Date()
        )
        
        observers.values.forEach { observer in
            observer.soundVariantChanged(notification)
        }
    }
}

// MARK: - Concrete Observers

@MainActor
final class LoggingObserver: @preconcurrency SoundObserver {
    let id: String = UUID().uuidString
    
    func soundStateChanged(_ notification: SoundStateNotification) {
        print("📊 [\(notification.timestamp)] Sound '\(notification.soundName)' state changed: \(notification.previousState) → \(notification.newState)")
    }
    
    func soundVolumeChanged(_ notification: SoundVolumeNotification) {
        print("🔊 [\(notification.timestamp)] Sound '\(notification.soundName)' volume changed: \(notification.previousVolume) → \(notification.newVolume)")
    }
    
    func soundVariantChanged(_ notification: SoundVariantNotification) {
        print("🎵 [\(notification.timestamp)] Sound '\(notification.soundName)' variant changed: \(notification.previousVariant) → \(notification.newVariant)")
    }
}

@MainActor
final class AnalyticsObserver: @preconcurrency SoundObserver {
    let id: String = UUID().uuidString
    
    func soundStateChanged(_ notification: SoundStateNotification) {
        // Track state changes for analytics
        trackEvent("sound_state_changed", parameters: [
            "sound_id": notification.soundId,
            "sound_name": notification.soundName,
            "from_state": notification.previousState,
            "to_state": notification.newState
        ])
    }
    
    func soundVolumeChanged(_ notification: SoundVolumeNotification) {
        // Track volume changes for analytics
        trackEvent("sound_volume_changed", parameters: [
            "sound_id": notification.soundId,
            "sound_name": notification.soundName,
            "from_volume": notification.previousVolume,
            "to_volume": notification.newVolume
        ])
    }
    
    func soundVariantChanged(_ notification: SoundVariantNotification) {
        // Track variant changes for analytics
        trackEvent("sound_variant_changed", parameters: [
            "sound_id": notification.soundId,
            "sound_name": notification.soundName,
            "from_variant": notification.previousVariant,
            "to_variant": notification.newVariant
        ])
    }
    
    private func trackEvent(_ eventName: String, parameters: [String: Any]) {
        // Placeholder for analytics tracking
        print("📈 Analytics Event: \(eventName) - \(parameters)")
    }
}

// MARK: - Event Bus (Alternative Implementation)

@MainActor
final class SoundEventBus {
    static let shared = SoundEventBus()
    
    private let stateChangeSubject = PassthroughSubject<SoundStateNotification, Never>()
    private let volumeChangeSubject = PassthroughSubject<SoundVolumeNotification, Never>()
    private let variantChangeSubject = PassthroughSubject<SoundVariantNotification, Never>()
    
    var stateChangePublisher: AnyPublisher<SoundStateNotification, Never> {
        stateChangeSubject.eraseToAnyPublisher()
    }
    
    var volumeChangePublisher: AnyPublisher<SoundVolumeNotification, Never> {
        volumeChangeSubject.eraseToAnyPublisher()
    }
    
    var variantChangePublisher: AnyPublisher<SoundVariantNotification, Never> {
        variantChangeSubject.eraseToAnyPublisher()
    }
    
    private init() {}
    
    func publishStateChange(_ notification: SoundStateNotification) {
        stateChangeSubject.send(notification)
    }
    
    func publishVolumeChange(_ notification: SoundVolumeNotification) {
        volumeChangeSubject.send(notification)
    }
    
    func publishVariantChange(_ notification: SoundVariantNotification) {
        variantChangeSubject.send(notification)
    }
}