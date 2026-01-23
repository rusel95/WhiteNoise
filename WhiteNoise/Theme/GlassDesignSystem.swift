//
//  GlassDesignSystem.swift
//  WhiteNoise
//
//  Glass morphism design system inspired by iOS 18+ aesthetics.
//  Provides consistent glass effects, buttons, and theme colors.
//

import SwiftUI

// MARK: - Theme Colors

struct ThemeColors {
    let colorScheme: ColorScheme

    // Primary accent - Deep blue
    var primary: Color {
        colorScheme == .dark ? Color(hex: "4A90D9") : Color(hex: "2E6CB5")
    }

    var secondary: Color {
        colorScheme == .dark ? Color(hex: "6BA3E0") : Color(hex: "4A8AD4")
    }

    // Backgrounds
    var background: Color {
        colorScheme == .dark ? Color(hex: "0D0D0F") : Color(hex: "F8F9FA")
    }

    var surface: Color {
        colorScheme == .dark ? Color(hex: "1C1C1E") : Color.white
    }

    var elevated: Color {
        colorScheme == .dark ? Color(hex: "2C2C2E") : Color(hex: "F0F1F3")
    }

    // Text
    var textPrimary: Color {
        colorScheme == .dark ? Color(hex: "F5F5F5") : Color(hex: "1A1A1A")
    }

    var textSecondary: Color {
        colorScheme == .dark ? Color(hex: "9CA3AF") : Color(hex: "6B7280")
    }

    var textTertiary: Color {
        colorScheme == .dark ? Color(hex: "6B7280") : Color(hex: "9CA3AF")
    }

    // Semantic
    var success: Color {
        colorScheme == .dark ? Color(hex: "5EBF94") : Color(hex: "4CAF82")
    }

    var warning: Color {
        colorScheme == .dark ? Color(hex: "F0B254") : Color(hex: "E6A23C")
    }

    var error: Color {
        colorScheme == .dark ? Color(hex: "E57D7D") : Color(hex: "D66B6B")
    }

    var info: Color {
        colorScheme == .dark ? Color(hex: "6DB5B5") : Color(hex: "5BA3A3")
    }
}

// MARK: - Glass Background

/// Base glass background with blur effect
struct GlassBackground: View {
    let colorScheme: ColorScheme
    var opacity: Double = 0.7

    var body: some View {
        Group {
            if colorScheme == .dark {
                Color(hex: "1C1C1E")
                    .opacity(opacity)
                    .background(.ultraThinMaterial)
            } else {
                Color.white
                    .opacity(opacity)
                    .background(.ultraThinMaterial)
            }
        }
    }
}

// MARK: - Glass Card Modifier

struct GlassCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    var cornerRadius: CGFloat = 26
    var opacity: Double = 0.7

    func body(content: Content) -> some View {
        content
            .background {
                GlassBackground(colorScheme: colorScheme, opacity: opacity)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
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
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.4 : 0.1),
                radius: 15,
                x: 0,
                y: 8
            )
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 26, opacity: Double = 0.7) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius, opacity: opacity))
    }
}

// MARK: - Glass Inset Modifier (for nested items)

struct GlassInsetModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    var cornerRadius: CGFloat = 16
    var opacity: Double = 0.55

    func body(content: Content) -> some View {
        content
            .background {
                GlassBackground(colorScheme: colorScheme, opacity: opacity)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.14 : 0.38),
                                Color.white.opacity(colorScheme == .dark ? 0.05 : 0.10)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
    }
}

extension View {
    func glassInset(cornerRadius: CGFloat = 16, opacity: Double = 0.55) -> some View {
        modifier(GlassInsetModifier(cornerRadius: cornerRadius, opacity: opacity))
    }
}

// MARK: - Glass Button Style

struct GlassButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled

    var tint: Color = .accentColor
    var cornerRadius: CGFloat = 18

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                GlassBackground(
                    colorScheme: colorScheme,
                    opacity: configuration.isPressed ? 0.55 : 0.7
                )
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(tint.opacity(colorScheme == .dark ? 0.15 : 0.08))
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.18 : 0.55),
                                (isEnabled ? tint : Color.gray).opacity(colorScheme == .dark ? 0.35 : 0.25),
                                Color.white.opacity(colorScheme == .dark ? 0.06 : 0.18)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.45 : 0.12),
                radius: 12,
                x: 0,
                y: 8
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
            .opacity(isEnabled ? 1.0 : 0.6)
    }
}

extension ButtonStyle where Self == GlassButtonStyle {
    static var glass: GlassButtonStyle { GlassButtonStyle() }
    static func glass(tint: Color, cornerRadius: CGFloat = 18) -> GlassButtonStyle {
        GlassButtonStyle(tint: tint, cornerRadius: cornerRadius)
    }
}

