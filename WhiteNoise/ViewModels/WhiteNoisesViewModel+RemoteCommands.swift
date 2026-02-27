//
//  WhiteNoisesViewModel+RemoteCommands.swift
//  WhiteNoise
//

import Foundation

extension WhiteNoisesViewModel {

    func setupRemoteCommands() {
        // Timer service callbacks
        timerService.onTimerExpired = { [weak self] in
            await self?.pauseSounds(fadeDuration: AppConstants.Animation.fadeOut)
        }

        timerService.onTimerTick = { [weak self] remainingSeconds in
            guard let self = self else { return }
            self.setRemainingTimerTime(self.timerService.remainingTime)
            if remainingSeconds % AppConstants.Timer.nowPlayingUpdateInterval == 0 {
                self.updateNowPlayingInfo()
            }
        }

        // Remote command callbacks
        remoteCommandService.onPlayCommand = { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                guard !self.actuallyPlayingAudio else { return }
                self.setPlayingState(true)
                self.playPauseTask?.cancel()
                self.playPauseTask = Task { [weak self] in
                    await self?.playSounds(fadeDuration: AppConstants.Animation.fadeLong, updateState: false)
                }
            }
        }

        remoteCommandService.onPauseCommand = { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                guard self.actuallyPlayingAudio else { return }
                self.setPlayingState(false)
                self.playPauseTask?.cancel()
                self.playPauseTask = Task { [weak self] in
                    await self?.pauseSounds(fadeDuration: AppConstants.Animation.fadeLong, updateState: false)
                }
            }
        }

        remoteCommandService.onToggleCommand = { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if self.actuallyPlayingAudio != self.isPlaying {
                    self.syncStateWithActualAudio()
                }
                self.playingButtonSelected()
            }
        }
    }
}
