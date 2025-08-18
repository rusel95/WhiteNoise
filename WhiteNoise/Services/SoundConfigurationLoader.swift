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
            let error = AppError.fileNotFound("\(filename).\(fileExtension)")
            SentryManager.logConfigurationError(error, resource: "\(filename).\(fileExtension)")
            print("❌ Failed to find \(filename).\(fileExtension) in bundle")
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
                    Sound.SoundVariant(name: variantData.name, filename: variantData.filename)
                }
                
                do {
                    return try Sound.create(
                        name: soundData.name,
                        icon: icon,
                        volume: AppConstants.Audio.defaultVolume,
                        selectedSoundVariant: nil,
                        soundVariants: variants
                    )
                } catch {
                    SentryManager.logSoundCreationError(error, soundName: soundData.name)
                    print("⚠️ Failed to create sound '\(soundData.name)': \(error.localizedDescription)")
                    return nil
                }
            }
        } catch {
            SentryManager.logConfigurationError(error, resource: "\(filename).\(fileExtension)")
            print("❌ Failed to load sound configuration: \(error)")
            return createDefaultSounds()
        }
    }
    
    private func createDefaultSounds() -> [Sound] {
        // Fallback to a minimal set of sounds if configuration fails to load
        let sounds: [Sound?] = [
            try? Sound.create(
                name: "rain",
                icon: .system("cloud.rain"),
                volume: AppConstants.Audio.defaultVolume,
                selectedSoundVariant: nil,
                soundVariants: [
                    .init(name: "soft", filename: "soft rain")
                ]
            ),
            try? Sound.create(
                name: "fireplace",
                icon: .system("fireplace"),
                volume: AppConstants.Audio.defaultVolume,
                selectedSoundVariant: nil,
                soundVariants: [
                    .init(name: "crackle", filename: "fire crackle spit flames fireplace")
                ]
            )
        ]
        
        return sounds.compactMap { $0 }
    }
}