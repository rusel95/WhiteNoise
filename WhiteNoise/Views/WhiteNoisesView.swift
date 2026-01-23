//
//  SoundsView.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 30.05.2023.
//

import SwiftUI

struct WhiteNoisesView: View {

    @ObservedObject var viewModel: WhiteNoisesViewModel
    private let hapticService: HapticFeedbackServiceProtocol = HapticFeedbackService.shared

    @State private var showPicker = false
    @State private var showTimerPicker = false
    @State private var showSettings = false

#if os(macOS)
    let columns = [GridItem(.adaptive(minimum: 150, maximum: 400))]
    private let layout = AdaptiveLayout(horizontalSizeClass: nil)
#elseif os(iOS)
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
#endif

    var body: some View {
        ZStack {
            // Adaptive background
            Color(UIColor.systemBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: layout.soundGridSpacing) {
                    // Header spacer to keep grid pushed down slightly if needed
                    Color.clear.frame(height: 20)

                    // Sound grid
                    LazyVGrid(columns: columns, spacing: layout.soundGridSpacing) {
                        ForEach(viewModel.soundsViewModels) { soundVM in
                            SoundView(viewModel: soundVM, layout: layout)
                        }
                    }
                    .padding(.horizontal, layout.gridHorizontalPadding)
                    .padding(.bottom, layout.bottomControllerPadding)
                }
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(.primary)

            // MARK: - Bottom Controller
#if os(macOS)
            VStack {
                Spacer()

                HStack(spacing: 20) {
                    Button(action: {
                        viewModel.playingButtonSelected()
                    }) {
                        Image(systemName: viewModel.isPlaying ? "pause" : "play")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                    }
                    .background(Color.clear)
                    .buttonStyle(PlainButtonStyle())
                    .padding(.vertical, 20)
                    .padding(.leading, 24)

                    Menu {
                        ForEach(WhiteNoisesViewModel.TimerMode.allCases) { mode in
                            Button(mode.description) {
                                viewModel.timerMode = mode
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "timer")
                                .resizable()
                                .frame(width: 30, height: 30)
                            if viewModel.timerMode != .off {
                                Text(viewModel.remainingTimerTime)
                                    .frame(width: 60)
                            }
                        }
                        .foregroundColor(viewModel.timerMode != .off ? .cyan : .primary)
                    }
                    .background(Color.clear)
                    .buttonStyle(PlainButtonStyle())
                    .padding(.vertical, 20)
                    .padding(.trailing, 24)
                }
                .background(Color("black90"))
                .clipShape(Capsule())
                .padding(.bottom, 10)
                .animation(.spring())
            }
#elseif os(iOS)
            VStack {
                Spacer()

                HStack(spacing: layout.controlStackSpacing) {
                    // Play/Pause button
                    Button(action: {
                        viewModel.playingButtonSelected()
                    }) {
                        Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: layout.controlButtonIconSize, weight: .semibold))
                            .foregroundColor(.primary)
                            .offset(x: viewModel.isPlaying ? 0 : 1)
                            .frame(width: layout.controlButtonSize, height: layout.controlButtonSize)
                            .background(
                                RoundedRectangle(cornerRadius: layout.controlButtonCornerRadius)
                                    .fill(LinearGradient.glassEffect)
                            )
                    }
                    .buttonStyle(ScaleButtonStyle())

                    // Timer button
                    Button(action: {
                        hapticService.impact(style: .light)

                        withAnimation(.spring()) {
                            showTimerPicker = true
                        }
                    }) {
                        VStack(spacing: 3) {
                            Image(systemName: "timer")
                                .font(.system(size: layout.controlButtonIconSize - 2, weight: .medium))
                                .foregroundColor(.primary)

                            if viewModel.timerMode != .off {
                                Text(viewModel.remainingTimerTime)
                                    .font(layout.timeLabelFont)
                                    .foregroundColor(.primary)
                            }
                        }
                        .frame(width: layout.controlButtonSize, height: layout.controlButtonSize)
                        .background(
                            RoundedRectangle(cornerRadius: layout.controlButtonCornerRadius)
                                .fill(viewModel.timerMode != .off ?
                                      LinearGradient.secondaryGradient :
                                      LinearGradient.glassEffect
                                )
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .frame(maxWidth: layout.controlTrayMaxWidth)
                .padding(.horizontal, layout.controlTrayHorizontalInsets)
                .padding(.vertical, layout.controlContainerVerticalPadding)
                .background(
                    RoundedRectangle(cornerRadius: layout.controlTrayCornerRadius)
                        .fill(Color.primary.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: layout.controlTrayCornerRadius)
                                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                        )
                )
                .padding(.horizontal, layout.controlContainerHorizontalPadding)
                .padding(.bottom, layout.controlTrayBottomPadding)
            }
            .overlay(alignment: .bottomTrailing) {
                Button(action: {
                    hapticService.impact(style: .light)
                    showSettings = true
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: layout.controlButtonIconSize, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: layout.controlButtonSize, height: layout.controlButtonSize)
                        .background(
                            RoundedRectangle(cornerRadius: layout.controlButtonCornerRadius)
                                .fill(LinearGradient.glassEffect)
                        )
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.trailing, layout.gridHorizontalPadding)
                .padding(.bottom, layout.controlTrayBottomPadding)
            }
#endif
        }
        .ignoresSafeArea(.all, edges: .bottom)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .overlay(
            // Timer picker overlay
            ZStack {
                if showTimerPicker {
                    TimerPickerView(
                        timerMode: $viewModel.timerMode,
                        isPresented: $showTimerPicker
                    )
                    .transition(AnyTransition.opacity)
                    .zIndex(999)
                }
            }
            .animation(.spring(), value: showTimerPicker)
        )
    }

}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct WhiteNoiseView_Previews: PreviewProvider {
    static var previews: some View {
        WhiteNoisesView(viewModel: .init())
    }
}
