//
//  TimerPickerView.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 2025-07-26.
//

import SwiftUI

struct TimerPickerView: View {
    @Binding var timerMode: TimerService.TimerMode
    @Binding var isPresented: Bool
    
    let timerOptions = TimerService.TimerMode.allCases
    
    @State private var selectedMode: TimerService.TimerMode
    
    init(timerMode: Binding<TimerService.TimerMode>, isPresented: Binding<Bool>) {
        self._timerMode = timerMode
        self._isPresented = isPresented
        self._selectedMode = State(initialValue: timerMode.wrappedValue)
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.9)
                .ignoresSafeArea()
                .opacity(isPresented ? 1 : 0)
                .animation(.easeInOut(duration: 0.3), value: isPresented)
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                }
            
            VStack(spacing: 20) {
                Text("Sleep Timer")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                // Native Picker with wheel style
                Picker("Timer", selection: $selectedMode) {
                    ForEach(timerOptions, id: \.self) { option in
                        Text(option.displayText)
                            .font(.system(size: 16))
                            .tag(option)
                            .foregroundColor(.white)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(height: 150)
                .clipped()
                .colorScheme(.dark)
                .onChange(of: selectedMode) { _, _ in
                    HapticFeedbackService.shared.selection()
                }
                
                Button(action: {
                    // Apply the selected timer mode
                    timerMode = selectedMode
                    
                    HapticFeedbackService.shared.impact(style: .medium)
                    
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                }) {
                    Text("Done")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 100, height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.1, green: 0.4, blue: 0.5),
                                        Color(red: 0.05, green: 0.3, blue: 0.4)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                        )
                }
                .padding(.bottom, 20)
            }
            .frame(width: 280)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color(white: 0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .scaleEffect(isPresented ? 1 : 0.9)
            .opacity(isPresented ? 1 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPresented)
        }
    }
}

struct TimerPickerView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            TimerPickerView(
                timerMode: .constant(TimerService.TimerMode.off),
                isPresented: .constant(true)
            )
        }
    }
}
