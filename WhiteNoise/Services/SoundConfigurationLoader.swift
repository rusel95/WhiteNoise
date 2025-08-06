//
//  SoundConfigurationLoader.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 06.08.2025.
//

import Foundation

protocol SoundConfigurationLoaderProtocol {
    func loadSounds() -> [Sound]
}

struct SoundConfiguration: Codable {
    struct SoundData: Codable {
        struct IconData: Codable {
            let type: String
            let value: String
        }
        
        struct VariantData: Codable {
            let name: String
            let filename: String
        }
        
        let name: String
        let icon: IconData
        let variants: [VariantData]
    }
    
    let sounds: [SoundData]
}

final class SoundConfigurationLoader: SoundConfigurationLoaderProtocol {
    
    private let filename = "SoundConfiguration"
    private let fileExtension = "json"
    
    func loadSounds() -> [Sound] {
        guard let url = Bundle.main.url(forResource: filename, withExtension: fileExtension) else {
            print("❌ Failed to find \(filename).\(fileExtension) in bundle")
            return createDefaultSounds()
        }
        
        do {
            let data = try Data(contentsOf: url)
            let configuration = try JSONDecoder().decode(SoundConfiguration.self, from: data)
            
            return configuration.sounds.map { soundData in
                let icon: Sound.Icon = soundData.icon.type == "system" ?
                    .system(soundData.icon.value) :
                    .custom(soundData.icon.value)
                
                let variants = soundData.variants.map { variantData in
                    Sound.SoundVariant(name: variantData.name, filename: variantData.filename)
                }
                
                return Sound(
                    name: soundData.name,
                    icon: icon,
                    volume: AppConstants.Audio.defaultVolume,
                    selectedSoundVariant: nil,
                    soundVariants: variants
                )
            }
        } catch {
            print("❌ Failed to load sound configuration: \(error)")
            return createDefaultSounds()
        }
    }
    
    private func createDefaultSounds() -> [Sound] {
        // Fallback to a minimal set of sounds if configuration fails to load
        return [
            Sound(
                name: "rain",
                icon: .system("cloud.rain"),
                volume: AppConstants.Audio.defaultVolume,
                selectedSoundVariant: nil,
                soundVariants: [
                    .init(name: "soft", filename: "soft rain")
                ]
            ),
            Sound(
                name: "fireplace",
                icon: .system("fireplace"),
                volume: AppConstants.Audio.defaultVolume,
                selectedSoundVariant: nil,
                soundVariants: [
                    .init(name: "crackle", filename: "fire crackle spit flames fireplace")
                ]
            )
        ]
    }
}