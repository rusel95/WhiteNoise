//
//  SoundView.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 31.05.2023.
//

import SwiftUI

struct SoundView: View {

    let viewModel: SoundViewModel
    let layout: AdaptiveLayout
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.hapticService) private var hapticService

    // MARK: - Slider Geometry (View-layer concern)
    @State private var sliderWidth: CGFloat = 0
    @State private var lastDragValue: CGFloat = 0
    @State private var maxWidth: CGFloat = 0
    @State private var isInteractive: Bool = false

    private var theme: ThemeColors {
        ThemeColors(colorScheme: colorScheme)
    }

    var body: some View {
        ZStack {
            // Glass background
            glassBackground

            // Volume slider layer
            volumeSlider

            // Content layer
            cardContent
        }
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.soundCardCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppConstants.UI.soundCardCornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.12 : 0.35),
                            Color.white.opacity(colorScheme == .dark ? 0.04 : 0.10)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.35 : 0.15),
            radius: colorScheme == .dark ? 12 : 16,
            x: 4,
            y: 8
        )
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.08),
            radius: 4,
            x: 2,
            y: 3
        )
    }

    // MARK: - Glass Background

    private var glassBackground: some View {
        GlassBackground(colorScheme: colorScheme, opacity: 0.45)
    }

    // MARK: - Volume Slider

    private var volumeSlider: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                Rectangle()
                    .fill(Color.primary.opacity(0.02))

                // Filled track with gradient
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                theme.primary.opacity(colorScheme == .dark ? 0.35 : 0.28),
                                theme.secondary.opacity(colorScheme == .dark ? 0.28 : 0.20)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(0, min(sliderWidth, geometry.size.width)))
            }
            .onAppear {
                maxWidth = geometry.size.width
                guard maxWidth > 0 else {
                    isInteractive = true
                    return
                }
                let target = CGFloat(viewModel.volume) * maxWidth
                if target > 0 {
                    // Animate fill-up from 0 on launch
                    sliderWidth = 0
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0...0.15)) {
                        withAnimation(.easeOut(duration: 0.5)) {
                            sliderWidth = target
                        }
                        lastDragValue = target
                        isInteractive = true
                    }
                } else {
                    isInteractive = true
                }
            }
            .onChange(of: geometry.size.width) { _, newWidth in
                maxWidth = newWidth
                sliderWidth = CGFloat(viewModel.volume) * newWidth
                lastDragValue = sliderWidth
            }
            .onTapGesture { location in
                guard isInteractive, maxWidth > 0 else { return }
                hapticService.impact(style: .light)
                sliderWidth = max(0, min(location.x, maxWidth))
                lastDragValue = sliderWidth
                viewModel.volume = Float(sliderWidth / maxWidth)
            }
            .gesture(volumeDragGesture)
        }
        .allowsHitTesting(isInteractive)
    }

    // MARK: - Card Content

    private var cardContent: some View {
        VStack(spacing: cardContentSpacing) {
            // Icon with glass background
            iconView

            // Title and variant selector
            VStack(spacing: textStackSpacing) {
                Text(viewModel.sound.name)
                    .font(.system(size: layout.soundTitleFontSize, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .allowsHitTesting(false)

                if viewModel.sound.soundVariants.count > 1 {
                    variantSelector
                }
            }
            .padding(.horizontal, 8)
        }
        .padding(.vertical, layout.soundCardVerticalPadding)
    }

    // MARK: - Icon View

    private var iconView: some View {
        ZStack {
            // Glass circle background
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: layout.soundIconSize, height: layout.soundIconSize)
                .overlay {
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(colorScheme == .dark ? 0.15 : 0.4),
                                    Color.white.opacity(colorScheme == .dark ? 0.05 : 0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }

            // Icon
            switch viewModel.sound.icon {
            case .system(let systemName):
                Image(systemName: systemName)
                    .font(.system(size: layout.soundNameFontSize, weight: .medium))
                    .foregroundStyle(theme.textPrimary)
                    .allowsHitTesting(false)

            case .custom(let name):
                Image(name)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(theme.textPrimary)
                    .frame(
                        width: layout.soundCardIconSize,
                        height: layout.soundCardIconSize
                    )
                    .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Variant Selector

    private var variantSelector: some View {
        Menu {
            ForEach(viewModel.sound.soundVariants) { variant in
                Button {
                    viewModel.selectedSoundVariant = variant
                    hapticService.impact(style: .light)
                } label: {
                    Text(variant.name)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(viewModel.selectedSoundVariant.name)
                    .font(.system(size: layout.soundVariantFontSize, weight: .medium))
                    .foregroundStyle(theme.textSecondary)
                    .lineLimit(1)

                Image(systemName: "chevron.down")
                    .font(.system(size: layout.soundVariantChevronSize, weight: .semibold))
                    .foregroundStyle(theme.textTertiary)
            }
            .padding(.horizontal, layout.soundVariantPaddingHorizontal)
            .padding(.vertical, layout.soundVariantPaddingVertical)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: layout.soundVariantCornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: layout.soundVariantCornerRadius, style: .continuous)
                    .strokeBorder(
                        Color.white.opacity(colorScheme == .dark ? 0.1 : 0.25),
                        lineWidth: 0.5
                    )
            }
        }
        // Allow volume slider drag gestures to continue even when starting on the variant selector
        .gesture(volumeDragGesture)
    }
}

// MARK: - Private Helpers

private extension SoundView {
    var cardContentSpacing: CGFloat {
        layout.isRegular ? 20 : 12
    }

    var textStackSpacing: CGFloat {
        layout.isRegular ? 10 : 6
    }

    var volumeDragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard isInteractive else { return }
                let newWidth = value.translation.width + lastDragValue
                sliderWidth = min(max(0, newWidth), maxWidth)
                let progress = maxWidth > 0 ? sliderWidth / maxWidth : 0
                viewModel.volume = Float(min(max(0, progress), 1.0))
            }
            .onEnded { _ in
                guard isInteractive else { return }
                sliderWidth = min(max(0, sliderWidth), maxWidth)
                lastDragValue = sliderWidth
            }
    }
}
