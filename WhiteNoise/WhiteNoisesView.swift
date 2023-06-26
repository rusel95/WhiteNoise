//
//  SoundsView.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 30.05.2023.
//

import SwiftUI

struct WhiteNoisesView: View {

    @ObservedObject var viewModel: WhiteNoisesViewModel

    @State private var showPicker = false

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.soundsViewModels) { viewModel in
                        SoundView(viewModel: viewModel)
                    }
                }
                .background(Color("black90"))
            }
            
            Spacer()
            
            // MARK: - Bottom Controller
            
            HStack {
                HStack {
                    Spacer()

                    Button(action: {
                        if self.viewModel.isPlaying {
                            self.viewModel.pauseSounds()
                        } else {
                            self.viewModel.playSounds()
                        }
                    }) {
#if os(macOS)
                        Image(systemName: viewModel.isPlaying ? "pause" : "play")
#else
                        Image(systemName: viewModel.isPlaying ? "pause.circle" : "play.circle")
                            .resizable()
                            .frame(width: 48, height: 48)
#endif
                    }
                    .padding(8)
                }

                HStack {
                    Menu {
                        ForEach(WhiteNoisesViewModel.TimerMode.allCases) { mode in
                            Button(mode.description) {
                                viewModel.timerMode = mode
                            }
                        }
                    } label: {
                        Image(systemName: "timer.circle")
                            .resizable()
                            .frame(width: 48, height: 48)
#if os(macOS)
                        Text(viewModel.timerMode.description)
#endif
                    }

                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity)
        .foregroundColor(Color.white)
        .background(Color.black)
    }

}

