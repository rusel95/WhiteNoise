//
//  AbstractSoundFactory.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 2025-08-11.
//

import Foundation

// MARK: - Abstract Factory Protocol

protocol AbstractSoundFactory {
    func createSound() -> Sound
    @MainActor func createSoundViewModel(sound: Sound) -> SoundViewModel
    func createAudioPlayer(for fileName: String) async throws -> AudioPlayerProtocol
    func getSoundCategory() -> SoundCategory
}

// MARK: - Sound Categories

enum SoundCategory: String, CaseIterable {
    case nature = "Nature"
    case weather = "Weather"
    case ambient = "Ambient"
    case whiteNoise = "White Noise"
    
    var icon: String {
        switch self {
        case .nature: return "leaf.fill"
        case .weather: return "cloud.rain.fill"
        case .ambient: return "flame.fill"
        case .whiteNoise: return "waveform"
        }
    }
}

// MARK: - Concrete Factories

final class NatureSoundFactory: AbstractSoundFactory {
    private let playerFactory: AudioPlayerFactoryProtocol
    private let persistenceService: SoundPersistenceServiceProtocol
    
    init(
        playerFactory: AudioPlayerFactoryProtocol = AVAudioPlayerFactory(),
        persistenceService: SoundPersistenceServiceProtocol = SoundPersistenceService()
    ) {
        self.playerFactory = playerFactory
        self.persistenceService = persistenceService
    }
    
    func createSound() -> Sound {
        // Create nature-specific sounds
        let variants = [
            Sound.SoundVariant(name: "Forest", filename: "forest"),
            Sound.SoundVariant(name: "Birds", filename: "birds"),
            Sound.SoundVariant(name: "Ocean Waves", filename: "ocean"),
            Sound.SoundVariant(name: "River Stream", filename: "river")
        ]
        
        return Sound(
            name: "Nature Sounds",
            icon: .system("leaf.fill"),
            volume: 0.5,
            selectedSoundVariant: variants[0],
            soundVariants: variants
        )
    }
    
    @MainActor func createSoundViewModel(sound: Sound) -> SoundViewModel {
        SoundViewModel(
            sound: sound,
            playerFactory: playerFactory,
            persistenceService: persistenceService,
            fadeType: .logarithmic // Nature sounds use logarithmic fade
        )
    }
    
    func createAudioPlayer(for fileName: String) async throws -> AudioPlayerProtocol {
        try await playerFactory.createPlayer(for: fileName)
    }
    
    func getSoundCategory() -> SoundCategory {
        .nature
    }
}

final class WeatherSoundFactory: AbstractSoundFactory {
    private let playerFactory: AudioPlayerFactoryProtocol
    private let persistenceService: SoundPersistenceServiceProtocol
    
    init(
        playerFactory: AudioPlayerFactoryProtocol = AVAudioPlayerFactory(),
        persistenceService: SoundPersistenceServiceProtocol = SoundPersistenceService()
    ) {
        self.playerFactory = playerFactory
        self.persistenceService = persistenceService
    }
    
    func createSound() -> Sound {
        let variants = [
            Sound.SoundVariant(name: "Soft Rain", filename: "soft-rain"),
            Sound.SoundVariant(name: "Heavy Rain", filename: "hard-rain"),
            Sound.SoundVariant(name: "Thunderstorm", filename: "thunder"),
            Sound.SoundVariant(name: "Snow", filename: "snow")
        ]
        
        return Sound(
            name: "Weather Sounds",
            icon: .system("cloud.rain.fill"),
            volume: 0.5,
            selectedSoundVariant: variants[0],
            soundVariants: variants
        )
    }
    
    @MainActor func createSoundViewModel(sound: Sound) -> SoundViewModel {
        SoundViewModel(
            sound: sound,
            playerFactory: playerFactory,
            persistenceService: persistenceService,
            fadeType: .exponential // Weather sounds use exponential fade
        )
    }
    
