//
//  Sound.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 30.05.2023.
//

class Sound: Codable {

    var id: String {
        fileName
    }
    
    let name: String
    let fileName: String
    var volume: Double
    var isActive: Bool

    init(name: String, fileName: String, volume: Double, isActive: Bool) {
        self.name = name
        self.fileName = fileName
        self.volume = volume
        self.isActive = isActive
    }
    
}
