//
//  SoundView.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 31.05.2023.
//

import SwiftUI

struct SoundView: View {

    @ObservedObject var viewModel: SoundViewModel
    private let hapticService: HapticFeedbackServiceProtocol = HapticFeedbackService.shared
    
    var body: some View {
        ZStack {
            // Background with gradient - using Rectangle instead of RoundedRectangle
            Rectangle()
                .fill(LinearGradient.glassEffect)
                .cornerRadius(AppConstants.UI.soundCardCornerRadius) // Apply corner radius to the rectangle
            
            GeometryReader(content: { geometry in
                ZStack(content: {
                    // MARK: Slider - without rounded corners on the track
                    ZStack(alignment: .leading) {
                        // Background track
                        Rectangle()
                            .fill(Color.white.opacity(0.05))
                        
                        // Filled track
                        Rectangle()
                            .fill(LinearGradient.secondaryGradient.opacity(AppConstants.UI.volumeSliderBackgroundOpacity))
                            .frame(width: max(0, min(viewModel.sliderWidth, geometry.size.width)))
                            .animation(.spring(), value: viewModel.sliderWidth)
                    }
                })
                .onAppear(perform: {
                    viewModel.maxWidth = geometry.size.width
                })
                .onChange(of: geometry.size.width) { _, newWidth in
                    viewModel.maxWidth = newWidth
                }
                .onTapGesture { location in
                    viewModel.sliderWidth = max(0, min(location.x, viewModel.maxWidth))
                    viewModel.lastDragValue = viewModel.sliderWidth
                    
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
            })
            .clipShape(RoundedRectangle(cornerRadius: 20)) // Clip the entire GeometryReader
            
            VStack(spacing: 12) {
                // Icon with background
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    switch viewModel.sound.icon {
                    case .system(let systemName):
                        Image(systemName: systemName)
                            .font(.system(size: AppConstants.UI.soundNameFontSize))
                            .foregroundColor(.white)
                            .allowsHitTesting(false)
                    case .custom(let name):
                        Image(name)
                            .resizable()
                            .frame(width: AppConstants.UI.soundCardIconSize, height: AppConstants.UI.soundCardIconSize)
                            .allowsHitTesting(false)
                    }
                }
                
                VStack(spacing: 6) {
                    Text(viewModel.sound.name)
                        .font(.system(size: AppConstants.UI.soundTitleFontSize, weight: .semibold))
                        .foregroundColor(.white)
                        .allowsHitTesting(false)
                    
                    if viewModel.sound.soundVariants.count > 1 {
                        Menu {
                            ForEach(viewModel.sound.soundVariants) { variant in
                                Button(action: {
                                    viewModel.selectedSoundVariant = variant
                                    hapticService.impact(style: .light)
                                }) {
                                    Label(variant.name, systemImage: "waveform")
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(viewModel.selectedSoundVariant.name)
                                    .font(.system(size: AppConstants.UI.soundVariantFontSize))
                                    .foregroundColor(.white.opacity(0.8))
                                    .lineLimit(1)
                                
                                Image(systemName: "chevron.down")
                                    .font(.system(size: AppConstants.UI.soundVariantChevronSize))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .padding(.horizontal, AppConstants.UI.soundVariantPaddingHorizontal)
                            .padding(.vertical, AppConstants.UI.soundVariantPaddingVertical)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(AppConstants.UI.soundVariantCornerRadius)
                        }
                        .environment(\.colorScheme, .dark)
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
                sound: (try? Sound.create(
                    name: "Rain",
                    icon: .system("cloud.rain"),
                    volume: 0.3,
                    selectedSoundVariant: nil,
                    soundVariants: [
                        .init(name: "Soft Rain", filename: "soft_rain"),
                        .init(name: "Heavy Rain", filename: "heavy_rain")
                    ]
                )) ?? Sound(
                    name: "Rain",
                    icon: .system("cloud.rain"),
                    volume: 0.3,
                    selectedSoundVariant: nil,
                    soundVariants: [
                        .init(name: "Soft Rain", filename: "soft_rain"),
                        .init(name: "Heavy Rain", filename: "heavy_rain")
                    ]
                )!
            ))
            .padding()
        }
    }
}
