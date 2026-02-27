//
//  WhiteNoisesViewModel+Lifecycle.swift
//  WhiteNoise
//

import Foundation
#if os(iOS)
import UIKit
#endif

extension WhiteNoisesViewModel {

    func setupObservers() {
        audioSessionService.onInterruptionChanged = { [weak self] isInterrupted in
            Task { @MainActor [weak self] in
                await self?.handleAudioInterruption(isInterrupted)
            }
        }

        setupAppLifecycleObservers()
    }

    func syncStateWithActualAudio() {
        let wasUIPlaying = isPlaying
        let actuallyPlaying = actuallyPlayingAudio

        if actuallyPlaying != wasUIPlaying {
            setPlayingState(actuallyPlaying)

            if actuallyPlaying && timerService.hasRemainingTime && !timerService.isActive {
                timerService.resume()
                setRemainingTimerTime(timerService.remainingTime)
            } else if !actuallyPlaying && timerService.isActive {
                timerService.pause()
            }

            updateNowPlayingInfo()
        }
    }

    // MARK: - Private

    private func setupAppLifecycleObservers() {
        #if os(iOS)
        lifecycleTask = Task { [weak self] in
            for await _ in NotificationCenter.default.notifications(named: UIApplication.didBecomeActiveNotification) {
                await self?.handleAppDidBecomeActive()
            }
        }
        foregroundTask = Task { [weak self] in
            for await _ in NotificationCenter.default.notifications(named: UIApplication.willEnterForegroundNotification) {
                await self?.audioSessionService.reconfigure()
            }
        }
        #endif
    }

    private func handleAudioInterruption(_ isInterrupted: Bool) async {
        if isInterrupted {
            if isPlaying {
                wasPlayingBeforeInterruption = true
                await pauseSounds(fadeDuration: AppConstants.Animation.fadeLong)
            }
        } else if wasPlayingBeforeInterruption {
            await audioSessionService.ensureActive()
            await playSounds(fadeDuration: AppConstants.Animation.fadeLong)
            wasPlayingBeforeInterruption = false
        }
    }

    private func handleAppDidBecomeActive() async {
        let desiredPlaying = isPlaying
        await audioSessionService.reconfigure()

        if desiredPlaying && !actuallyPlayingAudio {
            await playSounds(fadeDuration: AppConstants.Animation.fadeLong, updateState: false)
        } else if desiredPlaying && actuallyPlayingAudio {
            for soundViewModel in soundsViewModels where soundViewModel.volume > 0 {
                await soundViewModel.playSound()
            }
        }

        syncStateWithActualAudio()
    }
}
