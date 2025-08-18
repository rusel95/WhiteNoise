//
//  WhiteNoisesProtocols.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 2025-08-14.
//

import Foundation
import Combine

// MARK: - View Protocol
@MainActor
protocol WhiteNoisesViewProtocol: AnyObject {
    var presenter: WhiteNoisesPresenterProtocol? { get set }
    
    func updatePlayState(_ isPlaying: Bool)
    func updateTimerDisplay(_ time: String)
    func updateSounds(_ sounds: [SoundViewModel])
    func showLoading(_ show: Bool)
    func showError(_ message: String)
    func disableUserInput(_ disable: Bool)
}

// MARK: - Presenter Protocol
@MainActor
protocol WhiteNoisesPresenterProtocol: AnyObject {
    var view: WhiteNoisesViewProtocol? { get set }
    var interactor: WhiteNoisesInteractorProtocol? { get set }
    var router: WhiteNoisesRouterProtocol? { get set }
    
    func viewDidLoad()
    func playPauseTapped()
    func timerModeSelected(_ mode: TimerService.TimerMode)
    func volumeChanged(for soundId: UUID, volume: Float)
    func soundVariantChanged(for soundId: UUID, variant: Sound.SoundVariant)
}

// MARK: - Interactor Protocol
@MainActor
protocol WhiteNoisesInteractorProtocol: AnyObject {
    var presenter: WhiteNoisesPresenterProtocol? { get set }
    var state: WhiteNoisesState { get }
    var statePublisher: AnyPublisher<WhiteNoisesState, Never> { get }
    
    func loadSounds()
    func togglePlayPause()
    func setTimer(_ mode: TimerService.TimerMode)
    func updateVolume(soundId: UUID, volume: Float)
    func updateSoundVariant(soundId: UUID, variant: Sound.SoundVariant)
    func handleAudioInterruption(_ interrupted: Bool)
    func handleAppLifecycle(isActive: Bool)
}

// MARK: - Router Protocol
@MainActor
protocol WhiteNoisesRouterProtocol: AnyObject {
    var viewController: WhiteNoisesViewProtocol? { get set }
    
    func navigateToSettings()
    func presentTimerPicker(currentMode: TimerService.TimerMode, completion: @escaping (TimerService.TimerMode) -> Void)
    func presentSoundVariantPicker(for sound: Sound, completion: @escaping (Sound.SoundVariant) -> Void)
}

// MARK: - Output Protocol (Presenter to View)
@MainActor
protocol WhiteNoisesPresenterOutputProtocol: AnyObject {
    func didUpdateState(_ state: WhiteNoisesState)
    func didFailWithError(_ error: Error)
    func didStartLoading()
    func didFinishLoading()
}