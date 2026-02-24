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
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.setPlayingState(true)
                if !self.actuallyPlayingAudio {
                    self.playPauseTask?.cancel()
                    self.playPauseTask = Task {
                        await self.playSounds(fadeDuration: AppConstants.Animation.fadeLong, updateState: false)
                    }
                    if self.timerService.hasRemainingTime && !self.timerService.isActive {
                        self.timerService.resume()
                        self.setRemainingTimerTime(self.timerService.remainingTime)
                    }
                }
            }
        }

        remoteCommandService.onPauseCommand = { [weak self] in
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.setPlayingState(false)
                if self.actuallyPlayingAudio {
                    self.playPauseTask?.cancel()
                    self.playPauseTask = Task {
                        await self.pauseSounds(fadeDuration: AppConstants.Animation.fadeLong, updateState: false)
                    }
                    if self.timerService.isActive {
                        self.timerService.pause()
                    }
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
