//
//  SoundView.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 31.05.2023.
//

import SwiftUI
#if os(iOS)
import UIKit
#endif

struct SoundView: View {

    @ObservedObject var viewModel: SoundViewModel
    private let hapticService: HapticFeedbackServiceProtocol = HapticFeedbackService.shared
#if os(iOS)
    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
#endif
    
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
                    guard viewModel.isVolumeInteractive else { return }
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
            .allowsHitTesting(viewModel.isVolumeInteractive)
            
            VStack(spacing: cardContentSpacing) {
                // Icon with background
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: AppConstants.UI.soundIconSize, height: AppConstants.UI.soundIconSize)
                    
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
                
                VStack(spacing: textStackSpacing) {
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
                                    Text(variant.name)
                                        .font(.system(size: AppConstants.UI.soundVariantFontSize))
                                        .foregroundColor(.white.opacity(0.8))
                                        .lineLimit(1)
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
            .padding(.vertical, AppConstants.UI.soundCardVerticalPadding)
        }
    }
}

private extension SoundView {
    var cardContentSpacing: CGFloat {
#if os(iOS)
        return isPad ? 20 : 12
#else
        return 12
#endif
    }
    
    var textStackSpacing: CGFloat {
#if os(iOS)
        return isPad ? 10 : 6
#else
        return 6
#endif
    }
}
