//
//  SoundFactory.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 01.06.2023.
//

import Foundation

class SoundFactory {

    static func getSavedSounds() -> [Sound] {
        let sounds = createSounds()
        let userDefaults = UserDefaults.standard
        
        // Batch read all sound data to minimize UserDefaults access
        return sounds.map { sound in
            if let savedSoundData = userDefaults.data(forKey: sound.id) {
                do {
                    return try JSONDecoder().decode(Sound.self, from: savedSoundData)
                } catch {
                    print("Failed to load sound: \(error)")
                    return sound
                }
            }
            return sound
        }
    }
    
    @MainActor
    static func getSavedSoundsAsync() async -> [Sound] {
        await Task.detached(priority: .userInitiated) {
            getSavedSounds()
        }.value
    }

    static func createSounds() -> [Sound] {
        return [
            Sound(
                name: "rain",
                icon: .system("cloud.rain"),
                volume: 0.3,
                selectedSoundVariant: nil,
                soundVariants: [
                    .init(name: "soft", filename: "soft rain"),
                    .init(name: "spring", filename: "spring rain"),
                    .init(name: "medium", filename: "rain medium"),
                    .init(name: "medium heavy", filename: "rain medium heavy falling trees forest"),
                    .init(name: "raindrops on a car window", filename: "raindrops_on_a_car_window"),
                    .init(name: "raindrops on glass", filename: "soft_rain_on_window_glass_surface")
                ]
            ),
            Sound(
                name: "fireplace",
                icon: .system("fireplace"),
                volume: 0.8,
                selectedSoundVariant: nil,
                soundVariants: [
                    .init(name: "crackle spit", filename: "fire crackle spit flames fireplace"),
                    .init(name: "burning crackle", filename: "fire burning crackle fireplace"),
                    .init(name: "spit crackle", filename: "fire in fireplace spit rumble crackle"),
                ]
            ),
            Sound(
                name: "snow",
                icon: .system("snow"),
                selectedSoundVariant: nil,
                soundVariants: [
                    .init(name: "frozen tribal", filename: "frozen_tribal_organic_snow"),
                    .init(name: "blastwave blizzard", filename: "Blastwave_Blizzard"),
                    .init(name: "walk slow", filename: "walk_slow"),
                    .init(name: "snowball build", filename: "snowball_build"),
                    .init(name: "shovel clearing", filename: "shovel_clearing_snow"),
                    .init(name: "step scuff", filename: "STEP_Snow_Scuff"),
                    
                ]
            ),
            Sound(
                name: "thunder",
                icon: .system("cloud.bolt"),
                selectedSoundVariant: nil,
                soundVariants: [
                    .init(name: "distand low", filename: "thunder ssolated distant low rumble"),
                    .init(name: "isolated 1", filename: "isolated_001"),
                    .init(name: "isolated 2", filename: "isolated_002")
                ]
            ),
            Sound(
                name: "sea",
                icon: .custom("sea"),
                selectedSoundVariant: nil,
                soundVariants: [
                    .init(name: "calm", filename: "Mediterranean sea, calm ocean waves splashing on rocks pebbles and sand"),
                    .init(name: "close&distant", filename: "close&distant waves"),
                    .init(name: "strong waves", filename: "Beach Sea Waves"),
                    .init(name: "soft waves", filename: "west_wolf_Beach_Sea_Waves"),
                ]
            ),
            Sound(
                name: "river",
                icon: .system("water.waves"),
                selectedSoundVariant: nil,
                soundVariants: [
                    .init(name: "regular", filename: "River or stream, water flowing, running"),
                    .init(name: "mountain", filename: "River, French Alps, Binaural, Close perspective, Water, Flow, Mountain, Forest"),
                    .init(name: "flowing", filename: "flowing_water_loop_03_long"),
                    .init(name: "flowing 2", filename: "flowing_water_loop_06_long"),
                ]
            ),
            Sound(
                name: "waterfall",
                icon: .custom("waterfall"),
                selectedSoundVariant: nil,
                soundVariants: [
                    .init(name: "medium", filename: "Waterfall, medium close, people chatting, Bridal Falls, Canada"),
                    .init(name: "small", filename: "small_light_flow_creek_rainforest"),
                    .init(name: "distant", filename: "nature_creek_water_flow_against_rock_waterfall_in_distance_to_right"),
                    .init(name: "gentle", filename: "gentle_rainsforest_jungle_vietnam")
                ]
            ),
            Sound(
                name: "forest",
                icon: .system("tree"),
                selectedSoundVariant: nil,
                soundVariants: [
                    .init(name: "summer", filename: "Summer forest insects and birds"),
                    .init(name: "ambiance", filename: "Woodland ambience & several birds")
                ]
            ),
            Sound(
                name: "birds",
                icon: .system("bird"),
                selectedSoundVariant: nil,
                soundVariants: [
                    .init(name: "ducks", filename: "ducks"),
                    .init(name: "cocoo", filename: "cocoo"),
                    .init(name: "seagall", filename: "seagall"),
                    .init(name: "sparrow", filename: "sparrow"),
                    .init(name: "crickets", filename: "crickets")
                ]
            ),
            Sound(
                name: "voice",
                icon: .custom("voice-command"),
                selectedSoundVariant: nil,
                soundVariants: [
                    .init(name: "angels", filename: "among_the_stars"),
                    .init(name: "crowd in a room", filename: "HUMAN_CROWD_In_A_Room")
                ]
            ),
        ]
    }

}
