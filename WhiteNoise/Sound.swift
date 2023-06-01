//
//  Sound.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 30.05.2023.
//

class Sound: Codable {

    let id: UInt32
    let name: String
    let fileName: String
    var volume: Double
    var isActive: Bool

    init(id: UInt32, name: String, fileName: String, volume: Double, isActive: Bool) {
        self.id = id
        self.name = name
        self.fileName = fileName
        self.volume = volume
        self.isActive = isActive
    }
    
}
