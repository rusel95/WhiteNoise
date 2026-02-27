//
//  TimerPickerView.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 2025-07-26.
//

import SwiftUI

struct TimerPickerView: View {
    @Binding var timerMode: TimerService.TimerMode
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.hapticService) private var hapticService

    @State private var selectedMode: TimerService.TimerMode
    @State private var showCustomPicker: Bool = false
    @State private var customHours: Int = 0
    @State private var customMinutes: Int = 30

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var theme: ThemeColors {
        ThemeColors(colorScheme: colorScheme)
    }

    private var usesExpandedLayout: Bool {
        horizontalSizeClass == .regular && UIDevice.current.userInterfaceIdiom == .pad
    }

    // Quick presets - most commonly used (prominent at top)
    private var quickPresets: [TimerService.TimerMode] {
        [.fifteenMinutes, .thirtyMinutes, .sixtyMinutes, .twoHours]
    }

    // All other presets in a grid
    private var allPresets: [TimerService.TimerMode] {
        [
            .fiveMinutes, .tenMinutes, .fifteenMinutes, .thirtyMinutes,
            .sixtyMinutes, .twoHours, .threeHours, .fourHours,
            .sixHours, .eightHours
        ]
    }

    init(timerMode: Binding<TimerService.TimerMode>) {
        self._timerMode = timerMode
        self._selectedMode = State(initialValue: timerMode.wrappedValue)
    }

    var body: some View {
        ZStack {
            // Animated glass background - soft purple/lavender for sleep timer
            AnimatedGlassBackground(
                primaryColor: colorScheme == .dark ? Color(hex: "7C6AE8") : Color(hex: "6858D8"),
                secondaryColor: colorScheme == .dark ? Color(hex: "9B8AEF") : Color(hex: "8578E0")
            )

            VStack(spacing: 0) {
                // Header
                glassHeader

                // Content
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        if showCustomPicker {
                            customTimePicker
                        } else {
                            presetContent
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Glass Header

    private var glassHeader: some View {
        HStack {
            if showCustomPicker {
                // Back button
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showCustomPicker = false
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text(String(localized: "Back"))
                            .font(.system(size: 17, weight: .medium))
                    }
                    .foregroundStyle(theme.primary)
                }

                Spacer()

                Text(String(localized: "Custom"))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.textPrimary)
            } else {
                Text(String(localized: "Sleep Timer"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.textPrimary)
            }

            Spacer()

            // Close button
            Button {
                dismiss()
            } label: {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 36, height: 36)
                        .overlay {
                            Circle()
                                .strokeBorder(
                                    Color.white.opacity(colorScheme == .dark ? 0.12 : 0.25),
                                    lineWidth: 1
                                )
                        }

                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(theme.textSecondary)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }

    // MARK: - Preset Content

    private var presetContent: some View {
        VStack(spacing: 16) {
            // Quick presets - large, prominent buttons
            quickPresetsSection

            // Divider
            Rectangle()
                .fill(Color.white.opacity(colorScheme == .dark ? 0.1 : 0.15))
                .frame(height: 1)
                .padding(.vertical, 4)

            // All presets grid
            allPresetsGrid

            // Custom time option
            customTimeButton

            // Turn off option (if timer is active)
            if !selectedMode.isOff {
                turnOffButton
            }
        }
    }

    // MARK: - Quick Presets Section

    private var quickPresetsSection: some View {
        HStack(spacing: 10) {
            ForEach(quickPresets, id: \.self) { mode in
                QuickPresetButton(
                    mode: mode,
                    isSelected: selectedMode == mode,
                    theme: theme,
                    colorScheme: colorScheme,
                    isExpanded: usesExpandedLayout
                ) {
                    selectAndDismiss(mode)
                }
            }
        }
    }

    // MARK: - All Presets Grid

    private var allPresetsGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "All Durations"))
                .font(.system(size: usesExpandedLayout ? 13 : 11, weight: .semibold))
                .foregroundStyle(theme.textSecondary)
                .textCase(.uppercase)
                .tracking(0.5)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8)
                ],
                spacing: 8
            ) {
                ForEach(allPresets, id: \.self) { mode in
                    CompactDurationChip(
                        mode: mode,
                        isSelected: selectedMode == mode,
                        theme: theme,
                        colorScheme: colorScheme,
                        isExpanded: usesExpandedLayout
                    ) {
                        selectAndDismiss(mode)
                    }
                }
            }
        }
    }

    // MARK: - Custom Time Button

    private var customTimeButton: some View {
        Button {
            hapticService.selection()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showCustomPicker = true
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: usesExpandedLayout ? 18 : 16, weight: .medium))
                    .foregroundStyle(theme.primary)

                Text(String(localized: "Custom Duration"))
                    .font(.system(size: usesExpandedLayout ? 16 : 14, weight: .medium))
                    .foregroundStyle(theme.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: usesExpandedLayout ? 14 : 12, weight: .semibold))
                    .foregroundStyle(theme.textTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .glassInset(cornerRadius: 14, opacity: 0.5)
        }
        .buttonStyle(TimerOptionButtonStyle())
    }

    // MARK: - Turn Off Button

    private var turnOffButton: some View {
        Button {
            selectAndDismiss(.off)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "moon.zzz")
                    .font(.system(size: usesExpandedLayout ? 18 : 16, weight: .medium))
                    .foregroundStyle(theme.textSecondary)

                Text(String(localized: "Turn Off Timer"))
                    .font(.system(size: usesExpandedLayout ? 16 : 14, weight: .medium))
                    .foregroundStyle(theme.textPrimary)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .glassInset(cornerRadius: 14, opacity: 0.5)
        }
        .buttonStyle(TimerOptionButtonStyle())
    }

    // MARK: - Custom Time Picker

    private var customTimePicker: some View {
        VStack(spacing: 24) {
            HStack(spacing: 0) {
                // Hours picker
                VStack(spacing: 4) {
                    Text(String(localized: "Hours"))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(theme.textSecondary)

                    Picker("Hours", selection: $customHours) {
                        ForEach(0..<13, id: \.self) { hour in
                            Text("\(hour)")
                                .tag(hour)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 100, height: 150)
                    .clipped()
                }

                Text(":")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(theme.textSecondary)
                    .padding(.top, 24)

                // Minutes picker
                VStack(spacing: 4) {
                    Text(String(localized: "Minutes"))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(theme.textSecondary)

                    Picker("Minutes", selection: $customMinutes) {
                        ForEach([0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55], id: \.self) { minute in
                            Text(String(format: "%02d", minute))
                                .tag(minute)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 100, height: 150)
                    .clipped()
                }
            }
            .onChange(of: customHours) { _, _ in
                hapticService.selection()
            }
            .onChange(of: customMinutes) { _, _ in
                hapticService.selection()
            }

            // Set button
            Button {
                setCustomDuration()
            } label: {
                Text(customTimeDisplayText)
                    .font(.system(size: usesExpandedLayout ? 17 : 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: usesExpandedLayout ? 54 : 50)
                    .background {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: isValidCustomDuration
                                        ? [theme.primary, theme.secondary]
                                        : [Color.gray.opacity(0.5), Color.gray.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(
                                Color.white.opacity(0.2),
                                lineWidth: 1
                            )
                    }
            }
            .disabled(!isValidCustomDuration)
        }
        .padding(.top, 8)
    }

    private var isValidCustomDuration: Bool {
        customHours > 0 || customMinutes > 0
    }

    private var customTimeDisplayText: String {
        if !isValidCustomDuration {
            return String(localized: "Select Duration")
        }

        if customHours == 0 {
            return String(localized: "Set \(customMinutes) min")
        } else if customMinutes == 0 {
            return customHours == 1
                ? String(localized: "Set 1 hour")
                : String(localized: "Set \(customHours) hours")
        } else {
            return String(localized: "Set \(customHours)h \(customMinutes)m")
        }
    }

    // MARK: - Helpers

    private func selectAndDismiss(_ mode: TimerService.TimerMode) {
        hapticService.impact(style: .medium)
        timerMode = mode
        dismiss()
    }

    private func setCustomDuration() {
        let totalSeconds = (customHours * 3600) + (customMinutes * 60)
        guard totalSeconds > 0 else { return }

        // Check if it matches a preset first
        if let matchingPreset = TimerService.TimerMode.presets.first(where: { $0.totalSeconds == totalSeconds }) {
            selectAndDismiss(matchingPreset)
        } else {
            // Use custom duration
            selectAndDismiss(.custom(seconds: totalSeconds))
        }
    }
}

// MARK: - Quick Preset Button

private struct QuickPresetButton: View {
    let mode: TimerService.TimerMode
    let isSelected: Bool
    let theme: ThemeColors
    let colorScheme: ColorScheme
    let isExpanded: Bool
    let action: () -> Void

    private var shortLabel: String {
        switch mode {
        case .fifteenMinutes: return "15m"
        case .thirtyMinutes: return "30m"
        case .sixtyMinutes: return "1h"
        case .twoHours: return "2h"
        default: return mode.displayText
        }
    }

    var body: some View {
        Button(action: action) {
            Text(shortLabel)
                .font(.system(size: isExpanded ? 18 : 16, weight: .bold))
                .foregroundStyle(isSelected ? .white : theme.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: isExpanded ? 56 : 48)
                .background {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            isSelected
                                ? LinearGradient(
                                    colors: [theme.primary, theme.secondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [
                                        colorScheme == .dark
                                            ? Color.white.opacity(0.12)
                                            : Color.black.opacity(0.06),
                                        colorScheme == .dark
                                            ? Color.white.opacity(0.06)
                                            : Color.black.opacity(0.03)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                        )
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(
                            isSelected
                                ? Color.white.opacity(0.3)
                                : Color.white.opacity(colorScheme == .dark ? 0.15 : 0.3),
                            lineWidth: 1
                        )
                }
        }
        .buttonStyle(TimerOptionButtonStyle())
    }
}

// MARK: - Compact Duration Chip

private struct CompactDurationChip: View {
    let mode: TimerService.TimerMode
    let isSelected: Bool
    let theme: ThemeColors
    let colorScheme: ColorScheme
    let isExpanded: Bool
    let action: () -> Void

    private var compactLabel: String {
        switch mode {
        case .fiveMinutes: return "5m"
        case .tenMinutes: return "10m"
        case .fifteenMinutes: return "15m"
        case .thirtyMinutes: return "30m"
        case .sixtyMinutes: return "1h"
        case .twoHours: return "2h"
        case .threeHours: return "3h"
        case .fourHours: return "4h"
        case .sixHours: return "6h"
        case .eightHours: return "8h"
        default: return mode.displayText
        }
    }

    var body: some View {
        Button(action: action) {
            Text(compactLabel)
                .font(.system(size: isExpanded ? 14 : 12, weight: .semibold))
                .foregroundStyle(isSelected ? .white : theme.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: isExpanded ? 40 : 36)
                .background {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            isSelected
                                ? LinearGradient(
                                    colors: [theme.primary, theme.secondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [
                                        colorScheme == .dark
                                            ? Color.white.opacity(0.08)
                                            : Color.black.opacity(0.04),
                                        colorScheme == .dark
                                            ? Color.white.opacity(0.04)
                                            : Color.black.opacity(0.02)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                        )
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(
                            isSelected
                                ? Color.white.opacity(0.3)
                                : Color.white.opacity(colorScheme == .dark ? 0.1 : 0.2),
                            lineWidth: 1
                        )
                }
        }
        .buttonStyle(TimerOptionButtonStyle())
    }
}

// MARK: - Timer Option Button Style

private struct TimerOptionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Preview

struct TimerPickerView_Previews: PreviewProvider {
    static var previews: some View {
        TimerPickerView(timerMode: .constant(.thirtyMinutes))
            .preferredColorScheme(.dark)
    }
}
