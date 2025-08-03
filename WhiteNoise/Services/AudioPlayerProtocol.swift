//
//  AudioPlayerProtocol.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 2025-08-03.
//

import Foundation

protocol AudioPlayerProtocol {
    var isPlaying: Bool { get }
    var volume: Float { get set }
    
    func prepareToPlay() async throws
    func play() -> Bool
    func pause()
    func stop()
}

protocol AudioPlayerFactoryProtocol {
    func createPlayer(for filename: String) async throws -> AudioPlayerProtocol
}