//
//  SoundsView.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 30.05.2023.
//

import SwiftUI

struct WhiteNoisesView: View {

    @ObservedObject var viewModel: WhiteNoisesViewModel

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
                Button(action: {
                    if self.viewModel.isPlaying {
                        self.viewModel.stopSounds()
                    } else {
                        self.viewModel.playSounds()
                    }
                }) {
                    Image(systemName: viewModel.isPlaying ? "stop.fill" : "play.fill")
                        .resizable()
                        .frame(width: 28, height: 28)
                }
                .padding(8)
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(Color.white)
        }
    }
}
