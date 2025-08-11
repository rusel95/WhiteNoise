//
//  RemoteCommandService.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 2025-08-03.
//

import MediaPlayer

// MARK: - Constants

private enum RemoteCommandConstants {
    static let appArtist = "WhiteNoise App"
    static let albumTitle = "Ambient Sounds"
    static let artworkSize = CGSize(width: 300, height: 300)
    static let defaultPlaybackRate: Double = 1.0
    static let pausedPlaybackRate: Double = 0.0
    static let appIconName = "LaunchScreenIcon"
}

// MARK: - Protocols

/// Represents the result of a remote command execution
enum RemoteCommandResult {
    case success
    case failed
}

/// Protocol for remote command center operations
protocol RemoteCommandCenterProtocol {
    func setupPlayCommand(handler: @escaping () async -> RemoteCommandResult)
    func setupPauseCommand(handler: @escaping () async -> RemoteCommandResult)
    func setupToggleCommand(handler: @escaping () async -> RemoteCommandResult)
    func disableUnsupportedCommands()
}

/// Protocol for now playing info center operations
protocol NowPlayingInfoCenterProtocol {
    func updateNowPlayingInfo(_ info: NowPlayingInfo)
}

/// Data model for now playing information
struct NowPlayingInfo {
    let title: String
    let isPlaying: Bool
    let duration: TimeInterval?
    let elapsedTime: TimeInterval?
    let artwork: Any?
}

/// Protocol for handling remote media commands
protocol RemoteCommandHandling: AnyObject {
    var onPlayCommand: (() async -> Void)? { get set }
    var onPauseCommand: (() async -> Void)? { get set }
    var onToggleCommand: (() -> Void)? { get set }
    
    func updateNowPlayingInfo(title: String, isPlaying: Bool, timerInfo: (duration: Int, elapsed: Int)?)
}

// MARK: - Concrete Implementations

#if os(iOS)
/// Adapter for MPRemoteCommandCenter
final class MPRemoteCommandCenterAdapter: RemoteCommandCenterProtocol {
    private let commandCenter = MPRemoteCommandCenter.shared()
    
    func setupPlayCommand(handler: @escaping () async -> RemoteCommandResult) {
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { _ in
            Task {
                let result = await handler()
                return result == .success ? MPRemoteCommandHandlerStatus.success : MPRemoteCommandHandlerStatus.commandFailed
            }
            return MPRemoteCommandHandlerStatus.success
        }
    }
    
    func setupPauseCommand(handler: @escaping () async -> RemoteCommandResult) {
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { _ in
            Task {
                let result = await handler()
                return result == .success ? MPRemoteCommandHandlerStatus.success : MPRemoteCommandHandlerStatus.commandFailed
            }
            return MPRemoteCommandHandlerStatus.success
        }
    }
    
    func setupToggleCommand(handler: @escaping () async -> RemoteCommandResult) {
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { _ in
            Task {
                let result = await handler()
                return result == .success ? MPRemoteCommandHandlerStatus.success : MPRemoteCommandHandlerStatus.commandFailed
            }
            return MPRemoteCommandHandlerStatus.success
        }
    }
    
    func disableUnsupportedCommands() {
        commandCenter.nextTrackCommand.isEnabled = false
        commandCenter.previousTrackCommand.isEnabled = false
        commandCenter.changePlaybackRateCommand.isEnabled = false
        commandCenter.seekBackwardCommand.isEnabled = false
        commandCenter.seekForwardCommand.isEnabled = false
        commandCenter.skipBackwardCommand.isEnabled = false
        commandCenter.skipForwardCommand.isEnabled = false
        commandCenter.changePlaybackPositionCommand.isEnabled = false
    }
}

/// Adapter for MPNowPlayingInfoCenter
final class MPNowPlayingInfoCenterAdapter: NowPlayingInfoCenterProtocol {
    func updateNowPlayingInfo(_ info: NowPlayingInfo) {
        var nowPlayingInfo = [String: Any]()
        
        nowPlayingInfo[MPMediaItemPropertyTitle] = info.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = RemoteCommandConstants.appArtist
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = RemoteCommandConstants.albumTitle
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = info.isPlaying 
            ? RemoteCommandConstants.defaultPlaybackRate 
            : RemoteCommandConstants.pausedPlaybackRate
        
        if let duration = info.duration {
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        }
        
        if let elapsedTime = info.elapsedTime {
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsedTime
        }
        
        if let artwork = info.artwork {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
}

/// Factory for creating artwork
final class ArtworkFactory {
    static func createArtwork(imageName: String, size: CGSize) -> MPMediaItemArtwork? {
        guard let image = UIImage(named: imageName) else { return nil }
        
        return MPMediaItemArtwork(boundsSize: size) { _ in
            let renderer = UIGraphicsImageRenderer(size: size)
            return renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: size))
            }
        }
    }
}
#endif

// MARK: - Main Service

@MainActor
final class RemoteCommandService: @preconcurrency RemoteCommandHandling {
    // MARK: - Properties
    
    var onPlayCommand: (() async -> Void)?
    var onPauseCommand: (() async -> Void)?
    var onToggleCommand: (() -> Void)?
    
    private let commandCenter: RemoteCommandCenterProtocol
    private let nowPlayingCenter: NowPlayingInfoCenterProtocol
    
    // MARK: - Initialization
    
    #if os(iOS)
    init(
        commandCenter: RemoteCommandCenterProtocol = MPRemoteCommandCenterAdapter(),
        nowPlayingCenter: NowPlayingInfoCenterProtocol = MPNowPlayingInfoCenterAdapter()
    ) {
        self.commandCenter = commandCenter
        self.nowPlayingCenter = nowPlayingCenter
        setupRemoteCommands()
    }
    #else
    init(
        commandCenter: RemoteCommandCenterProtocol,
        nowPlayingCenter: NowPlayingInfoCenterProtocol
    ) {
        self.commandCenter = commandCenter
        self.nowPlayingCenter = nowPlayingCenter
        setupRemoteCommands()
    }
    #endif
    
    // MARK: - Private Methods
    
    private func setupRemoteCommands() {
        commandCenter.setupPlayCommand { [weak self] in
            guard let self = self else { return .failed }
            await self.onPlayCommand?()
            return .success
        }
        
        commandCenter.setupPauseCommand { [weak self] in
            guard let self = self else { return .failed }
            await self.onPauseCommand?()
            return .success
        }
        
        commandCenter.setupToggleCommand { [weak self] in
            guard let self = self else { return .failed }
            self.onToggleCommand?()
            return .success
        }
        
        commandCenter.disableUnsupportedCommands()
    }
    
    // MARK: - Public Methods
    
    func updateNowPlayingInfo(title: String, isPlaying: Bool, timerInfo: (duration: Int, elapsed: Int)? = nil) {
        #if os(iOS)
        let artwork = ArtworkFactory.createArtwork(
            imageName: RemoteCommandConstants.appIconName,
            size: RemoteCommandConstants.artworkSize
        )
        
        let info = NowPlayingInfo(
            title: title,
            isPlaying: isPlaying,
            duration: timerInfo.map { Double($0.duration) },
            elapsedTime: timerInfo.map { Double($0.elapsed) },
            artwork: artwork
        )
        
        nowPlayingCenter.updateNowPlayingInfo(info)
        #endif
    }
}