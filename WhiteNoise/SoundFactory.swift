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
                guard let savedSoundData = UserDefaults.standard.data(forKey: String($0.id)) else {
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
                id: 0,
                name: "Rain falling in forest with occasional birds",
                fileName: "Rain falling in forest with occasional birds",
                volume: 0.3,
                isActive: true
            ),
            Sound(
                id: 1,
                name: "Medium light constant rain with a rumble of thunder",
                fileName: "Medium light constant rain with a rumble of thunder",
                volume: 0.3,
                isActive: false
            ),
            Sound(
                id: 2,
                name: "Medium heavy constant rain with some thunder rumbles",
                fileName: "Medium heavy constant rain with some thunder rumbles",
                volume: 0.3,
                isActive: false
            ),
            Sound(
                id: 3,
                name: "Medium heavy constant rain with drips",
                fileName: "Medium heavy constant rain with drips",
                volume: 0.3,
                isActive: false
            ),
            Sound(
                id: 4,
                name: "Springtime rain and thunder and lightning",
                fileName: "Springtime rain and thunder and lightning",
                volume: 0.3,
                isActive: false
            ),
            Sound(
                id: 5,
                name: "Gentle ocean waves on sandy beach, distant surf, low tide, winter",
                fileName: "Gentle ocean waves on sandy beach, distant surf, low tide, winter",
                volume: 0.3,
                isActive: false
            ),
            Sound(
                id: 6,
                name: "Mediterranean sea, calm ocean waves splashing on rocks pebbles and sand",
                fileName: "Mediterranean sea, calm ocean waves splashing on rocks pebbles and sand",
                volume: 0.3,
                isActive: false
            ),
            Sound(
                id: 7,
                name: "Small cascading waterfall, water trickle between rocks",
                fileName: "Small cascading waterfall, water trickle between rocks",
                volume: 0.3,
                isActive: false
            ),
            Sound(
                id: 8,
                name: "River or stream, water flowing, running",
                fileName: "River or stream, water flowing, running",
                volume: 0.3,
                isActive: false
            ),
            Sound(
                id: 9,
                name: "River, French Alps, Binaural, Close perspective, Water, Flow, Mountain, Forest",
                fileName: "River, French Alps, Binaural, Close perspective, Water, Flow, Mountain, Forest",
                volume: 0.3,
                isActive: false
            ),
            Sound(
                id: 10,
                name: "Summer forest loop, insects, birds",
                fileName: "Summer forest loop, insects, birds",
                volume: 0.3,
                isActive: false
            ),
            Sound(
                id: 11,
                name: "Designed forest, woodland ambience loop, several birds including the American goldfinch",
                fileName: "Designed forest, woodland ambience loop, several birds including the American goldfinch",
                volume: 0.3,
                isActive: false
            )
        ]
    }

}
