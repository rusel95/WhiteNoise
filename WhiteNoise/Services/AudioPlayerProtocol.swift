//
//  AudioPlayerProtocol.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 2025-08-03.
//

import Foundation

@MainActor
protocol AudioPlayerProtocol: AnyObject {
    var isPlaying: Bool { get }
    var volume: Float { get set }
    var duration: TimeInterval { get }

    func prepareToPlay() async throws
    func play() -> Bool
    func pause()
    func stop()
}

@MainActor
protocol AudioPlayerFactoryProtocol {
    func createPlayer(for filename: String) async throws -> AudioPlayerProtocol
}