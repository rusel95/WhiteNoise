//
//  SoundFactoryProtocol.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 2025-08-03.
//

import Foundation

protocol SoundFactoryProtocol {
    func getSavedSounds() -> [Sound]
    func getSavedSoundsAsync() async -> [Sound]
}