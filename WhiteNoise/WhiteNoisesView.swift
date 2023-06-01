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
        VStack {
            ScrollView {
                ForEach(viewModel.soundsViewModels) { viewModel in
                    SoundView(viewModel: viewModel)
                    Divider()
                }
            }
            .padding()

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
                            .frame(width: 36, height: 36)
                    }
                    .padding(8)
                }

                HStack {
                    Button(action: {
                        self.showPicker = true
                    }) {
                        Image(systemName: "timer.circle")
                            .resizable()
                            .frame(width: 36, height: 36)
                    }
                    .padding(8)

                    Spacer()

                    Picker(selection: $viewModel.timerMode, label: Text("")) {
                        ForEach(WhiteNoisesViewModel.TimerMode.allCases) { mode in
                            Text(mode.description)
                        }
                    }
                    .pickerStyle(.menu)

                    Spacer()
                }
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(Color.white)
        }
    }
}
