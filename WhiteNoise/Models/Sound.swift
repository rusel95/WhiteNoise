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
    
    let id: UUID
    let name: String
    let icon: Icon
    var volume: Float
    var selectedSoundVariant: SoundVariant
    let soundVariants: [SoundVariant]

    init?(
        id: UUID = UUID(),
        name: String,
        icon: Icon,
        volume: Float = 0.0,
        selectedSoundVariant: SoundVariant?,
        soundVariants: [SoundVariant]
    ) {
        guard !soundVariants.isEmpty else {
            print("❌ Sound initialization failed: soundVariants cannot be empty")
            return nil
        }
        
        self.id = id
        self.name = name
        self.icon = icon
        self.volume = volume
        
        if let selected = selectedSoundVariant {
            self.selectedSoundVariant = selected
        } else {
            self.selectedSoundVariant = soundVariants[0]
        }
        
        self.soundVariants = soundVariants
    }
    
    // Static factory method that throws an error for better error handling
    static func create(
        id: UUID = UUID(),
        name: String,
        icon: Icon,
        volume: Float = 0.0,
        selectedSoundVariant: SoundVariant?,
        soundVariants: [SoundVariant]
    ) throws -> Sound {
        guard !soundVariants.isEmpty else {
            throw AppError.invalidSoundConfiguration("Sound must have at least one variant")
        }
        
        guard let sound = Sound(
            id: id,
            name: name,
            icon: icon,
            volume: volume,
            selectedSoundVariant: selectedSoundVariant,
            soundVariants: soundVariants
        ) else {
            throw AppError.soundCreationFailure("Failed to create sound")
        }
        
        return sound
    }
    
}
