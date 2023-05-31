//
//  SoundView.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 31.05.2023.
//

import SwiftUI

struct SoundView: View {

    @ObservedObject var viewModel: SoundViewModel

    var body: some View {
        VStack {
            HStack {
                Text(viewModel.sound.name)
                    .foregroundColor(.white)

                Spacer()
                
                Button(action: {
                    viewModel.isActive = !viewModel.isActive
                }) {
                    Image(systemName: viewModel.isActive ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .frame(width: 28, height: 28)
                }
            }

            HStack {
                #if os(tvOS)
                FocusableView { isFocused in
                    viewModel.adjustVolume(to: isFocused ? 1 : 0)
                }
                #else
                Slider(value: $viewModel.volume, in: 0...1, onEditingChanged: { _ in
                    viewModel.adjustVolume(to: viewModel.volume)
                })
                #endif
            }
        }
    }
}
