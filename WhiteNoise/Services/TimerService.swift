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
    var remainingSeconds: Int { get }
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
    
    private(set) var remainingSeconds: Int = 0
    private var timerTask: Task<Void, Never>?
    private var isPaused = false
    
    var hasRemainingTime: Bool {
        return remainingSeconds > 0 && !mode.isOff
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
        guard mode != .off else { return }

        self.mode = mode
        self.remainingSeconds = mode.totalSeconds
        self.isActive = true
        self.isPaused = false
        updateDisplay()

        timerTask?.cancel()
        startCountdownTask()
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
        timerTask?.cancel()
        timerTask = nil
        isActive = false
        isPaused = true
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
        guard mode != .off && remainingSeconds > 0 && isPaused else { return }

        isPaused = false
        isActive = true
        updateDisplay()

        timerTask?.cancel()
        startCountdownTask()
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
        timerTask?.cancel()
        timerTask = nil
        mode = .off
        remainingSeconds = 0
        remainingTime = ""
        isActive = false
        isPaused = false
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

    private func startCountdownTask() {
        let currentMode = mode
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: AppConstants.Timer.updateInterval)
                guard !Task.isCancelled else { break }

                guard let self = self else {
                    TelemetryService.captureNonFatal(
                        message: "TimerService countdown lost self",
                        extra: ["mode": currentMode.displayText]
                    )
                    break
                }

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
}

// MARK: - TimerMode
extension TimerService {
    enum TimerMode: Hashable, Identifiable {
        case off
        case fiveMinutes
        case tenMinutes
        case fifteenMinutes
        case thirtyMinutes
        case sixtyMinutes
        case twoHours
        case threeHours
        case fourHours
        case sixHours
        case eightHours
        case custom(seconds: Int)

        var id: Int {
            switch self {
            case .off: return -1
            case .custom(let seconds): return seconds + 1_000_000
            default: return totalSeconds
            }
        }

        var totalSeconds: Int {
            switch self {
            case .off: return 0
            case .fiveMinutes: return 300
            case .tenMinutes: return 600
            case .fifteenMinutes: return 900
            case .thirtyMinutes: return 1800
            case .sixtyMinutes: return 3600
            case .twoHours: return 7200
            case .threeHours: return 10800
            case .fourHours: return 14400
            case .sixHours: return 21600
            case .eightHours: return 28800
            case .custom(let seconds): return seconds
            }
        }

        var minutes: Int { totalSeconds / 60 }

        var displayText: String {
            switch self {
            case .off: return String(localized: "Off")
            case .fiveMinutes: return String(localized: "5 minutes")
            case .tenMinutes: return String(localized: "10 minutes")
            case .fifteenMinutes: return String(localized: "15 minutes")
            case .thirtyMinutes: return String(localized: "30 minutes")
            case .sixtyMinutes: return String(localized: "1 hour")
            case .twoHours: return String(localized: "2 hours")
            case .threeHours: return String(localized: "3 hours")
            case .fourHours: return String(localized: "4 hours")
            case .sixHours: return String(localized: "6 hours")
            case .eightHours: return String(localized: "8 hours")
            case .custom(let seconds):
                let hours = seconds / 3600
                let mins = (seconds % 3600) / 60
                if hours == 0 {
                    return String(localized: "\(mins) min")
                } else if mins == 0 {
                    return hours == 1
                        ? String(localized: "1 hour")
                        : String(localized: "\(hours) hours")
                } else {
                    return String(localized: "\(hours)h \(mins)m")
                }
            }
        }

        /// All preset cases (excludes custom)
        static var presets: [TimerMode] {
            [.fiveMinutes, .tenMinutes, .fifteenMinutes, .thirtyMinutes,
             .sixtyMinutes, .twoHours, .threeHours, .fourHours, .sixHours, .eightHours]
        }

        /// All cases including off (excludes custom)
        static var allCases: [TimerMode] {
            [.off] + presets
        }

        /// Check if this is the off mode
        var isOff: Bool {
            if case .off = self { return true }
            return false
        }
    }
}
