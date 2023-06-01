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
        VStack(spacing: 0) {
            HStack {
                Text(viewModel.name)
                    .foregroundColor(.white)

                Spacer()
                
                Button(action: {
                    viewModel.isActive = !viewModel.isActive
                }) {
                    Image(systemName: viewModel.isActive ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .frame(width: 28, height: 28)
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            HStack {
                #if os(tvOS)
                FocusableView { isFocused in
                    viewModel.adjustVolume(to: isFocused ? 1 : 0)
                }
                #else
                Slider(value: $viewModel.volume, in: 0...1)
                #endif
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color.black.opacity(0.3))
        .cornerRadius(16)
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}
