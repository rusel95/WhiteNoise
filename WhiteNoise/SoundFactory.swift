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
                name: "rain medium",
                fileName: "rain medium",
                volume: 0.3,
                isActive: false
            ),
            Sound(
                name: "rain medium heavy falling trees forest",
                fileName: "rain medium heavy falling trees forest",
                volume: 0.3,
                isActive: false
            ),
            Sound(
                name: "Springtime rain and thunder and lightning",
                fileName: "Springtime rain and thunder and lightning",
                volume: 0.3,
                isActive: false
            ),
            Sound(
                name: "Mediterranean sea, calm ocean waves splashing on rocks pebbles and sand",
                fileName: "Mediterranean sea, calm ocean waves splashing on rocks pebbles and sand",
                volume: 0.3,
                isActive: false
            ),
            Sound(
                name: "River or stream, water flowing, running",
                fileName: "River or stream, water flowing, running",
                volume: 0.3,
                isActive: false
            ),
            Sound(
                name: "River, French Alps, Binaural, Close perspective, Water, Flow, Mountain, Forest",
                fileName: "River, French Alps, Binaural, Close perspective, Water, Flow, Mountain, Forest",
                volume: 0.3,
                isActive: false
            ),
            Sound(
                name: "Summer forest insects and birds",
                fileName: "Summer forest insects and birds",
                volume: 0.3,
                isActive: false
            ),
            Sound(
                name: "Woodland ambience & several birds",
                fileName: "Woodland ambience & several birds",
                volume: 0.3,
                isActive: false
            )
        ]
    }

}
