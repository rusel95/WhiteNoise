//
//  SoundFactory.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 01.06.2023.
//

import Foundation

class SoundFactory: SoundFactoryProtocol {

    private let persistenceService: SoundPersistenceServiceProtocol = SoundPersistenceService()
    private let configurationLoader: SoundConfigurationLoaderProtocol = SoundConfigurationLoader()
    
    func getSavedSounds() -> [Sound] {
        let sounds = configurationLoader.loadSounds()
        
        // Load saved state for each sound
        return sounds.map { sound in
            if let savedSound = persistenceService.load(soundId: sound.id) {
                print("✅ Loaded saved state for \(sound.name): volume=\(savedSound.volume)")
                return savedSound
            } else {
                print("ℹ️ No saved state for \(sound.name), using default volume=\(sound.volume)")
                return sound
            }
        }
    }
    
    func getSavedSoundsAsync() async -> [Sound] {
        await Task.detached(priority: .userInitiated) { [weak self] in
            self?.getSavedSounds() ?? []
        }.value
    }
}
