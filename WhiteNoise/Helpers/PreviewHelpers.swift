//
//  PreviewHelpers.swift
//  WhiteNoise
//
//  Lightweight stubs for SwiftUI Previews — no audio, no network, no persistence.
//

#if DEBUG
import Foundation

// MARK: - No-Op Audio Player

@MainActor
struct NoOpAudioPlayerFactory: AudioPlayerFactoryProtocol {
    func createPlayer(for filename: String) async throws -> AudioPlayerProtocol {
        NoOpAudioPlayer()
    }
}

final class NoOpAudioPlayer: AudioPlayerProtocol {
    var isPlaying: Bool { false }
    var volume: Float = 0
    var duration: TimeInterval { 0 }
    func prepareToPlay() async throws {}
    @discardableResult func play() -> Bool { false }
    func pause() {}
    func stop() {}
}

// MARK: - No-Op Persistence

@MainActor
struct NoOpSoundPersistenceService: SoundPersistenceServiceProtocol {
    func save(_ sound: Sound) {}
    func load(soundId: String) -> Sound? { nil }
    func loadUserPreferences(soundId: String) -> (volume: Float?, selectedVariant: String?) { (nil, nil) }
    func clearAll() {}
}

// MARK: - Preview Sound

enum PreviewData {
    @MainActor
    static var sampleSound: Sound {
        let variant = Sound.SoundVariant(name: "Default", filename: "soft_rain.mp3")
        return try! Sound(name: "Soft Rain", icon: .system("cloud.rain.fill"), volume: 0.6, selectedSoundVariant: variant, soundVariants: [variant])
    }

    @MainActor
    static var sampleSoundViewModel: SoundViewModel {
        SoundViewModel(
            sound: sampleSound,
            playerFactory: NoOpAudioPlayerFactory(),
            persistenceService: NoOpSoundPersistenceService()
        )
    }
}
#endif
