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
                isActive: true,
                selectedSoundVariant: nil,
                soundVariants: [
                    .init(filename: "soft rain"),
                    .init(filename: "spring rain"),
                    .init(filename: "rain medium"),
                    .init(filename: "rain medium heavy falling trees forest"),
                    .init(filename: "Springtime rain and thunder and lightning")
                ]
            ),
            Sound(
                name: "fireplace",
                isActive: false,
                selectedSoundVariant: nil,
                soundVariants: [
                    .init(filename: "fire crackle spit flames fireplace"),
                    .init(filename: "fire burning crackle fireplace"),
                    .init(filename: "fire in fireplace spit rumble crackle"),
                ]
            ),
            Sound(
                name: "thunder",
                isActive: false,
                selectedSoundVariant: nil,
                soundVariants: [
                    .init(filename: "thunder ssolated distant low rumble"),
                ]
            ),
            Sound(
                name: "sea",
                isActive: false,
                selectedSoundVariant: nil,
                soundVariants: [
                    .init(filename: "Mediterranean sea, calm ocean waves splashing on rocks pebbles and sand"),
                ]
            ),
            Sound(
                name: "river",
                isActive: false,
                selectedSoundVariant: nil,
                soundVariants: [
                    .init(filename: "River or stream, water flowing, running"),
                    .init(filename: "River, French Alps, Binaural, Close perspective, Water, Flow, Mountain, Forest")
                ]
            ),
            Sound(
                name: "forest",
                isActive: false,
                selectedSoundVariant: nil,
                soundVariants: [
                    .init(filename: "Summer forest insects and birds"),
                    .init(filename: "Woodland ambience & several birds")
                ]
            ),
        ]
    }

}
