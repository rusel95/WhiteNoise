//
//  AbstractSoundFactory.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 2025-08-11.
//

import Foundation

// MARK: - Abstract Factory Protocol

/// Protocol for creating sound-related objects
protocol AbstractSoundFactory {
    func createSound() -> Sound
    @MainActor func createSoundViewModel(sound: Sound) -> SoundViewModel
    func createAudioPlayer(for fileName: String) async throws -> AudioPlayerProtocol
    func getSoundCategory() -> SoundCategory
}

// MARK: - Sound Categories

/// Categories for organizing sounds - used for UI grouping and specialized behavior
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

// MARK: - Configuration-Driven Factory

/// Factory that creates sounds from configuration files only
final class ConfigurationDrivenSoundFactory: AbstractSoundFactory {
    private let playerFactory: AudioPlayerFactoryProtocol
    private let persistenceService: SoundPersistenceServiceProtocol
    private let category: SoundCategory
    
    init(
        category: SoundCategory,
        playerFactory: AudioPlayerFactoryProtocol = AVAudioPlayerFactory(),
        persistenceService: SoundPersistenceServiceProtocol = SoundPersistenceService()
    ) {
        self.category = category
        self.playerFactory = playerFactory
        self.persistenceService = persistenceService
    }
    
    func createSound() -> Sound {
        // This method is not used since we load from SoundConfiguration.json
        // Returning empty sound as placeholder
        return Sound(
            name: "Configuration Sound",
            icon: .system(category.icon),
            volume: 0.0,
            selectedSoundVariant: nil,
            soundVariants: []
        )
    }
    
    @MainActor func createSoundViewModel(sound: Sound) -> SoundViewModel {
        let fadeType: FadeType = {
            switch category {
            case .nature: return .logarithmic
            case .weather: return .exponential  
            case .ambient: return .sCurve
            case .whiteNoise: return .linear
            }
        }()
        
        return SoundViewModel(
            sound: sound,
            playerFactory: playerFactory,
            persistenceService: persistenceService,
            fadeType: fadeType
        )
    }
    
    func createAudioPlayer(for fileName: String) async throws -> AudioPlayerProtocol {
        try await playerFactory.createPlayer(for: fileName)
    }
    
    func getSoundCategory() -> SoundCategory {
        category
    }
}

// MARK: - Factory Provider

final class SoundFactoryProvider {
    static func getFactory(for category: SoundCategory) -> AbstractSoundFactory {
        ConfigurationDrivenSoundFactory(category: category)
    }
    
    static func getAllFactories() -> [AbstractSoundFactory] {
        SoundCategory.allCases.map { getFactory(for: $0) }
    }
}
