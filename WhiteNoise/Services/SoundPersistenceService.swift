//
//  SoundPersistenceService.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 06.08.2025.
//

import Foundation

protocol SoundPersistenceServiceProtocol {
    func save(_ sound: Sound)
    func load(soundId: String) -> Sound?
}

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
            return nil
        }
    }
}