// MARK: - Glass Icon Button Style (for circular/square icon buttons)

struct GlassIconButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled

    var tint: Color = .primary
    var isActive: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        let effectiveTint = isActive ? tint : .clear
        let isPressed = configuration.isPressed

        configuration.label
            .background {
                GlassBackground(
                    colorScheme: colorScheme,
                    opacity: isPressed ? 0.45 : 0.65
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    effectiveTint.opacity(colorScheme == .dark ? 0.25 : 0.15),
                                    effectiveTint.opacity(colorScheme == .dark ? 0.10 : 0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                // Press highlight overlay
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white.opacity(isPressed ? 0.1 : 0))
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.20 : 0.50),
                                effectiveTint.opacity(colorScheme == .dark ? 0.30 : 0.20),
                                Color.white.opacity(colorScheme == .dark ? 0.08 : 0.20)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.35 : 0.10),
                radius: isPressed ? 6 : 10,
                x: 0,
                y: isPressed ? 3 : 6
            )
            .scaleEffect(isPressed ? 0.92 : 1.0)
            .brightness(isPressed ? -0.05 : 0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
            .opacity(isEnabled ? 1.0 : 0.5)
    }
}

// MARK: - Animated Glass Background

struct AnimatedGlassBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var animateOrbs = false

    var primaryColor: Color = Color(hex: "4A90D9")
    var secondaryColor: Color = Color(hex: "6BA3E0")

    var body: some View {
        let theme = ThemeColors(colorScheme: colorScheme)

        ZStack {
            // Base gradient
            LinearGradient(
                colors: [theme.background, theme.background.opacity(0.95)],
                startPoint: .top,
                endPoint: .bottom
            )

            // Animated primary orb
            GeometryReader { geometry in
                ZStack {
                    // Primary orb (top-leading)
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    primaryColor.opacity(colorScheme == .dark ? 0.35 : 0.20),
                                    primaryColor.opacity(colorScheme == .dark ? 0.15 : 0.08),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: geometry.size.width * 0.5
                            )
                        )
                        .frame(width: geometry.size.width * 0.9)
                        .offset(
                            x: animateOrbs ? -geometry.size.width * 0.1 : -geometry.size.width * 0.3,
                            y: animateOrbs ? -geometry.size.height * 0.2 : -geometry.size.height * 0.0
                        )
                        .blur(radius: 35)

                    // Secondary orb (bottom-trailing)
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    secondaryColor.opacity(colorScheme == .dark ? 0.30 : 0.18),
                                    secondaryColor.opacity(colorScheme == .dark ? 0.12 : 0.06),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: geometry.size.width * 0.45
                            )
                        )
                        .frame(width: geometry.size.width * 0.8)
                        .offset(
                            x: animateOrbs ? geometry.size.width * 0.15 : geometry.size.width * 0.35,
                            y: animateOrbs ? geometry.size.height * 0.3 : geometry.size.height * 0.1
                        )
                        .blur(radius: 45)

                    // Tertiary subtle orb
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    primaryColor.opacity(colorScheme == .dark ? 0.22 : 0.12),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: geometry.size.width * 0.3
                            )
                        )
                        .frame(width: geometry.size.width * 0.5)
                        .offset(
                            x: animateOrbs ? geometry.size.width * 0.15 : -geometry.size.width * 0.1,
                            y: animateOrbs ? geometry.size.height * 0.55 : geometry.size.height * 0.4
                        )
                        .blur(radius: 25)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(
                .easeInOut(duration: 6)
                .repeatForever(autoreverses: true)
            ) {
                animateOrbs = true
            }
        }
    }
}

// MARK: - Glass Section Header

struct GlassSectionHeader: View {
    let title: String
    var icon: String?

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let theme = ThemeColors(colorScheme: colorScheme)

        HStack(spacing: 10) {
            if let icon {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 32, height: 32)

                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(theme.primary)
                }
                .overlay {
                    Circle()
                        .strokeBorder(
                            Color.white.opacity(colorScheme == .dark ? 0.10 : 0.22),
                            lineWidth: 1
                        )
                }
            }

            Text(title)
                .font(.headline)
                .foregroundStyle(theme.textPrimary)

            Spacer()
        }
    }
}

// MARK: - Glass Settings Row

struct GlassSettingsRow<Content: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    @ViewBuilder var trailing: Content

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let theme = ThemeColors(colorScheme: colorScheme)

        HStack(spacing: 14) {
            // Icon container
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(iconColor.opacity(colorScheme == .dark ? 0.2 : 0.15))
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(iconColor)
            }

            Text(title)
                .font(.body)
                .foregroundStyle(theme.textPrimary)

            Spacer()

            trailing
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassInset(cornerRadius: 14, opacity: 0.5)
    }
}

// MARK: - Color Extension for Hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
