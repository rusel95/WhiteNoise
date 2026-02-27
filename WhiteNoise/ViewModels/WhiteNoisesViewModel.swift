//
//  WhiteNoisesViewModel.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 30.05.2023.
//

import Foundation
@preconcurrency import AVFAudio
import MediaPlayer
import Observation

@Observable @MainActor
final class WhiteNoisesViewModel {

    // MARK: - Computed Properties
    var playingSounds: [SoundViewModel] {
        soundsViewModels.filter { $0.volume > 0 }
    }

    var actuallyPlayingAudio: Bool {
        soundsViewModels.contains { $0.isPlaying && $0.volume > 0 }
    }

    // MARK: - State Properties
    private(set) var soundsViewModels: [SoundViewModel] = []
    private(set) var isPlaying: Bool = false
    private(set) var remainingTimerTime: String = ""

    var timerMode: TimerService.TimerMode = .off {
        didSet {
            guard timerMode != oldValue else { return }
            handleTimerModeChange(timerMode)
        }
    }

    // MARK: - Services
    @ObservationIgnored
    let audioSessionService: AudioSessionManaging
    @ObservationIgnored
    let timerService: TimerServiceProtocol
    @ObservationIgnored
    let remoteCommandService: RemoteCommandHandling
    @ObservationIgnored
    private let soundFactory: SoundFactoryProtocol

    // MARK: - Internal State
    @ObservationIgnored
    private var isBootstrapped = false
    @ObservationIgnored
    var wasPlayingBeforeInterruption = false
    @ObservationIgnored
    nonisolated(unsafe) var lifecycleTask: Task<Void, Never>?
    @ObservationIgnored
    nonisolated(unsafe) var foregroundTask: Task<Void, Never>?
    @ObservationIgnored
    nonisolated(unsafe) var playPauseTask: Task<Void, Never>?

    // MARK: - Initialization
    init(
        soundFactory: SoundFactoryProtocol,
        audioSessionService: AudioSessionManaging,
        timerService: TimerServiceProtocol,
        remoteCommandService: RemoteCommandHandling
    ) {
        self.soundFactory = soundFactory
        self.audioSessionService = audioSessionService
        self.timerService = timerService
        self.remoteCommandService = remoteCommandService
    }

    /// Convenience factory for production use
    static func makeDefault() -> WhiteNoisesViewModel {
        WhiteNoisesViewModel(
            soundFactory: SoundFactory(),
            audioSessionService: AudioSessionService(),
            timerService: TimerService(),
            remoteCommandService: RemoteCommandService()
        )
    }

    /// Call from `.task { await viewModel.bootstrap() }` in the View.
    /// Idempotent — safe to call multiple times.
    func bootstrap() async {
        guard !isBootstrapped else { return }
        isBootstrapped = true

        setupRemoteCommands()
        setupObservers()
        loadSounds()
    }

    deinit {
        playPauseTask?.cancel()
        lifecycleTask?.cancel()
        foregroundTask?.cancel()
    }

    // MARK: - Internal State Mutators (for cross-file extensions)

    func setPlayingState(_ value: Bool) {
        isPlaying = value
    }

    func setRemainingTimerTime(_ time: String) {
        remainingTimerTime = time
    }

    // MARK: - Public Methods

    func playingButtonSelected() {
        // Cancel any existing play/pause task and its fade operations
        if playPauseTask != nil {
            playPauseTask?.cancel()
            playPauseTask = nil
            for soundViewModel in soundsViewModels {
                soundViewModel.cancelFade()
            }
        }

        let wasPlaying = isPlaying
        isPlaying = !wasPlaying

        playPauseTask = Task { [weak self] in
            guard let self = self else { return }
            if wasPlaying {
                await self.pauseSounds(fadeDuration: AppConstants.Animation.fadeStandard, updateState: false)
            } else {
                let activated = await self.audioSessionService.ensureActive()
                guard activated else {
                    self.setPlayingState(false)
                    return
                }
                await self.playSounds(fadeDuration: AppConstants.Animation.fadeStandard, updateState: false)
            }
        }
    }

    // MARK: - Private Setup

    private func loadSounds() {
        let sounds = soundFactory.getSavedSounds()
        soundsViewModels = []

        for sound in sounds {
            let soundViewModel = SoundViewModel.make(sound: sound)
            soundViewModel.onVolumeChanged = { [weak self] vm, volume in
                vm.volumeChangeTask?.cancel()
                vm.volumeChangeTask = Task { [weak self] in
                    await self?.handleVolumeChange(for: vm, volume: volume)
                }
            }
            soundsViewModels.append(soundViewModel)
        }

        Task.detached(priority: .background) { [weak self] in
            try? await Task.sleep(nanoseconds: AppConstants.Audio.preloadDelayNanoseconds)
            guard let self = self else { return }
            let soundsToPreload = await MainActor.run {
                self.soundsViewModels.filter { $0.sound.volume > 0 }
            }
            for soundViewModel in soundsToPreload {
                await soundViewModel.preloadAudio()
            }
        }
    }
}
