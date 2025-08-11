//
//  TimerCommand.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 2025-08-11.
//

import Foundation

// MARK: - Timer Command Protocol

protocol TimerCommand {
    var name: String { get }
    func execute() async
    func cancel() async
}

// MARK: - Concrete Timer Commands

@MainActor
final class SetTimerCommand: @preconcurrency TimerCommand {
    private let timerService: TimerServiceProtocol
    private let mode: TimerService.TimerMode
    private let fadeOutDuration: Double
    private weak var viewModel: WhiteNoisesViewModel?
    
    var name: String {
        "Set Timer: \(mode.displayText)"
    }
    
    init(
        timerService: TimerServiceProtocol,
        mode: TimerService.TimerMode,
        fadeOutDuration: Double,
        viewModel: WhiteNoisesViewModel
    ) {
        self.timerService = timerService
        self.mode = mode
        self.fadeOutDuration = fadeOutDuration
        self.viewModel = viewModel
    }
    
    func execute() async {
        guard mode != .off else {
            await cancel()
            return
        }
        
        timerService.onTimerExpired = { [weak viewModel, fadeOutDuration] in
            await viewModel?.pauseSounds(fadeDuration: fadeOutDuration)
        }
        timerService.start(mode: mode)
    }
    
    func cancel() async {
        timerService.stop()
    }
}

@MainActor
final class CancelTimerCommand: @preconcurrency TimerCommand {
    private let timerService: TimerServiceProtocol
    
    var name: String {
        "Cancel Timer"
    }
    
    init(timerService: TimerServiceProtocol) {
        self.timerService = timerService
    }
    
    func execute() async {
        timerService.stop()
    }
    
    func cancel() async {
        // No-op for cancel command
    }
}

// MARK: - Timer Command Manager

@MainActor
final class TimerCommandManager {
    private let timerService: TimerServiceProtocol
    private var currentCommand: TimerCommand?
    
    init(timerService: TimerServiceProtocol) {
        self.timerService = timerService
    }
    
    func setTimer(mode: TimerService.TimerMode, fadeOutDuration: Double, viewModel: WhiteNoisesViewModel) async {
        // Cancel any existing timer
        if let current = currentCommand {
            await current.cancel()
        }
        
        // Create and execute new timer command
        let command = SetTimerCommand(
            timerService: timerService,
            mode: mode,
            fadeOutDuration: fadeOutDuration,
            viewModel: viewModel
        )
        
        currentCommand = command
        await command.execute()
    }
    
    func cancelTimer() async {
        if let current = currentCommand {
            await current.cancel()
            currentCommand = nil
        }
    }
    
    var hasActiveTimer: Bool {
        currentCommand != nil && timerService.isActive
    }
}