//
//  SoundFactory.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 01.06.2023.
//

import Foundation

class SoundFactory {

    static func getSavedSounds() -> [Sound] {
        createSounds()
            .map {
                guard let savedSoundData = UserDefaults.standard.data(forKey: $0.id) else {
                    return $0
                }

                do {
                    let sound = try JSONDecoder().decode(Sound.self, from: savedSoundData)
                    return sound
                } catch {
                    print("Failed to load sound: \(error)")
                    return $0
                }
            }


    }

    static func createSounds() -> [Sound] {
        return [
            Sound(
                name: "rain",
                icon: .system("cloud.rain"),
                isActive: true,
                selectedSoundVariant: nil,
                soundVariants: [
                    .init(name: "soft", filename: "soft rain"),
                    .init(name: "spring", filename: "spring rain"),
                    .init(name: "medium", filename: "rain medium"),
                    .init(name: "medium heavy", filename: "rain medium heavy falling trees forest")
                ]
            ),
            Sound(
                name: "fireplace",
                icon: .system("fireplace"),
                isActive: false,
                selectedSoundVariant: nil,
                soundVariants: [
                    .init(name: "crackle spit", filename: "fire crackle spit flames fireplace"),
                    .init(name: "burning crackle", filename: "fire burning crackle fireplace"),
                    .init(name: "spit crackle", filename: "fire in fireplace spit rumble crackle"),
                ]
            ),
            Sound(
                name: "thunder",
                icon: .system("cloud.bolt"),
                isActive: false,
                selectedSoundVariant: nil,
                soundVariants: [
                    .init(name: "distand low", filename: "thunder ssolated distant low rumble"),
                ]
            ),
            Sound(
                name: "sea",
                icon: .custom("sea"),
                isActive: false,
                selectedSoundVariant: nil,
                soundVariants: [
                    .init(name: "calm", filename: "Mediterranean sea, calm ocean waves splashing on rocks pebbles and sand"),
                ]
            ),
            Sound(
                name: "river",
                icon: .system("water.waves"),
                isActive: false,
                selectedSoundVariant: nil,
                soundVariants: [
                    .init(name: "regular", filename: "River or stream, water flowing, running"),
                    .init(name: "mountain", filename: "River, French Alps, Binaural, Close perspective, Water, Flow, Mountain, Forest")
                ]
            ),
            Sound(
                name: "waterfall",
                icon: .custom("waterfall"),
                isActive: false,
                selectedSoundVariant: nil,
                soundVariants: [
                    .init(name: "regular", filename: "Waterfall, medium close, people chatting, Bridal Falls, Canada")
                ]
            ),
            Sound(
                name: "forest",
                icon: .system("tree"),
                isActive: false,
                selectedSoundVariant: nil,
                soundVariants: [
                    .init(name: "summer", filename: "Summer forest insects and birds"),
                    .init(name: "ambiance", filename: "Woodland ambience & several birds")
                ]
            ),
        ]
    }

}
