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
            TelemetryService.captureNonFatal(
                message: "SoundConfigurationLoader missing configuration file",
                level: .error,
                extra: [
                    "filename": filename,
                    "extension": fileExtension
                ]
            )
            return createDefaultSounds()
        }
        
        do {
            let data = try Data(contentsOf: url)
            let configuration = try JSONDecoder().decode(SoundConfiguration.self, from: data)
            
            return configuration.sounds.compactMap { soundData in
                let icon: Sound.Icon = soundData.icon.type == "system" ?
                    .system(soundData.icon.value) :
                    .custom(soundData.icon.value)
                
                let variants = soundData.variants.map { variantData in
                    Sound.SoundVariant(name: String(localized: String.LocalizationValue(variantData.name)), filename: variantData.filename)
                }
                
                // Set specific default volumes for certain sounds
                let defaultVolume: Float = {
                    switch soundData.name.lowercased() {
                    case "rain":
                        print("🎵 SoundConfigurationLoader: Setting rain default volume to 70%")
                        return 0.7  // 70%
                    case "bonfire":
                        print("🎵 SoundConfigurationLoader: Setting birds default volume to 20%")
                        return 0.5  // 20%
                    case "thunderstorm":
                        print("🎵 SoundConfigurationLoader: Setting thunder default volume to 30%")
                        return 0.1  // 30%
                    default:
                        return AppConstants.Audio.defaultVolume
                    }
                }()
                
                // STABILITY FIX: Handle throwing Sound initializer
                do {
                    return try Sound(
                        name: String(localized: String.LocalizationValue(soundData.name)),
                        icon: icon,
                        volume: defaultVolume,
                        selectedSoundVariant: nil,
                        soundVariants: variants
                    )
                } catch {
                    TelemetryService.captureNonFatal(
                        error: error,
                        message: "SoundConfigurationLoader failed to create Sound object",
                        extra: ["soundName": soundData.name]
                    )
                    return nil  // Skip invalid sounds
                }
            }
        } catch {
            print("❌ Failed to load sound configuration: \(error)")
            TelemetryService.captureNonFatal(
                error: error,
                message: "SoundConfigurationLoader failed to decode configuration",
                extra: [
                    "filename": filename,
                    "extension": fileExtension
                ]
            )
            return createDefaultSounds()
        }
    }
    
    private func createDefaultSounds() -> [Sound] {
        // STABILITY FIX: Fallback to a minimal set of sounds if configuration fails to load
        // Handle throwing initializer safely
        let defaultSoundSpecs: [(String, Sound.Icon, Float, String, String)] = [
            ("rain", .system("cloud.rain"), 0.7, "soft", "soft rain"),
            ("thunder", .system("cloud.bolt"), 0.3, "distant", "thunder distant"),
            ("birds", .system("bird"), 0.2, "chirping", "birds chirping"),
            ("fireplace", .system("fireplace"), AppConstants.Audio.defaultVolume, "crackle", "fire crackle spit flames fireplace")
        ]

        return defaultSoundSpecs.compactMap { (name, icon, volume, variantName, filename) in
            do {
                return try Sound(
                    name: String(localized: String.LocalizationValue(name)),
                    icon: icon,
                    volume: volume,
                    selectedSoundVariant: nil,
                    soundVariants: [.init(name: String(localized: String.LocalizationValue(variantName)), filename: filename)]
                )
            } catch {
                TelemetryService.captureNonFatal(
                    error: error,
                    message: "Failed to create default sound",
                    extra: ["soundName": name]
                )
                return nil
            }
        }
    }
}
