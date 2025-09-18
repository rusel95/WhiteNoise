//
//  SoundsView.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 30.05.2023.
//

import SwiftUI
#if os(iOS)
import UIKit
#endif

struct WhiteNoisesView: View {

    @ObservedObject var viewModel: WhiteNoisesViewModel
    private let hapticService: HapticFeedbackServiceProtocol = HapticFeedbackService.shared

    @State private var showPicker = false
    @State private var showTimerPicker = false

#if os(macOS)
    let columns = [GridItem(.adaptive(minimum: 150, maximum: 400))]
#elseif os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var usesExpandedLayout: Bool {
        horizontalSizeClass == .regular && UIDevice.current.userInterfaceIdiom == .pad
    }

    private var columns: [GridItem] {
        let minimum = usesExpandedLayout ? AppConstants.UI.minSoundCardWidth : AppConstants.UI.phoneMinSoundCardWidth
        let maximum = usesExpandedLayout ? AppConstants.UI.maxSoundCardWidth : AppConstants.UI.phoneMaxSoundCardWidth
        return [GridItem(
            .adaptive(minimum: minimum, maximum: maximum),
            spacing: gridSpacing
        )]
    }

    private var horizontalPadding: CGFloat {
        usesExpandedLayout ? AppConstants.UI.gridHorizontalPadding : 16
    }

    private var timeLabelFont: Font {
        usesExpandedLayout ? .system(size: 11, weight: .medium) : .system(size: 9, weight: .medium)
    }

    private var gridSpacing: CGFloat {
        usesExpandedLayout ? AppConstants.UI.soundGridSpacing : 16
    }

    private var controlButtonCornerRadius: CGFloat {
        usesExpandedLayout ? 20 : AppConstants.UI.phoneControlButtonCornerRadius
    }

    private var controlStackSpacing: CGFloat {
        usesExpandedLayout ? AppConstants.UI.controlStackSpacing : AppConstants.UI.phoneControlStackSpacing
    }

    private var controlTrayHorizontalInsets: CGFloat {
        usesExpandedLayout ? AppConstants.UI.controlTrayHorizontalInsets : AppConstants.UI.phoneControlTrayHorizontalInsets
    }

    private var controlContainerVerticalPadding: CGFloat {
        usesExpandedLayout ? AppConstants.UI.controlContainerVerticalPadding : AppConstants.UI.phoneControlContainerVerticalPadding
    }

    private var controlTrayCornerRadius: CGFloat {
        usesExpandedLayout ? AppConstants.UI.controlTrayCornerRadius : AppConstants.UI.phoneControlTrayCornerRadius
    }

    private var controlContainerHorizontalPadding: CGFloat {
        usesExpandedLayout ? AppConstants.UI.controlContainerHorizontalPadding : AppConstants.UI.phoneControlContainerHorizontalPadding
    }

    private var controlTrayBottomPadding: CGFloat {
        usesExpandedLayout ? AppConstants.UI.controlTrayBottomPadding : AppConstants.UI.phoneControlTrayBottomPadding
    }
#endif

    var body: some View {
        ZStack {
            // Pure black background
            Color.black
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: gridSpacing) {
                    // Sound grid
                    LazyVGrid(columns: columns, spacing: gridSpacing) {
                        ForEach(viewModel.soundsViewModels) { viewModel in
                            SoundView(viewModel: viewModel)
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.bottom, AppConstants.UI.bottomControllerPadding) // Space for bottom controller
                }
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(Color.white)
            
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
                        .foregroundColor(viewModel.timerMode != .off ? .cyan : .white)
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

                HStack(spacing: controlStackSpacing) {
                    // Play/Pause button
                    Button(action: {
                        viewModel.playingButtonSelected()
                    }) {
                        Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: AppConstants.UI.controlButtonIconSize, weight: .semibold))
                            .foregroundColor(.white)
                            .offset(x: viewModel.isPlaying ? 0 : 1)
                            .frame(width: AppConstants.UI.controlButtonSize, height: AppConstants.UI.controlButtonSize)
                            .background(
                                RoundedRectangle(cornerRadius: controlButtonCornerRadius)
                                    .fill(LinearGradient.primaryGradient)
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
                                .font(.system(size: AppConstants.UI.controlButtonIconSize - 2, weight: .medium))
                                .foregroundColor(.white)

                            if viewModel.timerMode != .off {
                                Text(viewModel.remainingTimerTime)
                                    .font(timeLabelFont)
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(width: AppConstants.UI.controlButtonSize, height: AppConstants.UI.controlButtonSize)
                        .background(
                            RoundedRectangle(cornerRadius: controlButtonCornerRadius)
                                .fill(viewModel.timerMode != .off ?
                                      LinearGradient.secondaryGradient :
                                      LinearGradient.glassEffect
                                )
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .frame(maxWidth: AppConstants.UI.controlTrayMaxWidth)
                .padding(.horizontal, controlTrayHorizontalInsets)
                .padding(.vertical, controlContainerVerticalPadding)
                .background(
                    RoundedRectangle(cornerRadius: controlTrayCornerRadius)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: controlTrayCornerRadius)
                                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                        )
                )
                .padding(.horizontal, controlContainerHorizontalPadding)
                .padding(.bottom, controlTrayBottomPadding)
            }
#endif
        }
        .ignoresSafeArea(.all, edges: .bottom)
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
