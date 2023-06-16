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
                name: "soft rain",
                fileName: "soft rain",
                isActive: true
            ),
            Sound(
                name: "spring rain",
                fileName: "spring rain",
                isActive: false
            ),
            Sound(
                name: "rain medium",
                fileName: "rain medium",
                isActive: false
            ),
            Sound(
                name: "rain medium heavy falling trees forest",
                fileName: "rain medium heavy falling trees forest",
                isActive: false
            ),
            Sound(
                name: "Springtime rain and thunder and lightning",
                fileName: "Springtime rain and thunder and lightning",
                isActive: false
            ),
            Sound(
                name: "fire crackle spit flames fireplace",
                fileName: "fire crackle spit flames fireplace",
                isActive: false
            ),
            Sound(
                name: "fire burning crackle fireplace",
                fileName: "fire burning crackle fireplace",
                isActive: false
            ),
            Sound(
                name: "fire in fireplace spit rumble crackle",
                fileName: "fire in fireplace spit rumble crackle",
                isActive: false
            ),
            Sound(
                name: "thunder ssolated distant low rumble",
                fileName: "thunder ssolated distant low rumble",
                isActive: false
            ),
            Sound(
                name: "Mediterranean sea, calm ocean waves splashing on rocks pebbles and sand",
                fileName: "Mediterranean sea, calm ocean waves splashing on rocks pebbles and sand",
                isActive: false
            ),
            Sound(
                name: "River or stream, water flowing, running",
                fileName: "River or stream, water flowing, running",
                isActive: false
            ),
            Sound(
                name: "River, French Alps, Binaural, Close perspective, Water, Flow, Mountain, Forest",
                fileName: "River, French Alps, Binaural, Close perspective, Water, Flow, Mountain, Forest",
                isActive: false
            ),
            Sound(
                name: "Summer forest insects and birds",
                fileName: "Summer forest insects and birds",
                isActive: false
            ),
            Sound(
                name: "Woodland ambience & several birds",
                fileName: "Woodland ambience & several birds",
                isActive: false
            )
        ]
    }

}
