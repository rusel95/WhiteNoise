//
//  WhiteNoisesViewModel+Timer.swift
//  WhiteNoise
//

import Foundation

extension WhiteNoisesViewModel {

    func handleTimerModeChange(_ newMode: TimerService.TimerMode) {
        if newMode != .off {
            timerService.start(mode: newMode)
            setRemainingTimerTime(timerService.remainingTime)

            AnalyticsService.capture(.timerStarted(
                mode: newMode.displayText,
                durationSeconds: newMode.totalSeconds
            ))

            if !isPlaying {
                setPlayingState(true)
                playPauseTask?.cancel()
                playPauseTask = Task { [weak self] in
                    await self?.playSounds(fadeDuration: AppConstants.Animation.fadeLong, updateState: false)
                }
            }
            updateNowPlayingInfo()
        } else {
            let previousMode = timerService.mode
            let remaining = timerService.remainingSeconds
            timerService.stop()
            setRemainingTimerTime("")

            if remaining == 0 && !previousMode.isOff {
                AnalyticsService.capture(.timerCompleted(
                    mode: previousMode.displayText,
                    durationSeconds: previousMode.totalSeconds
                ))
            } else if !previousMode.isOff {
                AnalyticsService.capture(.timerCancelled(
                    mode: previousMode.displayText,
                    remainingSeconds: remaining
                ))
            }

            updateNowPlayingInfo()
        }
    }
}
