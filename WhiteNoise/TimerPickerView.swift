//
//  TimerPickerView.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 2025-07-26.
//

import SwiftUI

struct TimerPickerView: View {
    @Binding var timerMode: WhiteNoisesViewModel.TimerMode
    @Binding var isPresented: Bool
    
    let timerOptions: [WhiteNoisesViewModel.TimerMode] = [
        .off, .oneMinute, .twoMinutes, .threeMinutes, 
        .fiveMinutes, .tenMinutes, .fifteenMinutes,
        .thirtyMinutes, .sixtyMinutes, .twoHours, 
        .threeHours, .fourHours, .fiveHours,
        .sixHours, .sevenHours, .eightHours
    ]
    
    @State private var selectedMode: WhiteNoisesViewModel.TimerMode
    
    init(timerMode: Binding<WhiteNoisesViewModel.TimerMode>, isPresented: Binding<Bool>) {
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
                        Text(displayText(for: option))
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
                    // Haptic feedback only
                    #if os(iOS)
                    let selectionFeedback = UISelectionFeedbackGenerator()
                    selectionFeedback.selectionChanged()
                    #endif
                }
                
                Button(action: {
                    // Apply the selected timer mode
                    timerMode = selectedMode
                    
                    // Haptic feedback
                    #if os(iOS)
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    #endif
                    
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
                                .fill(Color(red: 0.1, green: 0.4, blue: 0.5))
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
    
    func displayText(for option: WhiteNoisesViewModel.TimerMode) -> String {
        switch option {
        case .off:
            return "Off"
        case .oneMinute:
            return "1 minute"
        case .twoMinutes:
            return "2 minutes"
        case .threeMinutes:
            return "3 minutes"
        case .fiveMinutes:
            return "5 minutes"
        case .tenMinutes:
            return "10 minutes"
        case .fifteenMinutes:
            return "15 minutes"
        case .thirtyMinutes:
            return "30 minutes"
        case .sixtyMinutes:
            return "1 hour"
        case .twoHours:
            return "2 hours"
        case .threeHours:
            return "3 hours"
        case .fourHours:
            return "4 hours"
        case .fiveHours:
            return "5 hours"
        case .sixHours:
            return "6 hours"
        case .sevenHours:
            return "7 hours"
        case .eightHours:
            return "8 hours"
        }
    }
}

struct TimerPickerView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            TimerPickerView(
                timerMode: .constant(.off),
                isPresented: .constant(true)
            )
        }
    }
}
