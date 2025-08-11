//
//  TimerService.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 2025-08-03.
//

import Foundation
import Combine

// MARK: - Protocol

/// Protocol for timer functionality
protocol TimerServiceProtocol: AnyObject {
    var mode: TimerService.TimerMode { get set }
    var remainingTime: String { get }
    var isActive: Bool { get }
    var onTimerExpired: (() async -> Void)? { get set }
    var onTimerTick: ((Int) -> Void)? { get set }
    
    func start(mode: TimerService.TimerMode)
    func stop()
}

@MainActor
class TimerService: ObservableObject, @preconcurrency TimerServiceProtocol {
    @Published var mode: TimerMode = .off
    @Published var remainingTime: String = ""
    @Published private(set) var isActive = false
    
    private var remainingSeconds: Int = 0
    private var timerTask: Task<Void, Never>?
    
    var onTimerExpired: (() async -> Void)?
    var onTimerTick: ((Int) -> Void)?
    
    deinit {
        timerTask?.cancel()
    }
    
    func start(mode: TimerMode) {
        guard mode != .off else { return }
        
        self.mode = mode
        self.remainingSeconds = mode.totalSeconds
        self.isActive = true
        updateDisplay()
        
        timerTask?.cancel()
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: AppConstants.Timer.updateInterval)
                
                guard let self = self else { break }
                
                if self.remainingSeconds > 0 {
                    self.remainingSeconds -= 1
                    self.updateDisplay()
                    self.onTimerTick?(self.remainingSeconds)
                } else {
                    await self.handleTimerExpired()
                    break
                }
            }
        }
    }
    
    func stop() {
        timerTask?.cancel()
        timerTask = nil
        mode = .off
        remainingSeconds = 0
        remainingTime = ""
        isActive = false
    }
    
    private func updateDisplay() {
        let hours = remainingSeconds / 3600
        let minutes = (remainingSeconds % 3600) / 60
        let seconds = remainingSeconds % 60
        
        if hours > 0 {
            remainingTime = String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            remainingTime = String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    private func handleTimerExpired() async {
        stop()
        await onTimerExpired?()
    }
}

// MARK: - TimerMode
extension TimerService {
    enum TimerMode: Int, CaseIterable, Identifiable {
        case off = 0
        case oneMinute = 60
        case twoMinutes = 120
        case threeMinutes = 180
        case fiveMinutes = 300
        case tenMinutes = 600
        case fifteenMinutes = 900
        case thirtyMinutes = 1800
        case sixtyMinutes = 3600
        case twoHours = 7200
        case threeHours = 10800
        case fourHours = 14400
        case fiveHours = 18000
        case sixHours = 21600
        case sevenHours = 25200
        case eightHours = 28800
        
        var id: Int { rawValue }
        var totalSeconds: Int { rawValue }
        var minutes: Int { rawValue / 60 }
        
        var displayText: String {
            switch self {
            case .off: return "Off"
            case .oneMinute: return "1 minute"
            case .twoMinutes: return "2 minutes"
            case .threeMinutes: return "3 minutes"
            case .fiveMinutes: return "5 minutes"
            case .tenMinutes: return "10 minutes"
            case .fifteenMinutes: return "15 minutes"
            case .thirtyMinutes: return "30 minutes"
            case .sixtyMinutes: return "1 hour"
            case .twoHours: return "2 hours"
            case .threeHours: return "3 hours"
            case .fourHours: return "4 hours"
            case .fiveHours: return "5 hours"
            case .sixHours: return "6 hours"
            case .sevenHours: return "7 hours"
            case .eightHours: return "8 hours"
            }
        }
    }
}