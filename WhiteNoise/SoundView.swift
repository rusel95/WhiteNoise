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
        VStack(spacing: 8) {
            Image(systemName: "magazine")
            
            HStack {
                Picker(
                    viewModel.sound.name, selection: $viewModel.selectedSoundVariant
                ) {
                    ForEach(viewModel.sound.soundVariants) { variant in
                        Text(variant.name).tag(variant as Sound.SoundVariant)
                    }
                }
                
//                Button(action: {
//                    viewModel.isActive = !viewModel.isActive
//                }) {
//                    Image(systemName: viewModel.isActive ? "speaker.wave.2.fill" : "speaker.slash.fill")
//                        .frame(width: 28, height: 28)
//                        .foregroundColor(.white)
//                }
            }
//            .frame(width: 130, height: 130)
            .padding(8)
        }
        .background(Color.black.opacity(0.2))
        .cornerRadius(8)
        .padding(8)
        .frame(width: 150, height: 150)
    }
}

struct SoundView_Previews: PreviewProvider {
    static var previews: some View {
        SoundView(viewModel:
                .init( sound: Sound(
                name: "rain",
                volume: 0.3,
                isActive: true,
                selectedSoundVariant: nil,
                soundVariants: [
                    .init(name: "variant1", filename: "variant1"),
                    .init(name: "variant", filename: "variant2")
                ]
            )
        ))
    }
}
