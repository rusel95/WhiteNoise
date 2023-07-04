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
            // MARK: Slider
            ZStack(alignment: .leading, content: {
                Rectangle()
                    .fill(Color.cyan.opacity(0.15))
                
                Rectangle()
                    .fill(Color.cyan)
                    .frame(width: viewModel.sliderWidth, alignment: .leading)
                    .animation(.spring())
                
            })
            .onTapGesture { location in
                viewModel.sliderWidth = location.x
                viewModel.lastDragValue = location.x
                
                let progress = viewModel.sliderWidth / viewModel.maxWidth
                viewModel.volume = progress <= 1.0 ? progress : 1.0
            }
            .highPriorityGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged({ value in
                        viewModel.dragDidChange(newTranslationWidth: value.translation.width)
                    })
                    .onEnded({ value in
                        viewModel.dragDidEnded()
                    })
            )
            
            VStack(spacing: 8) {
                switch viewModel.sound.icon {
                case .system(let systemName):
                    Image(systemName: systemName)
                        .frame(width: 20, height: 20)
                case .custom(let name):
                    Image(name)
                        .resizable()
                        .frame(width: 20, height: 20)
                }
                
                Text(viewModel.sound.name)
                    .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                
                Picker(
                    "", selection: $viewModel.selectedSoundVariant
                ) {
                    ForEach(viewModel.sound.soundVariants) { variant in
                        Text(variant.name)
                            .tag(variant as Sound.SoundVariant)
                    }
                }
                .font(.system(size: 8))
                .highPriorityGesture(
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
            .padding(16)
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
                    .init(name: "calm Mediterrainean", filename: "calm Mediterrainean"),
                    .init(name: "variant", filename: "variant2")
                ]
            )
        ))
    }
}
