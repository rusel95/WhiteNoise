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
        ZStack {
            GeometryReader(content: { geometry in
                ZStack(content: {
                    
                })
                .onAppear(perform: {
                    viewModel.maxWidth = geometry.size.width
                })
            })
            // MARK: Slider
            ZStack(alignment: .leading, content: {
                Rectangle()
                    .fill(Color.cyan.opacity(0.15))
                
                Rectangle()
                    .fill(Color.cyan)
                    .frame(width: viewModel.sliderWidth, alignment: .leading)
                
            })
            .onTapGesture { location in
                viewModel.sliderWidth = location.x
                viewModel.lastDragValue = location.x
                
                let progress = viewModel.sliderWidth / viewModel.maxWidth
                viewModel.volume = progress <= 1.0 ? Float(progress) : 1.0
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged({ value in
                        viewModel.dragDidChange(newTranslationWidth: value.translation.width)
                    })
                    .onEnded({ value in
                        viewModel.dragDidEnded()
                    })
            )
            
            // MARK: - icon
            VStack(spacing: 8) {
                switch viewModel.sound.icon {
                case .system(let systemName):
                    Image(systemName: systemName)
                        .frame(width: 20, height: 20)
                        .allowsHitTesting(false)
                case .custom(let name):
                    Image(name)
                        .resizable()
                        .frame(width: 20, height: 20)
                        .allowsHitTesting(false)
                }
                
                Text(viewModel.sound.name)
                    .font(.system(size: 18))
                    .fontWeight(.semibold)
                    .allowsHitTesting(false)
                
                Picker(
                    "", selection: $viewModel.selectedSoundVariant
                ) {
                    ForEach(viewModel.sound.soundVariants) { variant in
                        Text(variant.name)
                            .font(.system(size: 10))
                            .fontWeight(.ultraLight)
                            .tag(variant as Sound.SoundVariant)
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged({ value in
                            viewModel.dragDidChange(newTranslationWidth: value.translation.width)
                        })
                        .onEnded({ _ in
                            viewModel.dragDidEnded()
                        })
                )
            }
            .foregroundColor(.white)
            .padding(.vertical)
        }
        .cornerRadius(16)
    }
}

struct SoundView_Previews: PreviewProvider {
    static var previews: some View {
        SoundView(viewModel: .init(
            sound: Sound(
                name: "rain",
                icon: .system("tree"),
                volume: 0.3,
                selectedSoundVariant: nil,
                soundVariants: [
                    .init(name: "calm 2", filename: "calm Mediterrainean"),
                    .init(name: "variant", filename: "variant2")
                ]
            )
        ))
        .frame(width: 100, height: 100)
    }
}
