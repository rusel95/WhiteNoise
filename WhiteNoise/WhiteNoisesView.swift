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

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                ForEach(viewModel.soundsViewModels) { viewModel in
                    SoundView(viewModel: viewModel)
                }
            }

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
                        Image(systemName: viewModel.isPlaying ? "pause.circle" : "play.circle")
                            .resizable()
                            .frame(width: 48, height: 48)
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
                    }

                    Spacer()
                }
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(Color.white)
            .background(Color.black)
        }
        .background(Color("black90"))
    }

}
