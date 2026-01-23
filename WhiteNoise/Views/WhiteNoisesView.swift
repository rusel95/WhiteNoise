//
//  SoundsView.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 30.05.2023.
//

import SwiftUI

struct WhiteNoisesView: View {

    @ObservedObject var viewModel: WhiteNoisesViewModel
    @Environment(\.colorScheme) private var colorScheme
    private let hapticService: HapticFeedbackServiceProtocol = HapticFeedbackService.shared

    @State private var showTimerPicker = false
    @State private var showSettings = false

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private var layout: AdaptiveLayout {
        AdaptiveLayout(horizontalSizeClass: horizontalSizeClass)
    }

    private var columns: [GridItem] {
        if layout.isRegular {
            return expandedLayoutColumns
        }
        return [GridItem(
            .adaptive(minimum: layout.minSoundCardWidth, maximum: layout.maxSoundCardWidth),
            spacing: layout.soundGridSpacing
        )]
    }

    private var expandedLayoutColumns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: layout.soundGridSpacing),
            count: expandedLayoutColumnCount
        )
    }

    private var expandedLayoutColumnCount: Int {
        if let verticalSizeClass, verticalSizeClass == .regular {
            return 3
        }
        return 4
    }

    private var theme: ThemeColors {
        ThemeColors(colorScheme: colorScheme)
    }

    var body: some View {
        ZStack {
            // Animated glass background
            AnimatedGlassBackground(
                primaryColor: theme.primary,
                secondaryColor: theme.secondary
            )

            ScrollView {
                VStack(spacing: layout.soundGridSpacing) {
                    Color.clear.frame(height: 20)

                    LazyVGrid(columns: columns, spacing: layout.soundGridSpacing) {
                        ForEach(viewModel.soundsViewModels) { soundVM in
                            SoundView(viewModel: soundVM, layout: layout)
                        }
                    }
                    .padding(.horizontal, layout.gridHorizontalPadding)
                    .padding(.bottom, layout.bottomControllerPadding + 20)
                }
            }
            .frame(maxWidth: .infinity)

            // MARK: - Glass Control Tray
            VStack {
                Spacer()
                glassControlTray
            }
        }
        .ignoresSafeArea(.all, edges: .bottom)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .overlay(timerPickerOverlay)
    }

    // MARK: - Glass Control Tray

    private var glassControlTray: some View {
        HStack(spacing: layout.isRegular ? 20 : 16) {
            // Timer button (left)
            timerButton

            // Play/Pause button (center) - larger
            playPauseButton

            // Settings button (right)
            settingsButton
        }
        .padding(.horizontal, layout.isRegular ? 24 : 20)
        .padding(.vertical, layout.isRegular ? 20 : 16)
        .glassCard(cornerRadius: layout.isRegular ? 36 : 30, opacity: 0.65)
        .padding(.horizontal, layout.gridHorizontalPadding)
        .padding(.bottom, layout.controlTrayBottomPadding)
    }

    private var settingsButton: some View {
        Button {
            hapticService.impact(style: .light)
            showSettings = true
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: layout.isRegular ? 26 : 22, weight: .semibold))
                .foregroundStyle(theme.textPrimary)
                .frame(
                    width: layout.isRegular ? 64 : 54,
                    height: layout.isRegular ? 64 : 54
                )
        }
        .buttonStyle(GlassIconButtonStyle(tint: theme.primary, isActive: false))
    }

    private var playPauseButton: some View {
        Button {
            hapticService.impact(style: .medium)
            viewModel.playingButtonSelected()
        } label: {
            Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: layout.isRegular ? 36 : 28, weight: .bold))
                .foregroundStyle(theme.textPrimary)
                .offset(x: viewModel.isPlaying ? 0 : 3)
                .frame(
                    width: layout.isRegular ? 88 : 72,
                    height: layout.isRegular ? 72 : 60
                )
        }
        .buttonStyle(GlassIconButtonStyle(tint: theme.primary, isActive: viewModel.isPlaying))
    }

    private var timerButton: some View {
        Button {
            hapticService.impact(style: .light)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showTimerPicker = true
            }
        } label: {
            VStack(spacing: 2) {
                Image(systemName: "timer")
                    .font(.system(size: layout.isRegular ? 24 : 20, weight: .semibold))
                    .foregroundStyle(theme.textPrimary)

                if viewModel.timerMode != .off {
                    Text(viewModel.remainingTimerTime)
                        .font(.system(size: layout.isRegular ? 12 : 10, weight: .medium))
                        .foregroundStyle(theme.textSecondary)
                        .monospacedDigit()
                }
            }
            .frame(
                width: layout.isRegular ? 64 : 54,
                height: layout.isRegular ? 64 : 54
            )
        }
        .buttonStyle(GlassIconButtonStyle(tint: theme.secondary, isActive: viewModel.timerMode != .off))
    }

    // MARK: - Timer Picker Overlay

    private var timerPickerOverlay: some View {
        ZStack {
            if showTimerPicker {
                TimerPickerView(
                    timerMode: $viewModel.timerMode,
                    isPresented: $showTimerPicker
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .zIndex(999)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showTimerPicker)
    }
}

// MARK: - Button Styles

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview

struct WhiteNoiseView_Previews: PreviewProvider {
    static var previews: some View {
        WhiteNoisesView(viewModel: .init())
    }
}
