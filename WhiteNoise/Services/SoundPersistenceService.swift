//
//  SoundPersistenceService.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 06.08.2025.
//

import Foundation

protocol SoundPersistenceServiceProtocol {
    func save(_ sound: Sound)
    func load(soundId: UUID) -> Sound?
    func load(soundId: String) -> Sound? // Legacy support
}

final class SoundPersistenceService: SoundPersistenceServiceProtocol {
    private let userDefaults = UserDefaults.standard
    
    private enum Keys {
        static func sound(_ id: String) -> String { "sound_\(id)" }
        static func sound(_ id: UUID) -> String { "sound_\(id.uuidString)" }
    }
    
    func save(_ sound: Sound) {
        do {
            let soundData = try JSONEncoder().encode(sound)
            userDefaults.set(soundData, forKey: Keys.sound(sound.id))
        } catch {
            SentryManager.logPersistenceError(error, operation: "save_sound_\(sound.name)")
            print("Failed to save sound: \(error)")
        }
    }
    
    func load(soundId: UUID) -> Sound? {
        guard let data = userDefaults.data(forKey: Keys.sound(soundId)) else {
            return nil
        }
        
        do {
            return try JSONDecoder().decode(Sound.self, from: data)
        } catch {
            SentryManager.logPersistenceError(error, operation: "load_sound_by_uuid")
            print("Failed to load sound: \(error)")
            return nil
        }
    }
    
    // Legacy support for string IDs
    func load(soundId: String) -> Sound? {
        guard let data = userDefaults.data(forKey: Keys.sound(soundId)) else {
            return nil
        }
        
        do {
            return try JSONDecoder().decode(Sound.self, from: data)
        } catch {
            SentryManager.logPersistenceError(error, operation: "load_sound_by_string_legacy")
            print("Failed to load sound: \(error)")
            return nil
        }
    }
}