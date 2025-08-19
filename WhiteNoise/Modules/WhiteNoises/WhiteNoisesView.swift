//
//  WhiteNoisesView.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 2025-08-14.
//

import SwiftUI
import Combine

struct WhiteNoisesView: View {
    @StateObject private var viewModel: WhiteNoisesViewModel
    
    init(presenter: WhiteNoisesPresenterProtocol) {
        _viewModel = StateObject(wrappedValue: WhiteNoisesViewModel(presenter: presenter))
    }
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(viewModel.soundViewModels) { soundViewModel in
                            SoundView(viewModel: soundViewModel)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(Color.white)
            
            VStack {
                Spacer()
                
                HStack(spacing: 20) {
                    // Play/Pause button
                    Button(action: {
                        viewModel.playPauseTapped()
                        HapticFeedbackService.shared.play(.light)
                    }) {
                        Image(systemName: viewModel.isPlaying ? "pause" : "play")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.vertical, 20)
                    .padding(.leading, 24)
                    .disabled(!viewModel.canAcceptInput)
                    .opacity(viewModel.canAcceptInput ? 1.0 : 0.5)
                    
                    Spacer()
                    
                    // Timer button
                    Button(action: {
                        viewModel.showTimerPicker = true
                        HapticFeedbackService.shared.play(.light)
                    }) {
                        HStack {
                            Image(systemName: "timer")
                                .resizable()
                                .frame(width: 30, height: 30)
                            if !viewModel.timerDisplay.isEmpty {
                                Text(viewModel.timerDisplay)
                                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                                    .frame(minWidth: 50)
                            }
                        }
                        .foregroundColor(viewModel.timerMode != .off ? .cyan : .white)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.vertical, 20)
                    .padding(.trailing, 24)
                }
                .background(Color("black90"))
                .clipShape(Capsule())
                .padding(.bottom, 10)
                .animation(.spring(response: 0.3, dampingFraction: 0.8))
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $viewModel.showTimerPicker) {
            TimerPickerView(selectedMode: $viewModel.timerMode)
                .presentationDetents([.height(300)])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            viewModel.onAppear()
        }
    }
    
    #if os(macOS)
    private let columns = [GridItem(.adaptive(minimum: 150, maximum: 400))]
    #elseif os(iOS)
    private let columns = [GridItem(.adaptive(minimum: 100, maximum: 200))]
    #endif
}

// MARK: - View Model

@MainActor
final class WhiteNoisesViewModel: ObservableObject, WhiteNoisesViewProtocol {
    
    // MARK: - Published Properties
    
    @Published var isPlaying: Bool = false
    @Published var timerDisplay: String = ""
    @Published var soundViewModels: [SoundViewModel] = []
    @Published var canAcceptInput: Bool = true
    @Published var showTimerPicker: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    @Published var isLoading: Bool = false
    
    @Published var timerMode: TimerService.TimerMode = .off {
        didSet {
            presenter?.timerModeSelected(timerMode)
        }
    }
    
    // MARK: - Properties
    
    var presenter: WhiteNoisesPresenterProtocol?
    
    // MARK: - Initialization
    
    init(presenter: WhiteNoisesPresenterProtocol) {
        self.presenter = presenter
        presenter.view = self
    }
    
    // MARK: - Public Methods
    
    func onAppear() {
        presenter?.viewDidLoad()
    }
    
    func playPauseTapped() {
        presenter?.playPauseTapped()
    }
    
    // MARK: - WhiteNoisesViewProtocol
    
    func updatePlayState(_ isPlaying: Bool) {
        self.isPlaying = isPlaying
    }
    
    func updateTimerDisplay(_ time: String) {
        self.timerDisplay = time
    }
    
    func updateSounds(_ sounds: [SoundViewModel]) {
        self.soundViewModels = sounds
    }
    
    func showLoading(_ show: Bool) {
        self.isLoading = show
    }
    
    func showError(_ message: String) {
        self.errorMessage = message
        self.showError = true
    }
    
    func disableUserInput(_ disable: Bool) {
        self.canAcceptInput = !disable
    }
}