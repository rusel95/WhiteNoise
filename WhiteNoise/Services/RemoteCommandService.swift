//
//  RemoteCommandService.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 2025-08-03.
//

@preconcurrency import MediaPlayer

// MARK: - Constants

private enum RemoteCommandConstants {
    static let appArtist = "WhiteNoise App"
    static let albumTitle = "Ambient Sounds"
    static let artworkSize = CGSize(width: 300, height: 300)
    static let defaultPlaybackRate: Double = 1.0
    static let pausedPlaybackRate: Double = 0.0
}

// MARK: - Protocols

/// Represents the result of a remote command execution
enum RemoteCommandResult {
    case success
    case failed
}

/// Protocol for remote command center operations
protocol RemoteCommandCenterProtocol: Sendable {
    func setupPlayCommand(handler: @escaping @Sendable () async -> RemoteCommandResult)
    func setupPauseCommand(handler: @escaping @Sendable () async -> RemoteCommandResult)
    func setupToggleCommand(handler: @escaping @Sendable () async -> RemoteCommandResult)
    func disableUnsupportedCommands()
}

/// Protocol for now playing info center operations
protocol NowPlayingInfoCenterProtocol: Sendable {
    func updateNowPlayingInfo(_ info: NowPlayingInfo)
}

/// Data model for now playing information
struct NowPlayingInfo: Sendable {
    let title: String
    let isPlaying: Bool
    let duration: TimeInterval?
    let elapsedTime: TimeInterval?
    let artwork: (any Sendable)?
}

/// Protocol for handling remote media commands
@MainActor
protocol RemoteCommandHandling: AnyObject {
    var onPlayCommand: (@Sendable () async -> Void)? { get set }
    var onPauseCommand: (@Sendable () async -> Void)? { get set }
    var onToggleCommand: (@Sendable () -> Void)? { get set }

    func updateNowPlayingInfo(title: String, isPlaying: Bool, timerInfo: (duration: Int, elapsed: Int)?)
}

// MARK: - Concrete Implementations

#if os(iOS)
/// Adapter for MPRemoteCommandCenter
/// - Note: Marked @unchecked Sendable because MPRemoteCommandCenter.shared() is a thread-safe singleton
/// - Safety invariant: All access goes through the shared() singleton which is internally synchronized
/// - TODO: [Swift 6 Migration] Review when Apple frameworks add Sendable conformance
final class MPRemoteCommandCenterAdapter: RemoteCommandCenterProtocol, @unchecked Sendable {
    private let commandCenter = MPRemoteCommandCenter.shared()

    func setupPlayCommand(handler: @escaping @Sendable () async -> RemoteCommandResult) {
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { _ in
            Task {
                _ = await handler()
            }
            return MPRemoteCommandHandlerStatus.success
        }
    }

    func setupPauseCommand(handler: @escaping @Sendable () async -> RemoteCommandResult) {
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { _ in
            Task {
                _ = await handler()
            }
            return MPRemoteCommandHandlerStatus.success
        }
    }

    func setupToggleCommand(handler: @escaping @Sendable () async -> RemoteCommandResult) {
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { _ in
            Task {
                _ = await handler()
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
/// - Note: Marked @unchecked Sendable because MPNowPlayingInfoCenter.default() is a thread-safe singleton
/// - Safety invariant: All access goes through the default() singleton which is internally synchronized
/// - TODO: [Swift 6 Migration] Review when Apple frameworks add Sendable conformance
final class MPNowPlayingInfoCenterAdapter: NowPlayingInfoCenterProtocol, @unchecked Sendable {
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

#endif

// MARK: - Main Service

@MainActor
final class RemoteCommandService: RemoteCommandHandling {
    // MARK: - Properties

    var onPlayCommand: (@Sendable () async -> Void)?
    var onPauseCommand: (@Sendable () async -> Void)?
    var onToggleCommand: (@Sendable () -> Void)?
    
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
            guard let self = self else {
                TelemetryService.captureNonFatal(
                    message: "RemoteCommandService.playCommand lost self"
                )
                return .failed
            }
            await self.onPlayCommand?()
            return .success
        }

        commandCenter.setupPauseCommand { [weak self] in
            guard let self = self else {
                TelemetryService.captureNonFatal(
                    message: "RemoteCommandService.pauseCommand lost self"
                )
                return .failed
            }
            await self.onPauseCommand?()
            return .success
        }

        commandCenter.setupToggleCommand { [weak self] in
            guard let strongSelf = self else {
                TelemetryService.captureNonFatal(
                    message: "RemoteCommandService.toggleCommand lost self"
                )
                return .failed
            }
            await MainActor.run {
                strongSelf.onToggleCommand?()
            }
            return .success
        }
        
        commandCenter.disableUnsupportedCommands()
    }
    
    // MARK: - Public Methods
    
    func updateNowPlayingInfo(title: String, isPlaying: Bool, timerInfo: (duration: Int, elapsed: Int)? = nil) {
        #if os(iOS)
        // Use app icon from asset catalog with Swift generated asset symbol
        let artwork: MPMediaItemArtwork? = {
            let image = UIImage.launchScreenIcon
            return MPMediaItemArtwork(boundsSize: RemoteCommandConstants.artworkSize) { _ in image }
        }()
        
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
