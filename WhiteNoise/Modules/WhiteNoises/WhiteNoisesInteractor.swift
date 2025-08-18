//
//  WhiteNoisesInteractor.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 2025-08-14.
//

import Foundation
import Combine

@MainActor
final class WhiteNoisesInteractor: WhiteNoisesInteractorProtocol {
    
    // MARK: - Properties
    
    weak var presenter: WhiteNoisesPresenterProtocol?
    
    @Published private(set) var state: WhiteNoisesState = WhiteNoisesState()
    var statePublisher: AnyPublisher<WhiteNoisesState, Never> {
        $state.eraseToAnyPublisher()
    }
    
    private let reducer: WhiteNoisesReducer
    private let audioSessionService: AudioSessionManaging
    private let timerService: TimerServiceProtocol
    private let remoteCommandService: RemoteCommandHandling
    private let soundFactory: SoundFactoryProtocol
    
    private var soundViewModels: [UUID: SoundViewModel] = [:]
    private var cancellables = Set<AnyCancellable>()
    private var timerTask: Task<Void, Never>?
    private var fadeTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    init(
        reducer: WhiteNoisesReducer,
        audioSessionService: AudioSessionManaging? = nil,
        timerService: TimerServiceProtocol? = nil,
        remoteCommandService: RemoteCommandHandling? = nil,
        soundFactory: SoundFactoryProtocol? = nil
    ) {
        self.reducer = reducer
        self.audioSessionService = audioSessionService ?? AudioSessionService()
        self.timerService = timerService ?? TimerService()
        self.remoteCommandService = remoteCommandService ?? RemoteCommandService()
        self.soundFactory = soundFactory ?? SoundFactory()
        
        setupBindings()
    }
    
    deinit {
        timerTask?.cancel()
        fadeTask?.cancel()
    }
    
    // MARK: - WhiteNoisesInteractorProtocol
    
    func loadSounds() {
        dispatch(.setLoading(true))
        
        let sounds = soundFactory.getSavedSounds()
        var soundStates: [SoundState] = []
        
        for sound in sounds {
            let soundViewModel = SoundViewModel(sound: sound)
            soundViewModels[sound.id] = soundViewModel
            
            let soundState = SoundState(
                id: sound.id,
                name: sound.name,
                iconName: iconName(for: sound.icon),
                volume: sound.volume,
                selectedVariant: sound.selectedSoundVariant,
                availableVariants: sound.soundVariants
            )
            soundStates.append(soundState)
            
            // Observe volume changes
            soundViewModel.$volume
                .dropFirst()
                .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
                .sink { [weak self] volume in
                    self?.dispatch(.userChangedVolume(soundId: sound.id, volume: volume))
                }
                .store(in: &cancellables)
        }
        
        dispatch(.loadSounds(soundStates))
    }
    
    func togglePlayPause() {
        dispatch(.userTappedPlayPause)
    }
    
    func setTimer(_ mode: TimerService.TimerMode) {
        dispatch(.userSelectedTimer(mode: mode))
    }
    
    func updateVolume(soundId: UUID, volume: Float) {
        dispatch(.userChangedVolume(soundId: soundId, volume: volume))
    }
    
    func updateSoundVariant(soundId: UUID, variant: Sound.SoundVariant) {
        dispatch(.userSelectedSoundVariant(soundId: soundId, variant: variant))
    }
    
    func handleAudioInterruption(_ interrupted: Bool) {
        if interrupted && state.isPlaying {
            dispatch(.pausePlayback)
        } else if !interrupted && state.playbackState == .paused {
            dispatch(.startPlayback)
        }
    }
    
