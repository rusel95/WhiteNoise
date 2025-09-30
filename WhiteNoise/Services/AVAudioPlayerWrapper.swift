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
        // Try multiple audio formats in order of preference
        // Note: FLAC is not supported by AVAudioPlayer on iOS
        let supportedFormats = ["m4a", "wav", "aac", "mp3", "aiff", "caf"]
        var url: URL?
        
        for format in supportedFormats {
            url = Bundle.main.url(forResource: filename, withExtension: format)
            if url != nil {
                print("🎵 Found audio file: \(filename).\(format)")
                break
            } else {
                print("⚠️ Not found: \(filename).\(format)")
            }
        }
        
        guard let audioURL = url else {
            print("❌ No audio file found for: \(filename) in formats: \(supportedFormats)")
            TelemetryService.captureNonFatal(
                message: "AVAudioPlayerFactory missing audio asset",
                level: .error,
                extra: [
                    "filename": filename,
                    "attemptedExtensions": supportedFormats.joined(separator: ",")
                ]
            )
            throw AudioError.fileNotFound(filename)
        }
        
        let player = try await Task.detached(priority: .userInitiated) {
            let avPlayer = try AVAudioPlayer(contentsOf: audioURL)
            avPlayer.prepareToPlay()
            return avPlayer
        }.value
        
        return AVAudioPlayerWrapper(player: player)
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
