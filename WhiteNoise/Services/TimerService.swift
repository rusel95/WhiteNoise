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
@MainActor
protocol TimerServiceProtocol: AnyObject {
    var mode: TimerService.TimerMode { get set }
    var remainingTime: String { get }
    var isActive: Bool { get }
    var hasRemainingTime: Bool { get }
    var onTimerExpired: (() async -> Void)? { get set }
    var onTimerTick: ((Int) -> Void)? { get set }

    func start(mode: TimerService.TimerMode)
    func pause()
    func resume()
    func stop()
}

@MainActor
class TimerService: ObservableObject, TimerServiceProtocol {
    @Published var mode: TimerMode = .off
    @Published var remainingTime: String = ""
    @Published private(set) var isActive = false
    
    private var remainingSeconds: Int = 0
    private var timerTask: Task<Void, Never>?
    private var isPaused = false
    
    var hasRemainingTime: Bool {
        return remainingSeconds > 0 && mode != .off
    }

    /// Exposes remaining seconds for testing purposes
    var remainingSecondsValue: Int {
        return remainingSeconds
    }
    
    var onTimerExpired: (() async -> Void)?
    var onTimerTick: ((Int) -> Void)?
    
    deinit {
        timerTask?.cancel()
    }
    
    /// Starts a new timer with the specified mode.
    ///
    /// This method initializes a timer with the duration specified by the mode parameter.
    /// If a timer is already running, it will be cancelled and replaced with the new timer.
    ///
    /// - Parameter mode: The timer mode specifying the duration. Must not be `.off`.
    ///
    /// - Important: This method resets any existing timer state and starts fresh.
    ///   Use `resume()` to continue a paused timer.
    func start(mode: TimerMode) {
        guard mode != .off else {
            print("⚠️ TimerSvc.start - SKIPPED: Mode is off")
            return
        }
        
        print("🎯 TimerSvc.start - START: mode=\(mode.displayText) (\(mode.totalSeconds)s)")
        print("📊 TimerSvc.start - PRE-STATE: active=\(isActive), paused=\(isPaused), remaining=\(remainingSeconds)s")
        
        self.mode = mode
        self.remainingSeconds = mode.totalSeconds
        self.isActive = true
        self.isPaused = false
        updateDisplay()
        
        if timerTask != nil {
            print("🔄 TimerSvc.start - CANCELLING: Previous timer task")
            timerTask?.cancel()
        }
        
        print("⏱️ TimerSvc.start - CREATING: New timer task for \(mode.totalSeconds) seconds")

        startCountdownTask(logPrefix: "start")

        print("✅ TimerSvc.start - COMPLETED: Timer started with \(remainingTime)")
    }
    
    /// Pauses the currently running timer.
    ///
    /// This method stops the timer task while preserving the current state, including
    /// the remaining time and timer mode. The timer can be resumed later using `resume()`.
    ///
    /// - Note: The timer state (mode and remaining seconds) is preserved for resumption.
    ///
    /// - Important: This method differs from `stop()` which completely resets the timer.
    func pause() {
        print("🎯 TimerSvc.pause - START")
        print("📊 TimerSvc.pause - PRE-STATE: active=\(isActive), paused=\(isPaused), remaining=\(remainingSeconds)s (\(remainingTime))")
        
        if timerTask != nil {
            print("🔄 TimerSvc.pause - CANCELLING: Timer task")
            timerTask?.cancel()
            timerTask = nil
        }
        
        isActive = false
        isPaused = true
        
        print("📊 TimerSvc.pause - POST-STATE: active=\(isActive), paused=\(isPaused), remaining=\(remainingSeconds)s")
        print("✅ TimerSvc.pause - COMPLETED: Timer paused at \(remainingTime)")
    }
    
