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
    var volume: Double
    var isActive: Bool
    var selectedSoundVariant: SoundVariant
    let soundVariants: [SoundVariant]

    init(
        name: String,
        icon: Icon,
        volume: Double = 0.0,
        isActive: Bool,
        selectedSoundVariant: SoundVariant?,
        soundVariants: [SoundVariant]
    ) {
        self.name = name
        self.icon = icon
        self.volume = volume
        self.isActive = isActive
        self.selectedSoundVariant = selectedSoundVariant ?? soundVariants.first!
        self.soundVariants = soundVariants
    }
    
}
