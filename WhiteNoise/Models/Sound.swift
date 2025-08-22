//
//  Sound.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 30.05.2023.
//

import Foundation

class Sound: Codable, Identifiable {
    
    class SoundVariant: Codable, Identifiable, Hashable {
        
        let id: UUID
        let name: String
        let filename: String
        
        init(
            id: UUID = UUID(),
            name: String,
            filename: String
        ) {
            self.id = id
            self.name = name
            self.filename = filename
        }
        
        static func == (lhs: SoundVariant, rhs: SoundVariant) -> Bool {
            return lhs.id == rhs.id
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
    
    enum Icon: Codable {
        case system(String)
        case custom(String)
    }
    
    var id: String {
        name
    }
    
    let name: String
    let icon: Icon
    var volume: Float
    var selectedSoundVariant: SoundVariant
    let soundVariants: [SoundVariant]

    init(
        name: String,
        icon: Icon,
        volume: Float = 0.0,
        selectedSoundVariant: SoundVariant?,
        soundVariants: [SoundVariant]
    ) {
        guard !soundVariants.isEmpty else {
            fatalError("Sound must have at least one variant")
        }
        
        self.name = name
        self.icon = icon
        self.volume = volume
        if let selected = selectedSoundVariant {
            self.selectedSoundVariant = selected
        } else if let firstVariant = soundVariants.first {
            self.selectedSoundVariant = firstVariant
        } else {
            // This should never happen due to the guard above, but satisfies the compiler
            fatalError("Logic error: soundVariants was empty after validation")
        }
        self.soundVariants = soundVariants
    }
    
}
