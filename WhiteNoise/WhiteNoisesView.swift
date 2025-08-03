//
//  SoundsView.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 30.05.2023.
//

import SwiftUI

struct WhiteNoisesView: View {

    @ObservedObject var viewModel: WhiteNoisesViewModel

    @State private var showPicker = false
    @State private var showTimerPicker = false

#if os(macOS)
    let columns = [GridItem(.adaptive(minimum: 150, maximum: 400))]
#elseif os(iOS)
    let columns = [GridItem(.adaptive(minimum: 100, maximum: 200))]
#endif
    
    var body: some View {
        ZStack {
            // Pure black background
            Color.black
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    // Sound grid
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(viewModel.soundsViewModels) { viewModel in
                            SoundView(viewModel: viewModel)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100) // Space for bottom controller
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
                
                HStack(spacing: 20) {
                    // Play/Pause button
                    Button(action: {
                        viewModel.playingButtonSelected()
                    }) {
                        Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .offset(x: viewModel.isPlaying ? 0 : 1)
                            .frame(width: 50, height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.2, green: 0.5, blue: 0.6),
                                            Color(red: 0.1, green: 0.4, blue: 0.5)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                            )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    // Timer button
                    Button(action: {
                        #if os(iOS)
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        #endif
                        
                        withAnimation(.spring()) {
                            showTimerPicker = true
                        }
                    }) {
                        VStack(spacing: 3) {
                            Image(systemName: "timer")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                            
                            if viewModel.timerMode != .off {
                                Text(viewModel.remainingTimerTime)
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(width: 50, height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(viewModel.timerMode != .off ?
                                      LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.1, green: 0.4, blue: 0.5),
                                            Color(red: 0.05, green: 0.3, blue: 0.4)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                      ) :
                                      LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.08),
                                            Color.white.opacity(0.05)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                      )
                                )
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 80)
                .padding(.bottom, 20)
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
