//
//  RemoteCommandService.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 2025-08-03.
//

import MediaPlayer

@MainActor
class RemoteCommandService {
    var onPlayCommand: (() async -> Void)?
    var onPauseCommand: (() async -> Void)?
    var onToggleCommand: (() -> Void)?
    
    init() {
        setupRemoteCommands()
    }
    
    private func setupRemoteCommands() {
        #if os(iOS)
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Play command
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            Task { @MainActor in
                await self.onPlayCommand?()
            }
            return .success
        }
        
        // Pause command
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            Task { @MainActor in
                await self.onPauseCommand?()
            }
            return .success
        }
        
        // Toggle play/pause command
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            Task { @MainActor in
                self.onToggleCommand?()
            }
            return .success
        }
        
        // Disable other commands
        commandCenter.nextTrackCommand.isEnabled = false
        commandCenter.previousTrackCommand.isEnabled = false
        commandCenter.changePlaybackRateCommand.isEnabled = false
        commandCenter.seekBackwardCommand.isEnabled = false
        commandCenter.seekForwardCommand.isEnabled = false
        commandCenter.skipBackwardCommand.isEnabled = false
        commandCenter.skipForwardCommand.isEnabled = false
        commandCenter.changePlaybackPositionCommand.isEnabled = false
        #endif
    }
    
    func updateNowPlayingInfo(title: String, isPlaying: Bool, timerInfo: (duration: Int, elapsed: Int)? = nil) {
        #if os(iOS)
        var nowPlayingInfo = [String: Any]()
        
        nowPlayingInfo[MPMediaItemPropertyTitle] = title
        nowPlayingInfo[MPMediaItemPropertyArtist] = "WhiteNoise App"
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = "Ambient Sounds"
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        
        // Add timer info if provided
        if let timerInfo = timerInfo {
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = Double(timerInfo.duration)
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = Double(timerInfo.elapsed)
        }
        
        // Use app icon for lock screen artwork
        if let image = UIImage(named: "LaunchScreenIcon") {
            let artwork = MPMediaItemArtwork(boundsSize: CGSize(width: 300, height: 300)) { size in
                let renderer = UIGraphicsImageRenderer(size: size)
                return renderer.image { _ in
                    image.draw(in: CGRect(origin: .zero, size: size))
                }
            }
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        #endif
    }
}