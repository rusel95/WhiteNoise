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
                
                // Set specific default volumes for certain sounds
                let defaultVolume: Float = {
                    switch soundData.name.lowercased() {
                    case "rain":
                        print("🎵 SoundConfigurationLoader: Setting rain default volume to 70%")
                        return 0.7  // 70%
                    case "thunder":
                        print("🎵 SoundConfigurationLoader: Setting thunder default volume to 30%")
                        return 0.3  // 30%
                    case "birds":
                        print("🎵 SoundConfigurationLoader: Setting birds default volume to 20%")
                        return 0.2  // 20%
                    default:
                        return AppConstants.Audio.defaultVolume
                    }
                }()
                
                return Sound(
                    name: soundData.name,
                    icon: icon,
                    volume: defaultVolume,
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
                volume: 0.7,  // 70% default for rain
                selectedSoundVariant: nil,
                soundVariants: [
                    .init(name: "soft", filename: "soft rain")
                ]
            ),
            Sound(
                name: "thunder",
                icon: .system("cloud.bolt"),
                volume: 0.3,  // 30% default for thunder
                selectedSoundVariant: nil,
                soundVariants: [
                    .init(name: "distant", filename: "thunder distant")
                ]
            ),
            Sound(
                name: "birds",
                icon: .system("bird"),
                volume: 0.2,  // 20% default for birds
                selectedSoundVariant: nil,
                soundVariants: [
                    .init(name: "chirping", filename: "birds chirping")
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