//
//  TimerPickerView.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 2025-07-26.
//

import SwiftUI
import UIKit

struct TimerPickerView: View {
    @Binding var timerMode: TimerService.TimerMode
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) private var colorScheme

    let timerOptions = TimerService.TimerMode.allCases

    @State private var selectedMode: TimerService.TimerMode
    @State private var showBackground: Bool = false

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var theme: ThemeColors {
        ThemeColors(colorScheme: colorScheme)
    }

    private var usesExpandedLayout: Bool {
        horizontalSizeClass == .regular && UIDevice.current.userInterfaceIdiom == .pad
    }

    private var containerWidth: CGFloat { usesExpandedLayout ? 380 : 300 }
    private var pickerHeight: CGFloat { usesExpandedLayout ? 220 : 160 }
    private var titleFont: Font {
        usesExpandedLayout
            ? .system(size: 24, weight: .bold, design: .rounded)
            : .system(size: 20, weight: .bold, design: .rounded)
    }
    private var doneButtonHeight: CGFloat { usesExpandedLayout ? 52 : 44 }
    private var doneButtonFont: Font {
        usesExpandedLayout
            ? .system(size: 18, weight: .semibold)
            : .system(size: 16, weight: .semibold)
    }

    init(timerMode: Binding<TimerService.TimerMode>, isPresented: Binding<Bool>) {
        self._timerMode = timerMode
        self._isPresented = isPresented
        self._selectedMode = State(initialValue: timerMode.wrappedValue)
    }

    var body: some View {
        ZStack {
            // Dimmed background - delayed fade in so edges aren't visible during container scale
            Color.black
                .opacity(showBackground ? (colorScheme == .dark ? 0.7 : 0.5) : 0)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.8), value: showBackground)
                .onTapGesture {
                    dismissPicker()
                }

            // Glass container
            VStack(spacing: 0) {
                // Header
                timerHeader

                // Picker
                timerPicker

                // Done button
                doneButton
            }
            .frame(width: containerWidth)
            .glassCard(cornerRadius: 28, opacity: 0.75)
            .scaleEffect(isPresented ? 1 : 0.9)
            .opacity(isPresented ? 1 : 0)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isPresented)
        }
        .onChange(of: isPresented) { _, newValue in
            if newValue {
                // Delay background fade-in until container has scaled up
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showBackground = true
                }
            } else {
                // Fade out background immediately when dismissing
                showBackground = false
            }
        }
    }

    // MARK: - Timer Header

    private var timerHeader: some View {
        HStack {
            Text(String(localized: "Sleep Timer"))
                .font(titleFont)
                .foregroundStyle(theme.textPrimary)

            Spacer()

            // Close button
            Button {
                dismissPicker()
            } label: {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 32, height: 32)
                        .overlay {
                            Circle()
                                .strokeBorder(
                                    Color.white.opacity(colorScheme == .dark ? 0.12 : 0.25),
                                    lineWidth: 1
                                )
                        }

                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(theme.textSecondary)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }

    // MARK: - Timer Picker

    private var timerPicker: some View {
        Picker("Timer", selection: $selectedMode) {
            ForEach(timerOptions, id: \.self) { option in
                Text(option.displayText)
                    .tag(option)
            }
        }
        .pickerStyle(.wheel)
        .frame(height: pickerHeight)
        .clipped()
        .onChange(of: selectedMode) { _, _ in
            HapticFeedbackService.shared.selection()
        }
    }

    // MARK: - Done Button

    private var doneButton: some View {
        Button {
            timerMode = selectedMode
            HapticFeedbackService.shared.impact(style: .medium)
            dismissPicker()
        } label: {
            Text(String(localized: "Done"))
                .font(doneButtonFont)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: doneButtonHeight)
                .background {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [theme.primary, theme.secondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
        .padding(.top, 8)
    }

    // MARK: - Helpers

    private func dismissPicker() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isPresented = false
        }
    }
}

// MARK: - Preview

struct TimerPickerView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ZStack {
                Color.black.ignoresSafeArea()
                TimerPickerView(
                    timerMode: .constant(.off),
                    isPresented: .constant(true)
                )
            }
            .preferredColorScheme(.dark)

            ZStack {
                Color.white.ignoresSafeArea()
                TimerPickerView(
                    timerMode: .constant(.off),
                    isPresented: .constant(true)
                )
            }
            .preferredColorScheme(.light)
        }
    }
}
