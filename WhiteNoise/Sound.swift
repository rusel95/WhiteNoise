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
        let iconName: String
        let filename: String
        
        init(id: UUID = UUID(), name: String, iconName: String = "snow", filename: String) {
            self.id = id
            self.name = name
            self.iconName = iconName
            self.filename = filename
        }
        
        static func == (lhs: SoundVariant, rhs: SoundVariant) -> Bool {
            return lhs.id == rhs.id
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
    
    var id: String {
        name
    }
    
    let name: String
    var volume: Double
    var isActive: Bool
    var selectedSoundVariant: SoundVariant
    let soundVariants: [SoundVariant]

    init(
        name: String,
        volume: Double = 0.0,
        isActive: Bool,
        selectedSoundVariant: SoundVariant?,
        soundVariants: [SoundVariant]
    ) {
        self.name = name
        self.volume = volume
        self.isActive = isActive
        self.selectedSoundVariant = selectedSoundVariant ?? soundVariants.first!
        self.soundVariants = soundVariants
    }
    
}
