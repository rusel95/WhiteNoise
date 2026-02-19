//
//  SoundFactoryProtocol.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 2025-08-03.
//

import Foundation

@MainActor
protocol SoundFactoryProtocol {
    func getSavedSounds() -> [Sound]
}
