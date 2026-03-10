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

// MARK: - Preview Paywall Presenter

@Observable @MainActor
final class PreviewPaywallPresenter: PaywallPresenting {
    let hasFreeTrial: Bool
    let priceText: String?
    let monthlyPriceText: String?
    let trialText: String?
    let ctaText: String
    let legalText: String?
    var isBusy: Bool { false }
    var isReady: Bool { true }
    var errorMessage: String?

    init(
        hasFreeTrial: Bool = true,
        priceText: String? = "$24.99 / 3 months",
        monthlyPriceText: String? = "$8.33/mo",
        trialText: String? = "Includes 1 week free trial",
        ctaText: String = "Start trial – then $24.99/3 months",
        legalText: String? = "Auto-renews every 3 months unless cancelled at least 24h before the period ends. Billed to your Apple ID. Manage in Settings."
    ) {
        self.hasFreeTrial = hasFreeTrial
        self.priceText = priceText
        self.monthlyPriceText = monthlyPriceText
        self.trialText = trialText
        self.ctaText = ctaText
        self.legalText = legalText
    }

    func purchase() async {}
    func restore() async {}
    func dismissPaywall() {}
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