    func handleAppLifecycle(isActive: Bool) {
        if isActive && state.isPlaying {
            // Refresh audio when app becomes active
            Task {
                await audioSessionService.reconfigure()
                for soundViewModel in soundViewModels.values where soundViewModel.volume > 0 {
                    await soundViewModel.refreshAudioPlayer()
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func dispatch(_ action: WhiteNoisesAction) {
        let (newState, sideEffects) = reducer.reduce(state: state, action: action)
        state = newState
        
        Task {
            await processSideEffects(sideEffects)
        }
    }
    
    private func processSideEffects(_ sideEffects: [WhiteNoisesSideEffect]) async {
        for effect in sideEffects {
            await processSideEffect(effect)
        }
    }
    
    private func processSideEffect(_ effect: WhiteNoisesSideEffect) async {
        switch effect {
        case .playSounds(let ids, let fadeDuration):
            await playSounds(ids: ids, fadeDuration: fadeDuration)
            
        case .pauseSounds(let ids, let fadeDuration):
            await pauseSounds(ids: ids, fadeDuration: fadeDuration)
            
        case .updateSoundVolume(let id, let volume):
            soundViewModels[id]?.volume = volume
            
        case .updateSoundVariant(let id, let variant):
            if let soundViewModel = soundViewModels[id] {
                soundViewModel.selectedSoundVariant = variant
            }
            
        case .startTimer(let seconds):
            startTimer(seconds: seconds)
            
        case .stopTimer:
            stopTimer()
            
        case .saveState:
            // Save state to persistence
            break
            
        case .log(let level, let message):
            logMessage(level: level, message: message)
        }
    }
    
    private func playSounds(ids: [UUID], fadeDuration: Double?) async {
        await audioSessionService.ensureActive()
        
        dispatch(.startFadeIn)
        
        fadeTask?.cancel()
        fadeTask = Task {
            // Start playing sounds with fade
            await withTaskGroup(of: Void.self) { group in
                for id in ids {
                    if let soundViewModel = soundViewModels[id] {
                        group.addTask {
                            await soundViewModel.playSound(fadeDuration: fadeDuration)
                        }
                    }
                }
            }
            
            guard !Task.isCancelled else { return }
            
            // Simulate fade progress
            if let duration = fadeDuration, duration > 0 {
                let steps = 10
                for i in 1...steps {
                    try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000 / Double(steps)))
                    dispatch(.fadeInProgress(Double(i) / Double(steps)))
                }
            }
            
            dispatch(.fadeInCompleted)
        }
        
        await fadeTask?.value
    }
    
    private func pauseSounds(ids: [UUID], fadeDuration: Double?) async {
        dispatch(.startFadeOut)
        
        fadeTask?.cancel()
        fadeTask = Task {
            // Simulate fade progress
            if let duration = fadeDuration, duration > 0 {
                let steps = 10
                for i in 1...steps {
                    try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000 / Double(steps)))
                    dispatch(.fadeOutProgress(Double(i) / Double(steps)))
                }
            }
            
            guard !Task.isCancelled else { return }
            
            // Pause sounds with fade
            await withTaskGroup(of: Void.self) { group in
                for id in ids {
                    if let soundViewModel = soundViewModels[id] {
                        group.addTask {
                            await soundViewModel.pauseSound(fadeDuration: fadeDuration)
                        }
                    }
                }
            }
            
            dispatch(.fadeOutCompleted)
        }
        
        await fadeTask?.value
    }
    
    private func startTimer(seconds: Int) {
        stopTimer()
        
        timerTask = Task { [weak self] in
            for _ in 0..<seconds {
                guard !Task.isCancelled else { break }
                
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                self?.dispatch(.timerTick)
                
                if self?.state.timerState.remainingSeconds == 0 {
                    self?.dispatch(.timerExpired)
                    break
                }
            }
        }
    }
    
    private func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
    }
    
    private func setupBindings() {
        // Audio session interruption
        if let audioService = audioSessionService as? AudioSessionService {
            audioService.$isInterrupted
                .sink { [weak self] isInterrupted in
                    self?.handleAudioInterruption(isInterrupted)
                }
                .store(in: &cancellables)
        }
        
        // Remote commands
        remoteCommandService.onPlayCommand = { [weak self] in
            self?.togglePlayPause()
        }
        
        remoteCommandService.onPauseCommand = { [weak self] in
            self?.togglePlayPause()
        }
        
        remoteCommandService.onToggleCommand = { [weak self] in
            self?.togglePlayPause()
        }
        
        // App lifecycle
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.handleAppLifecycle(isActive: true)
            }
            .store(in: &cancellables)
    }
    
    private func iconName(for icon: Sound.Icon) -> String {
        switch icon {
        case .system(let name):
            return name
        case .custom(let name):
            return name
        }
    }
    
    private func logMessage(level: WhiteNoisesSideEffect.LogLevel, message: String) {
        switch level {
        case .debug:
            print("🔍 [DEBUG] \(message)")
        case .info:
            print("ℹ️ [INFO] \(message)")
        case .warning:
            print("⚠️ [WARNING] \(message)")
        case .error:
            print("❌ [ERROR] \(message)")
        }
    }
    
    // MARK: - Public Accessors
    
    func getSoundViewModels() -> [SoundViewModel] {
        Array(soundViewModels.values)
    }
}