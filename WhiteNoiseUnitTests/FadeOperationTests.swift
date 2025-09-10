//
//  FadeOperationTests.swift
//  WhiteNoiseUnitTests
//
//  Tests FadeOperation using a lightweight AudioPlayerProtocol stub.
//

import XCTest
@testable import WhiteNoise

private final class StubPlayer: AudioPlayerProtocol {
    var isPlaying: Bool = false
    var volume: Float = 0
    var duration: TimeInterval = 60

    func prepareToPlay() async throws {}
    func play() -> Bool { isPlaying = true; return true }
    func pause() { isPlaying = false }
    func stop() { isPlaying = false }
}

final class FadeOperationTests: XCTestCase {
    func testFadeInAndOut() async throws {
        let op = await MainActor.run { FadeOperation(fadeType: .linear) }
        let player = StubPlayer()

        // Fade in to 1.0 over 0.2s
        await op.fadeIn(player: player, targetVolume: 1.0, duration: 0.2)
        XCTAssertTrue(player.isPlaying, "Player should be playing after fade in")
        XCTAssertEqual(player.volume, 1.0, accuracy: 0.05)

        // Fade out over 0.2s
        await op.fadeOut(player: player, duration: 0.2)
        XCTAssertFalse(player.isPlaying, "Player should be paused after fade out")
        XCTAssertEqual(player.volume, 0.0, accuracy: 0.05)
    }
}

