//
//  SoundFactory.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 01.06.2023.
//

import Foundation

// MARK: - Legacy Factory (For Backward Compatibility)

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

// MARK: - Enhanced Factory Using Abstract Factory Pattern

final class EnhancedSoundFactory: SoundFactoryProtocol {
    
    private let persistenceService: SoundPersistenceServiceProtocol
    private let configurationLoader: SoundConfigurationLoaderProtocol
    private let abstractFactories: [AbstractSoundFactory]
    
    init(
        persistenceService: SoundPersistenceServiceProtocol = SoundPersistenceService(),
        configurationLoader: SoundConfigurationLoaderProtocol = SoundConfigurationLoader()
    ) {
        self.persistenceService = persistenceService
        self.configurationLoader = configurationLoader
        self.abstractFactories = SoundFactoryProvider.getAllFactories()
    }
    
    func getSavedSounds() -> [Sound] {
        // Try loading from configuration first (backward compatibility)
        let configSounds = configurationLoader.loadSounds()
        
        // If no configuration sounds, create from abstract factories
        let sounds = configSounds.isEmpty ? createSoundsFromFactories() : configSounds
        
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
    
    func createSound(for category: SoundCategory) -> Sound {
        let factory = SoundFactoryProvider.getFactory(for: category)
        return factory.createSound()
    }
    
    @MainActor
    func createSoundViewModel(for sound: Sound, category: SoundCategory) -> SoundViewModel {
        let factory = SoundFactoryProvider.getFactory(for: category)
        return factory.createSoundViewModel(sound: sound)
    }
    
    private func createSoundsFromFactories() -> [Sound] {
        abstractFactories.map { $0.createSound() }
    }
}
