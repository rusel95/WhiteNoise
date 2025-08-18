//
//  AVAudioPlayerWrapper.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 2025-08-03.
//

import AVFoundation

/// Wrapper for AVAudioPlayer that conforms to AudioPlayerProtocol
class AVAudioPlayerWrapper: AudioPlayerProtocol {
    private let player: AVAudioPlayer
    
    init(player: AVAudioPlayer) {
        self.player = player
        self.player.numberOfLoops = AppConstants.Audio.loopForever
    }
    
    var isPlaying: Bool {
        player.isPlaying
    }
    
    var volume: Float {
        get { player.volume }
        set { player.volume = newValue }
    }
    
    var duration: TimeInterval {
        player.duration
    }
    
    func prepareToPlay() async throws {
        player.prepareToPlay()
    }
    
    func play() -> Bool {
        player.play()
    }
    
    func pause() {
        player.pause()
    }
    
    func stop() {
        player.stop()
    }
}

/// Factory for creating AVAudioPlayer instances
class AVAudioPlayerFactory: AudioPlayerFactoryProtocol {
    func createPlayer(for filename: String) async throws -> AudioPlayerProtocol {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "mp3") else {
            let error = AudioError.fileNotFound(filename)
            SentryManager.logAudioError(error, operation: "create_player_file_not_found")
            throw error
        }
        
        do {
            let player = try await Task.detached(priority: .userInitiated) {
                let avPlayer = try AVAudioPlayer(contentsOf: url)
                avPlayer.prepareToPlay()
                return avPlayer
            }.value
            
            return AVAudioPlayerWrapper(player: player)
        } catch {
            SentryManager.logAudioError(error, operation: "create_audio_player_\(filename)")
            throw error
        }
    }
}

enum AudioError: LocalizedError {
    case fileNotFound(String)
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound(let filename):
            return "Unable to find sound file: \(filename)"
        }
    }
}