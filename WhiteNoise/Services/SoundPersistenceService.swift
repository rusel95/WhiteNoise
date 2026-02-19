//
//  SoundPersistenceService.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 06.08.2025.
//

import Foundation

@MainActor
protocol SoundPersistenceServiceProtocol {
    func save(_ sound: Sound)
    func load(soundId: String) -> Sound?
    func loadUserPreferences(soundId: String) -> (volume: Float?, selectedVariant: String?)
    func clearAll()
}

// CONCURRENCY FIX: Ensure thread-safe UserDefaults access
@MainActor
final class SoundPersistenceService: SoundPersistenceServiceProtocol {
    private let userDefaults = UserDefaults.standard
    
    private enum Keys {
        static func sound(_ id: String) -> String { "sound_\(id)" }
    }
    
    func save(_ sound: Sound) {
        do {
            let soundData = try JSONEncoder().encode(sound)
            userDefaults.set(soundData, forKey: Keys.sound(sound.id))
        } catch {
            print("Failed to save sound: \(error)")
            TelemetryService.captureNonFatal(
                error: error,
                message: "SoundPersistenceService failed to encode sound",
                extra: [
                    "soundId": sound.id
                ]
            )
        }
    }
    
    func load(soundId: String) -> Sound? {
        guard let data = userDefaults.data(forKey: Keys.sound(soundId)) else {
            return nil
        }
        
        do {
            return try JSONDecoder().decode(Sound.self, from: data)
        } catch {
            print("Failed to load sound: \(error)")
            TelemetryService.captureNonFatal(
                error: error,
                message: "SoundPersistenceService failed to decode sound",
                extra: [
                    "soundId": soundId
                ]
            )
            return nil
        }
    }
    
    /// Loads only user preferences (volume, selected variant) for migration purposes
    func loadUserPreferences(soundId: String) -> (volume: Float?, selectedVariant: String?) {
        guard let data = userDefaults.data(forKey: Keys.sound(soundId)),
              let sound = try? JSONDecoder().decode(Sound.self, from: data) else {
            return (nil, nil)
        }
        
        let selectedVariantName = sound.selectedSoundVariant.name
        return (sound.volume, selectedVariantName)
    }
    
    func clearAll() {
        let allKeys = userDefaults.dictionaryRepresentation().keys
        let soundKeys = allKeys.filter { $0.hasPrefix("sound_") }
        
        for key in soundKeys {
            userDefaults.removeObject(forKey: key)
        }
        
        print("🧹 Cleared \(soundKeys.count) cached sounds from UserDefaults")
    }
}
