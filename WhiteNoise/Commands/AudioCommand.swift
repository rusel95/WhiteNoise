//
//  AudioCommand.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 2025-08-11.
//

import Foundation

// MARK: - Command Protocol

protocol AudioCommand {
    var name: String { get }
    func execute() async
    func undo() async
    func canUndo() -> Bool
}

// MARK: - Base Command

@MainActor
class BaseAudioCommand: @preconcurrency AudioCommand {
    let player: AudioPlayerProtocol
    let viewModel: SoundViewModel
    var previousState: (isPlaying: Bool, volume: Float)?
    
    var name: String {
        "Base Audio Command"
    }
    
    init(player: AudioPlayerProtocol, viewModel: SoundViewModel) {
        self.player = player
        self.viewModel = viewModel
    }
    
    func execute() async {
        // Store current state before execution
        previousState = (player.isPlaying, player.volume)
    }
    
    func undo() async {
        guard let state = previousState else { return }
        
        player.volume = state.volume
        if state.isPlaying && !player.isPlaying {
            _ = player.play()
        } else if !state.isPlaying && player.isPlaying {
            player.pause()
        }
    }
    
    func canUndo() -> Bool {
        previousState != nil
    }
}

// MARK: - Concrete Commands

@MainActor
final class PlayCommand: BaseAudioCommand {
    private let fadeDuration: Double?
    
    override var name: String {
        "Play Sound"
    }
    
    init(player: AudioPlayerProtocol, viewModel: SoundViewModel, fadeDuration: Double? = nil) {
        self.fadeDuration = fadeDuration
        super.init(player: player, viewModel: viewModel)
    }
    
    override func execute() async {
        await super.execute()
        await viewModel.playSound(fadeDuration: fadeDuration)
    }
}

@MainActor
final class PauseCommand: BaseAudioCommand {
    private let fadeDuration: Double?
    
    override var name: String {
        "Pause Sound"
    }
    
    init(player: AudioPlayerProtocol, viewModel: SoundViewModel, fadeDuration: Double? = nil) {
        self.fadeDuration = fadeDuration
        super.init(player: player, viewModel: viewModel)
    }
    
    override func execute() async {
        await super.execute()
        await viewModel.pauseSound(fadeDuration: fadeDuration)
    }
}

@MainActor
final class StopCommand: BaseAudioCommand {
    override var name: String {
        "Stop Sound"
    }
    
    override func execute() async {
        await super.execute()
        await viewModel.stop()
    }
}

@MainActor
final class VolumeChangeCommand: BaseAudioCommand {
    private let newVolume: Float
    private var previousVolume: Float?
    
    override var name: String {
        "Change Volume"
    }
    
    init(player: AudioPlayerProtocol, viewModel: SoundViewModel, newVolume: Float) {
        self.newVolume = newVolume
        super.init(player: player, viewModel: viewModel)
    }
    
    override func execute() async {
        previousVolume = viewModel.volume
        viewModel.volume = newVolume
    }
    
    override func undo() async {
        if let volume = previousVolume {
            viewModel.volume = volume
        }
    }
}

// MARK: - Command Invoker

@MainActor
final class AudioCommandInvoker {
    private var commandHistory: [AudioCommand] = []
    private var currentCommandIndex: Int = -1
    
    private let maxHistorySize: Int
    
    init(maxHistorySize: Int = 50) {
        self.maxHistorySize = maxHistorySize
    }
    
    func execute(_ command: AudioCommand) async {
        await command.execute()
        
        // Remove any commands after the current index
        if currentCommandIndex < commandHistory.count - 1 {
            commandHistory.removeLast(commandHistory.count - currentCommandIndex - 1)
        }
        
        // Add new command
        commandHistory.append(command)
        currentCommandIndex = commandHistory.count - 1
        
        // Limit history size
        if commandHistory.count > maxHistorySize {
            commandHistory.removeFirst()
            currentCommandIndex -= 1
        }
    }
    
    func undo() async {
        guard canUndo() else { return }
        
        let command = commandHistory[currentCommandIndex]
        await command.undo()
        currentCommandIndex -= 1
    }
    
    func redo() async {
        guard canRedo() else { return }
        
        currentCommandIndex += 1
        let command = commandHistory[currentCommandIndex]
        await command.execute()
    }
    
    func canUndo() -> Bool {
        currentCommandIndex >= 0 && currentCommandIndex < commandHistory.count
    }
    
    func canRedo() -> Bool {
        currentCommandIndex < commandHistory.count - 1
    }
    
    func clearHistory() {
        commandHistory.removeAll()
        currentCommandIndex = -1
    }
    
    var lastCommand: AudioCommand? {
        guard currentCommandIndex >= 0 && currentCommandIndex < commandHistory.count else { return nil }
        return commandHistory[currentCommandIndex]
    }
}