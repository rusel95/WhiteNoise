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
            // Background with gradient
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.1),
                        Color.white.opacity(0.05)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            
            GeometryReader(content: { geometry in
                ZStack(content: {
                    
                })
                .onAppear(perform: {
                    viewModel.maxWidth = geometry.size.width
                })
            })
            
            // MARK: Slider
            ZStack(alignment: .leading, content: {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.05))
                
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.1, green: 0.4, blue: 0.5).opacity(0.8),
                            Color(red: 0.05, green: 0.3, blue: 0.4).opacity(0.8)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(width: viewModel.sliderWidth, alignment: .leading)
                    .animation(.spring(), value: viewModel.sliderWidth)
                
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
            
            VStack(spacing: 12) {
                // Icon with background
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    switch viewModel.sound.icon {
                    case .system(let systemName):
                        Image(systemName: systemName)
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .allowsHitTesting(false)
                    case .custom(let name):
                        Image(name)
                            .resizable()
                            .frame(width: 24, height: 24)
                            .allowsHitTesting(false)
                    }
                }
                
                VStack(spacing: 6) {
                    Text(viewModel.sound.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .allowsHitTesting(false)
                    
                    if viewModel.sound.soundVariants.count > 1 {
                        Menu {
                            ForEach(viewModel.sound.soundVariants) { variant in
                                Button(variant.name) {
                                    viewModel.selectedSoundVariant = variant
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(viewModel.selectedSoundVariant.name)
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.8))
                                    .lineLimit(1)
                                
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 8))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
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
                }
            }
            .padding(.vertical, 16)
        }
    }
}

struct SoundView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            SoundView(viewModel: .init(
                sound: Sound(
                    name: "Rain",
                    icon: .system("cloud.rain"),
                    volume: 0.3,
                    selectedSoundVariant: nil,
                    soundVariants: [
                        .init(name: "Soft Rain", filename: "soft_rain"),
                        .init(name: "Heavy Rain", filename: "heavy_rain")
                    ]
                )
            ))
            .padding()
        }
    }
}
