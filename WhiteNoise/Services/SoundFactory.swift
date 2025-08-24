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
        
        // Apply user preferences migration to each sound
        return sounds.map { sound in
            let (savedVolume, savedVariantName) = persistenceService.loadUserPreferences(soundId: sound.id)
            
            // Use saved volume or default to 0.0 if no preference
            let finalVolume = savedVolume ?? 0.0
            
            // Find matching variant or use first available
            let finalVariant: Sound.SoundVariant?
            if let savedVariantName = savedVariantName,
               let matchingVariant = sound.soundVariants.first(where: { $0.name == savedVariantName }) {
                finalVariant = matchingVariant
                print("✅ Migrated \(sound.name): volume=\(finalVolume), variant=\(matchingVariant.name)")
            } else if !sound.soundVariants.isEmpty {
                finalVariant = sound.soundVariants.first
                let variantName = finalVariant?.name ?? "none"
                print("🔄 Migrated \(sound.name): volume=\(finalVolume), variant=\(variantName) (default)")
            } else {
                finalVariant = nil
                print("⚠️ Migrated \(sound.name): volume=\(finalVolume), no variants available")
            }
            
            return Sound(
                name: sound.name,
                icon: sound.icon,
                volume: finalVolume,
                selectedSoundVariant: finalVariant,
                soundVariants: sound.soundVariants
            )
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
        
        // Apply user preferences migration to each sound
        return sounds.map { sound in
            let (savedVolume, savedVariantName) = persistenceService.loadUserPreferences(soundId: sound.id)
            
            // Use saved volume or default to 0.0 if no preference
            let finalVolume = savedVolume ?? 0.0
            
            // Find matching variant or use first available
            let finalVariant: Sound.SoundVariant?
            if let savedVariantName = savedVariantName,
               let matchingVariant = sound.soundVariants.first(where: { $0.name == savedVariantName }) {
                finalVariant = matchingVariant
                print("✅ Enhanced migrated \(sound.name): volume=\(finalVolume), variant=\(matchingVariant.name)")
            } else if !sound.soundVariants.isEmpty {
                finalVariant = sound.soundVariants.first
                let variantName = finalVariant?.name ?? "none"
                print("🔄 Enhanced migrated \(sound.name): volume=\(finalVolume), variant=\(variantName) (default)")
            } else {
                finalVariant = nil
                print("⚠️ Enhanced migrated \(sound.name): volume=\(finalVolume), no variants available")
            }
            
            return Sound(
                name: sound.name,
                icon: sound.icon,
                volume: finalVolume,
                selectedSoundVariant: finalVariant,
                soundVariants: sound.soundVariants
            )
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
