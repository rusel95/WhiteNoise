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

            if !isPlaying {
                setPlayingState(true)
                playPauseTask?.cancel()
                playPauseTask = Task { [weak self] in
                    await self?.playSounds(fadeDuration: AppConstants.Animation.fadeLong, updateState: false)
                }
            }
            updateNowPlayingInfo()
        } else {
            timerService.stop()
            setRemainingTimerTime("")
            updateNowPlayingInfo()
        }
    }

    func handleTimerExpired() async {
        await pauseSounds(fadeDuration: AppConstants.Animation.fadeOut)
        setRemainingTimerTime("")
    }
}
