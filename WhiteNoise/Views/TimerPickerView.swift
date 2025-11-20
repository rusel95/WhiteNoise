//
//  TimerPickerView.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 2025-07-26.
//

import SwiftUI
#if os(iOS)
import UIKit
#endif

struct TimerPickerView: View {
    @Binding var timerMode: TimerService.TimerMode
    @Binding var isPresented: Bool

    let timerOptions = TimerService.TimerMode.allCases

    @State private var selectedMode: TimerService.TimerMode

#if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var usesExpandedLayout: Bool {
        horizontalSizeClass == .regular && UIDevice.current.userInterfaceIdiom == .pad
    }
    
    private var containerWidth: CGFloat { usesExpandedLayout ? 360 : 280 }
    private var pickerHeight: CGFloat { usesExpandedLayout ? 220 : 150 }
    private var titleFont: Font { usesExpandedLayout ? .system(size: 22, weight: .semibold) : .headline }
    private var optionFont: Font { usesExpandedLayout ? .system(size: 18) : .system(size: 16) }
    private var doneButtonSize: CGSize { usesExpandedLayout ? CGSize(width: 140, height: 48) : CGSize(width: 100, height: 40) }
    private var doneButtonFont: Font { usesExpandedLayout ? .system(size: 18, weight: .semibold) : .system(size: 16, weight: .medium) }
#else
    private let containerWidth: CGFloat = 280
    private let pickerHeight: CGFloat = 150
    private let titleFont: Font = .headline
    private let optionFont: Font = .system(size: 16)
    private let doneButtonSize: CGSize = CGSize(width: 100, height: 40)
    private let doneButtonFont: Font = .system(size: 16, weight: .medium)
#endif
    
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
                Text(String(localized: "Sleep Timer"))
                    .font(titleFont)
                    .foregroundColor(.primary)
                    .padding(.top, 20)

                // Native Picker with wheel style
                Picker("Timer", selection: $selectedMode) {
                    ForEach(timerOptions, id: \.self) { option in
                        Text(option.displayText)
                            .font(optionFont)
                            .tag(option)
                            .foregroundColor(.primary)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(height: pickerHeight)
                .clipped()
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
                    Text(String(localized: "Done"))
                        .font(doneButtonFont)
                        .foregroundColor(.white)
                        .frame(width: doneButtonSize.width, height: doneButtonSize.height)
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
            .frame(width: containerWidth)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
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
