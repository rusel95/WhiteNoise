//
//  SoundView.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 31.05.2023.
//

import SwiftUI

struct SoundView: View {

    @ObservedObject var viewModel: SoundViewModel
    
    @State var lastDragValue: CGFloat = 0
    
    var body: some View {
        ZStack {
            // MARK: Slider
            ZStack(alignment: .leading, content: {
                Rectangle()
                    .fill(Color.accentColor.opacity(0.15))
                
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(width: viewModel.sliderWidth)
                
            })
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged({ value in
                        let translation = value.translation
                        viewModel.sliderWidth = translation.width + lastDragValue
                        
                        viewModel.sliderWidth = viewModel.sliderWidth > viewModel.maxWidth ? viewModel.maxWidth : viewModel.sliderWidth
                        viewModel.sliderWidth = viewModel.sliderWidth >= 0 ? viewModel.sliderWidth : 0
                    })
                    .onEnded({ value in
                        viewModel.sliderWidth = viewModel.sliderWidth > viewModel.maxWidth ? viewModel.maxWidth : viewModel.sliderWidth
                        viewModel.sliderWidth = viewModel.sliderWidth >= 0 ? viewModel.sliderWidth : 0
                        
                        lastDragValue = viewModel.sliderWidth
                        let progress = viewModel.sliderWidth / viewModel.maxWidth
                        viewModel.volume = progress <= 1.0 ? progress : 1.0
                    })
            )
            
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: viewModel.sound.selectedSoundVariant.iconName)
                    Image(systemName: viewModel.isActive ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .frame(width: 20, height: 20)
                }
                
                Text(viewModel.sound.name)
                
                Picker(
                    "", selection: $viewModel.selectedSoundVariant
                ) {
                    ForEach(viewModel.sound.soundVariants) { variant in
                        Text(variant.name).tag(variant as Sound.SoundVariant)
                    }
                }
            }
            .foregroundColor(.white)
            .padding(8)
        }
        .cornerRadius(8)
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
                    .init(name: "calm Mediterrainean", filename: "calm Mediterrainean"),
                    .init(name: "variant", filename: "variant2")
                ]
            )
        ))
    }
}
