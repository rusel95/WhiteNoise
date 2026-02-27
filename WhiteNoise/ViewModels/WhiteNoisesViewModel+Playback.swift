//
//  WhiteNoisesViewModel+Playback.swift
//  WhiteNoise
//

import Foundation

extension WhiteNoisesViewModel {

    func playSounds(fadeDuration: Double? = nil) async {
        await playSounds(fadeDuration: fadeDuration, updateState: true)
    }

    func pauseSounds(fadeDuration: Double? = nil) async {
        await pauseSounds(fadeDuration: fadeDuration, updateState: true)
    }

    func playSounds(fadeDuration: Double? = nil, updateState: Bool) async {
        let actuallyPlaying = soundsViewModels.contains { $0.isPlaying && $0.volume > 0 }
        if actuallyPlaying && isPlaying && updateState { return }

        // Resume or start timer if needed
        if timerService.mode != .off {
            if timerService.hasRemainingTime && !timerService.isActive {
                timerService.resume()
                setRemainingTimerTime(timerService.remainingTime)
            } else if !timerService.hasRemainingTime {
                timerService.start(mode: timerService.mode)
                setRemainingTimerTime(timerService.remainingTime)
            }
        }

        let soundsToPlay = soundsViewModels.filter { $0.volume > 0 }
        await withTaskGroup(of: Void.self) { group in
            for soundViewModel in soundsToPlay {
                group.addTask { [weak soundViewModel] in
                    await soundViewModel?.playSound(fadeDuration: fadeDuration)
                }
            }
        }

        if updateState && !isPlaying {
            setPlayingState(true)
        }

        updateNowPlayingInfo()
    }

    func pauseSounds(fadeDuration: Double? = nil, updateState: Bool) async {
        let actuallyPlaying = soundsViewModels.contains { $0.isPlaying && $0.volume > 0 }
        if !actuallyPlaying && !isPlaying && updateState { return }

        if timerService.isActive {
            timerService.pause()
        }

        let soundsToPause = soundsViewModels.filter { $0.volume > 0 }
        await withTaskGroup(of: Void.self) { group in
            for soundViewModel in soundsToPause {
                group.addTask { [weak soundViewModel] in
                    await soundViewModel?.pauseSound(fadeDuration: fadeDuration)
                }
            }
        }

        if updateState && isPlaying {
            setPlayingState(false)
        }

        updateNowPlayingInfo()
    }

    func stopAllSounds() async {
        await withTaskGroup(of: Void.self) { group in
            for soundViewModel in soundsViewModels {
                group.addTask {
                    await soundViewModel.stop()
                }
            }
        }
    }

    func handleVolumeChange(for soundViewModel: SoundViewModel, volume: Float) async {
        if isPlaying {
            if volume > 0 {
                await soundViewModel.playSound()
            } else {
                await soundViewModel.pauseSound()
            }
            updateNowPlayingInfo()
        }
    }
}
