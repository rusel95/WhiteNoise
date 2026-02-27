//
//  WhiteNoisesViewModel+NowPlaying.swift
//  WhiteNoise
//

import Foundation

extension WhiteNoisesViewModel {

    func updateNowPlayingInfo() {
        let activeSounds = soundsViewModels
            .filter { $0.volume > 0 }
            .map { $0.sound.name }

        let title = activeSounds.isEmpty ? "White Noise" : activeSounds.joined(separator: ", ")

        var timerInfo: (duration: Int, elapsed: Int)?
        if timerService.mode != .off && timerService.isActive {
            let totalSeconds = timerService.mode.totalSeconds
            let elapsedSeconds = totalSeconds - timerService.remainingSeconds
            timerInfo = (duration: totalSeconds, elapsed: elapsedSeconds)
        }

        remoteCommandService.updateNowPlayingInfo(
            title: title,
            isPlaying: isPlaying,
            timerInfo: timerInfo
        )
    }
}
