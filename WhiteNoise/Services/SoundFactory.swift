//
//  SoundFactory.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 01.06.2023.
//

import Foundation

// MARK: - Legacy Factory (For Backward Compatibility)

@MainActor
class SoundFactory: SoundFactoryProtocol {

    private let persistenceService: SoundPersistenceServiceProtocol = SoundPersistenceService()
    private let configurationLoader: SoundConfigurationLoaderProtocol = SoundConfigurationLoader()
    
    func getSavedSounds() -> [Sound] {
        let sounds = configurationLoader.loadSounds()

        // Apply user preferences migration to each sound
        return sounds.compactMap { sound in
            do {
                let (savedVolume, savedVariantName) = persistenceService.loadUserPreferences(soundId: sound.id)

                // Prefer persisted volume; otherwise honor the loader's default
                let finalVolume: Float
                if let savedVolume = savedVolume {
                    finalVolume = savedVolume
                } else {
                    finalVolume = sound.volume
                    print("🎚️ Using default volume for \(sound.name): volume=\(finalVolume))")
                }

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

                return try Sound(
                    name: sound.name,
                    icon: sound.icon,
                    volume: finalVolume,
                    selectedSoundVariant: finalVariant,
                    soundVariants: sound.soundVariants
                )
            } catch let error as Sound.SoundError {
                // Capture specific Sound validation errors
                TelemetryService.captureNonFatal(
                    error: error,
                    message: "SoundFactory.getSavedSounds - Failed to create Sound object",
                    level: .error,
                    extra: [
                        "soundName": sound.name,
                        "variantsCount": sound.soundVariants.count
                    ]
                )
                print("❌ SoundFactory - Failed to migrate \(sound.name): \(error.localizedDescription)")
                return nil
            } catch {
                // Capture unexpected errors
                TelemetryService.captureNonFatal(
                    error: error,
                    message: "SoundFactory.getSavedSounds - Unexpected error creating Sound",
                    level: .error,
                    extra: ["soundName": sound.name]
                )
                print("❌ SoundFactory - Unexpected error migrating \(sound.name): \(error)")
                return nil
            }
        }
    }
}
