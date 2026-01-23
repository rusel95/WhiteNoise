//
//  SoundView.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 31.05.2023.
//

import SwiftUI

// Note: SF Symbols can be used with the SystemImage enum for type-safe access:
// Example: Image(system: .cloudRain) instead of Image(systemName: "cloud.rain")

struct SoundView: View {

    @ObservedObject var viewModel: SoundViewModel
    let layout: AdaptiveLayout
    private let hapticService: HapticFeedbackServiceProtocol = HapticFeedbackService.shared

    var body: some View {
        ZStack {
            // Background with gradient - using Rectangle instead of RoundedRectangle
            Rectangle()
                .fill(Color(UIColor.secondarySystemBackground))
                .overlay(LinearGradient.glassEffect.opacity(0.5)) // Subtle glass overlay
                .cornerRadius(AppConstants.UI.soundCardCornerRadius)

            GeometryReader(content: { geometry in
                ZStack(content: {
                    // MARK: Slider - without rounded corners on the track
                    ZStack(alignment: .leading) {
                        // Background track
                        Rectangle()
                            .fill(Color.primary.opacity(0.05))

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
                        .fill(Color.primary.opacity(0.1))
                        .frame(width: layout.soundIconSize, height: layout.soundIconSize)

                    switch viewModel.sound.icon {
                    case .system(let systemName):
                        Image(systemName: systemName)
                            .font(.system(size: layout.soundNameFontSize))
                            .foregroundColor(.primary)
                            .allowsHitTesting(false)
                    case .custom(let name):
                        // Using string-based Image initialization
                        // Swift generates asset symbols (e.g., Image.waterfall, Image.sea)
                        // which are available in the generated GeneratedAssetSymbols.swift file
                        Image(name)
                            .resizable()
                            .frame(
                                width: layout.soundCardIconSize,
                                height: layout.soundCardIconSize
                            )
                            .allowsHitTesting(false)
                    }
                }

                VStack(spacing: textStackSpacing) {
                    Text(viewModel.sound.name)
                        .font(.system(size: layout.soundTitleFontSize, weight: .semibold))
                        .foregroundColor(.primary)
                        .allowsHitTesting(false)

                    if viewModel.sound.soundVariants.count > 1 {
                        Menu {
                            ForEach(viewModel.sound.soundVariants) { variant in
                                Button(action: {
                                    viewModel.selectedSoundVariant = variant
                                    hapticService.impact(style: .light)
                                }) {
                                    Text(variant.name)
                                        .font(.system(size: layout.soundVariantFontSize))
                                        .foregroundColor(.primary.opacity(0.8))
                                        .lineLimit(1)
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(viewModel.selectedSoundVariant.name)
                                    .font(.system(size: layout.soundVariantFontSize))
                                    .foregroundColor(.primary.opacity(0.8))
                                    .lineLimit(1)

                                Image(systemName: "chevron.down")
                                    .font(.system(size: layout.soundVariantChevronSize))
                                    .foregroundColor(.primary.opacity(0.6))
                            }
                            .padding(.horizontal, layout.soundVariantPaddingHorizontal)
                            .padding(.vertical, layout.soundVariantPaddingVertical)
                            .background(Color.primary.opacity(0.1))
                            .cornerRadius(layout.soundVariantCornerRadius)
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
            .padding(.vertical, layout.soundCardVerticalPadding)
        }
    }
}

private extension SoundView {
    var cardContentSpacing: CGFloat {
        layout.isRegular ? 20 : 12
    }

    var textStackSpacing: CGFloat {
        layout.isRegular ? 10 : 6
    }
}
