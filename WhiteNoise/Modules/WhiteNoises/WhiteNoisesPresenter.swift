//
//  WhiteNoisesPresenter.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 2025-08-14.
//

import Foundation
import Combine

@MainActor
final class WhiteNoisesPresenter: WhiteNoisesPresenterProtocol {
    
    // MARK: - Properties
    
    weak var view: WhiteNoisesViewProtocol?
    var interactor: WhiteNoisesInteractorProtocol?
    var router: WhiteNoisesRouterProtocol?
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(interactor: WhiteNoisesInteractorProtocol, router: WhiteNoisesRouterProtocol) {
        self.interactor = interactor
        self.router = router
        
        setupBindings()
    }
    
    // MARK: - WhiteNoisesPresenterProtocol
    
    func viewDidLoad() {
        interactor?.loadSounds()
    }
    
    func playPauseTapped() {
        interactor?.togglePlayPause()
    }
    
    func timerModeSelected(_ mode: TimerService.TimerMode) {
        interactor?.setTimer(mode)
    }
    
    func volumeChanged(for soundId: UUID, volume: Float) {
        interactor?.updateVolume(soundId: soundId, volume: volume)
    }
    
    func soundVariantChanged(for soundId: UUID, variant: Sound.SoundVariant) {
        interactor?.updateSoundVariant(soundId: soundId, variant: variant)
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        interactor?.statePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                self?.updateView(with: state)
            }
            .store(in: &cancellables)
    }
    
    private func updateView(with state: WhiteNoisesState) {
        // Update play state
        view?.updatePlayState(state.isPlaying)
        
        // Update timer display
        view?.updateTimerDisplay(state.timerState.displayTime)
        
        // Update user input state
        view?.disableUserInput(!state.canAcceptInput)
        
        // Update sounds if needed
        if let interactor = interactor as? WhiteNoisesInteractor {
            view?.updateSounds(interactor.getSoundViewModels())
        }
        
        // Show loading
        view?.showLoading(state.isLoading)
        
        // Show error if any
        if let error = state.error {
            view?.showError(error)
        }
    }
}