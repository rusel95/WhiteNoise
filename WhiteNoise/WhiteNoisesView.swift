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
        ZStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(viewModel.soundsViewModels) { viewModel in
                        SoundView(viewModel: viewModel)
                    }
                }
            }
            .padding(.top)
            .frame(maxWidth: .infinity)
            .foregroundColor(Color.white)
            .background(Color("black90"))
            
            // MARK: - Bottom Controller
#if os(macOS)
            VStack {
                Spacer()
                
                HStack(spacing: 8) {
                    Button(action: {
                        if self.viewModel.isPlaying {
                            self.viewModel.pauseSounds()
                        } else {
                            self.viewModel.playSounds()
                        }
                    }) {
                        Image(systemName: viewModel.isPlaying ? "pause" : "play")
                            .resizable()
                            .frame(width: 30, height: 30)
                    }
                    .background(Color.clear)
                    .buttonStyle(PlainButtonStyle())
                    .padding(.vertical, 16)
                    .padding(.leading, 20)
                    
                    Menu {
                        ForEach(WhiteNoisesViewModel.TimerMode.allCases) { mode in
                            Button(mode.description) {
                                viewModel.timerMode = mode
                            }
                        }
                    } label: {
                        Image(systemName: "timer")
                            .resizable()
                            .frame(width: 30, height: 30)

                        Text(viewModel.timerMode.description)
                    }
                    .background(Color.clear)
                    .buttonStyle(PlainButtonStyle())
                    .padding(.vertical, 16)
                    .padding(.trailing, 20)
                    .frame(maxWidth: 100)
                }
                .background(Color.black)
                .clipShape(Capsule())
                .padding(.bottom, 10)
            }
#elseif os(iOS)
            VStack {
                Spacer()
                
                HStack(spacing: 20) {
                    Button(action: {
                        if self.viewModel.isPlaying {
                            self.viewModel.pauseSounds()
                        } else {
                            self.viewModel.playSounds()
                        }
                    }) {
                        Image(systemName: viewModel.isPlaying ? "pause" : "play")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                    }
                    .padding(.vertical, 8)
                    .padding(.leading, 20)
                    
                    Menu {
                        ForEach(WhiteNoisesViewModel.TimerMode.allCases) { mode in
                            Button(mode.description) {
                                viewModel.timerMode = mode
                            }
                        }
                    } label: {
                        Image(systemName: "timer")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)

                        Text(viewModel.timerMode.description)

                    }
                    .padding(.vertical, 8)
                    .padding(.trailing, 20)
                }
                .background(Color.black)
                .clipShape(Capsule())
                .padding(.bottom, 24)
            }
#endif
        }
        .ignoresSafeArea(.all, edges: .bottom)
    }

}

struct WhiteNoiseView_Previews: PreviewProvider {
    static var previews: some View {
        WhiteNoisesView(viewModel: .init())
    }
}