    func createAudioPlayer(for fileName: String) async throws -> AudioPlayerProtocol {
        try await playerFactory.createPlayer(for: fileName)
    }
    
    func getSoundCategory() -> SoundCategory {
        .weather
    }
}

final class AmbientSoundFactory: AbstractSoundFactory {
    private let playerFactory: AudioPlayerFactoryProtocol
    private let persistenceService: SoundPersistenceServiceProtocol
    
    init(
        playerFactory: AudioPlayerFactoryProtocol = AVAudioPlayerFactory(),
        persistenceService: SoundPersistenceServiceProtocol = SoundPersistenceService()
    ) {
        self.playerFactory = playerFactory
        self.persistenceService = persistenceService
    }
    
    func createSound() -> Sound {
        let variants = [
            Sound.SoundVariant(name: "Fireplace", filename: "fireplace"),
            Sound.SoundVariant(name: "Coffee Shop", filename: "coffee-shop"),
            Sound.SoundVariant(name: "Library", filename: "library"),
            Sound.SoundVariant(name: "Night City", filename: "city-night")
        ]
        
        return Sound(
            name: "Ambient Sounds",
            icon: .system("flame.fill"),
            volume: 0.5,
            selectedSoundVariant: variants[0],
            soundVariants: variants
        )
    }
    
    @MainActor func createSoundViewModel(sound: Sound) -> SoundViewModel {
        SoundViewModel(
            sound: sound,
            playerFactory: playerFactory,
            persistenceService: persistenceService,
            fadeType: .sCurve // Ambient sounds use S-curve fade
        )
    }
    
    func createAudioPlayer(for fileName: String) async throws -> AudioPlayerProtocol {
        try await playerFactory.createPlayer(for: fileName)
    }
    
    func getSoundCategory() -> SoundCategory {
        .ambient
    }
}

final class WhiteNoiseSoundFactory: AbstractSoundFactory {
    private let playerFactory: AudioPlayerFactoryProtocol
    private let persistenceService: SoundPersistenceServiceProtocol
    
    init(
        playerFactory: AudioPlayerFactoryProtocol = AVAudioPlayerFactory(),
        persistenceService: SoundPersistenceServiceProtocol = SoundPersistenceService()
    ) {
        self.playerFactory = playerFactory
        self.persistenceService = persistenceService
    }
    
    func createSound() -> Sound {
        let variants = [
            Sound.SoundVariant(name: "White Noise", filename: "white-noise"),
            Sound.SoundVariant(name: "Pink Noise", filename: "pink-noise"),
            Sound.SoundVariant(name: "Brown Noise", filename: "brown-noise"),
            Sound.SoundVariant(name: "Fan Noise", filename: "fan")
        ]
        
        return Sound(
            name: "White Noise",
            icon: .system("waveform"),
            volume: 0.5,
            selectedSoundVariant: variants[0],
            soundVariants: variants
        )
    }
    
    @MainActor func createSoundViewModel(sound: Sound) -> SoundViewModel {
        SoundViewModel(
            sound: sound,
            playerFactory: playerFactory,
            persistenceService: persistenceService,
            fadeType: .linear // White noise uses linear fade
        )
    }
    
    func createAudioPlayer(for fileName: String) async throws -> AudioPlayerProtocol {
        try await playerFactory.createPlayer(for: fileName)
    }
    
    func getSoundCategory() -> SoundCategory {
        .whiteNoise
    }
}

// MARK: - Factory Provider

final class SoundFactoryProvider {
    static func getFactory(for category: SoundCategory) -> AbstractSoundFactory {
        switch category {
        case .nature:
            return NatureSoundFactory()
        case .weather:
            return WeatherSoundFactory()
        case .ambient:
            return AmbientSoundFactory()
        case .whiteNoise:
            return WhiteNoiseSoundFactory()
        }
    }
    
    static func getAllFactories() -> [AbstractSoundFactory] {
        SoundCategory.allCases.map { getFactory(for: $0) }
    }
}