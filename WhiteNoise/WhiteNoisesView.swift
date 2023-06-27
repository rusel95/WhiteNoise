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
        GridItem(.adaptive(minimum: 180, maximum: 180)),
    ]
    
    var body: some View {
        VStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(viewModel.soundsViewModels) { viewModel in
                        SoundView(viewModel: viewModel)
                    }
                }
            }
            
            // MARK: - Bottom Controller
            
            HStack(spacing: 30) {
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
                        Image(systemName: viewModel.isPlaying ? "pause" : "play")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 30, height: 30)
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
                        Image(systemName: "timer")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 30, height: 30)
#if os(macOS)
                        Text(viewModel.timerMode.description)
#endif
                    }

                    Spacer()
                }
            }
            .background(Color.black)
        }
        .frame(maxWidth: .infinity)
        .foregroundColor(Color.white)
        .background(Color("black90"))
    }

}

struct WhiteNoiseView_Previews: PreviewProvider {
    static var previews: some View {
        WhiteNoisesView(viewModel: .init())
    }
}