    /// Resumes a paused timer from where it left off.
    ///
    /// This method restarts the timer using the preserved remaining time from when
    /// it was paused. The timer must have been previously paused using `pause()`.
    ///
    /// - Precondition: The timer must be in a paused state with remaining time > 0.
    ///
    /// - Note: If the timer was not paused or has no remaining time, this method does nothing.
    func resume() {
        print("🎯 TimerSvc.resume - START")
        print("📊 TimerSvc.resume - PRE-STATE: mode=\(mode), paused=\(isPaused), remaining=\(remainingSeconds)s")
        
        guard mode != .off && remainingSeconds > 0 && isPaused else {
            print("⚠️ TimerSvc.resume - SKIPPED: Invalid state (mode=\(mode), remaining=\(remainingSeconds), paused=\(isPaused))")
            return
        }
        
        isPaused = false
        isActive = true
        updateDisplay()
        
        if timerTask != nil {
            print("🔄 TimerSvc.resume - CANCELLING: Previous timer task")
            timerTask?.cancel()
        }
        
        print("⏱️ TimerSvc.resume - CREATING: Resume task for \(remainingSeconds) seconds")

        startCountdownTask(logPrefix: "resume")

        print("✅ TimerSvc.resume - COMPLETED: Timer resumed at \(remainingTime)")
    }
    
    /// Completely stops and resets the timer.
    ///
    /// This method cancels the timer task and resets all timer state to initial values.
    /// Unlike `pause()`, this method does not preserve any state for resumption.
    ///
    /// After calling this method:
    /// - Timer mode is set to `.off`
    /// - Remaining time is reset to 0
    /// - All timer state is cleared
    ///
    /// - Important: Use `pause()` if you want to preserve the timer state for later resumption.
    func stop() {
        print("🎯 TimerSvc.stop - START")
        print("📊 TimerSvc.stop - PRE-STATE: mode=\(mode), active=\(isActive), paused=\(isPaused), remaining=\(remainingSeconds)s")
        
        if timerTask != nil {
            print("🔄 TimerSvc.stop - CANCELLING: Timer task")
            timerTask?.cancel()
            timerTask = nil
        }
        
        mode = .off
        remainingSeconds = 0
        remainingTime = ""
        isActive = false
        isPaused = false
        
        print("📊 TimerSvc.stop - POST-STATE: All timer state reset")
        print("✅ TimerSvc.stop - COMPLETED: Timer fully stopped and reset")
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

    /// Shared countdown logic for both start() and resume()
    /// - Parameter logPrefix: Prefix for log messages (e.g., "start" or "resume")
    private func startCountdownTask(logPrefix: String) {
        let currentMode = mode
        timerTask = Task { [weak self] in
            print("⏱️ TimerSvc.\(logPrefix) - TASK STARTED: Beginning countdown")

            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: AppConstants.Timer.updateInterval)

                guard !Task.isCancelled else { break }

                guard let self = self else {
                    print("❌ TimerSvc.\(logPrefix) - TASK CANCELLED: Self deallocated")
                    TelemetryService.captureNonFatal(
                        message: "TimerService.\(logPrefix) countdown lost self",
                        extra: ["mode": currentMode.displayText]
                    )
                    break
                }

                if self.remainingSeconds > 0 {
                    self.remainingSeconds -= 1
                    self.updateDisplay()

                    // Log every 10 seconds or when less than 10 seconds remain
                    if self.remainingSeconds % 10 == 0 || self.remainingSeconds < 10 {
                        print("⏱️ TimerSvc - TICK: \(self.remainingTime) remaining")
                    }

                    self.onTimerTick?(self.remainingSeconds)
                } else {
                    print("⏱️ TimerSvc - EXPIRED: Timer reached zero")
                    await self.handleTimerExpired()
                    break
                }
            }

            print("⏱️ TimerSvc.\(logPrefix) - TASK ENDED")
        }
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
            case .off: return String(localized: "Off")
            case .oneMinute: return String(localized: "1 minute")
            case .twoMinutes: return String(localized: "2 minutes")
            case .threeMinutes: return String(localized: "3 minutes")
            case .fiveMinutes: return String(localized: "5 minutes")
            case .tenMinutes: return String(localized: "10 minutes")
            case .fifteenMinutes: return String(localized: "15 minutes")
            case .thirtyMinutes: return String(localized: "30 minutes")
            case .sixtyMinutes: return String(localized: "1 hour")
            case .twoHours: return String(localized: "2 hours")
            case .threeHours: return String(localized: "3 hours")
            case .fourHours: return String(localized: "4 hours")
            case .fiveHours: return String(localized: "5 hours")
            case .sixHours: return String(localized: "6 hours")
            case .sevenHours: return String(localized: "7 hours")
            case .eightHours: return String(localized: "8 hours")
            }
        }
    }
}
