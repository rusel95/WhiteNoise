//
//  PaywallSheetView.swift
//  WhiteNoise
//
//  Custom glass-design paywall using RevenueCat SDK for purchases.
//

import SwiftUI

struct PaywallSheetView<ViewModel: PaywallPresenting>: View {
    @State private var viewModel: ViewModel

    @Environment(\.colorScheme) private var colorScheme

    private var theme: ThemeColors {
        ThemeColors(colorScheme: colorScheme)
    }

    init(viewModel: ViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack {
            AnimatedGlassBackground(
                primaryColor: Color(hex: "7C4DFF"),
                secondaryColor: Color(hex: "4A90D9")
            )

            ScrollView {
                VStack(spacing: 0) {
                    dismissHandle
                    logoSection
                    headlineSection

                    if viewModel.hasFreeTrial {
                        trialTimelineSection
                    } else {
                        featuresSection
                    }

                    pricingSection
                    ctaButton
                    legalText
                    footerLinks
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }

            if viewModel.isBusy {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.3)
            }
        }
        .preferredColorScheme(.dark)
        .interactiveDismissDisabled(viewModel.isBusy)
    }

    // MARK: - Dismiss Handle

    private var dismissHandle: some View {
        HStack {
            Spacer()
            Button {
                viewModel.dismissPaywall()
            } label: {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 32, height: 32)
                        .overlay {
                            Circle()
                                .strokeBorder(
                                    Color.white.opacity(0.12),
                                    lineWidth: 1
                                )
                        }
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(theme.textSecondary)
                }
            }
        }
        .padding(.top, 16)
    }

    // MARK: - Logo

    private var logoSection: some View {
        Image("HushLogo")
            .resizable()
            .scaledToFit()
            .frame(width: 100, height: 100)
            .padding(.top, 8)
    }

    // MARK: - Headline

    private var headlineSection: some View {
        VStack(spacing: 8) {
            if viewModel.hasFreeTrial {
                Text(String(localized: "How your free trial works"))
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.textPrimary)
            } else {
                Text(String(localized: "Unlock Full Access"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.textPrimary)

                Text(String(localized: "Enjoy all sounds without limits"))
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(theme.textSecondary)
            }
        }
        .multilineTextAlignment(.center)
        .padding(.top, 20)
    }

    // MARK: - Trial Timeline

    private var trialTimelineSection: some View {
        VStack(spacing: 0) {
            timelineStep(
                icon: "lock.open.fill",
                color: Color(hex: "7C4DFF"),
                title: String(localized: "All Access"),
                subtitle: String(localized: "Unlock all sounds and features"),
                isFirst: true
            )

            timelineStep(
                icon: "bell.fill",
                color: Color(hex: "7C4DFF").opacity(0.7),
                title: String(localized: "We'll remind you 1 day before it ends"),
                subtitle: String(localized: "You'll get a notification before any charge"),
                isFirst: false
            )

            timelineStep(
                icon: "star.fill",
                color: Color(hex: "4A90D9"),
                title: String(localized: "After trial"),
                subtitle: viewModel.priceText.map { _ in
                    String(localized: "You can cancel anytime before")
                } ?? "",
                isFirst: false,
                isLast: true
            )
        }
        .padding(16)
        .glassCard(cornerRadius: 20, opacity: 0.5)
        .padding(.top, 28)
    }

    private func timelineStep(
        icon: String,
        color: Color,
        title: String,
        subtitle: String,
        isFirst: Bool,
        isLast: Bool = false
    ) -> some View {
        HStack(alignment: .top, spacing: 14) {
            // Timeline line + circle
            VStack(spacing: 0) {
                if !isFirst {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "7C4DFF").opacity(0.6), color.opacity(0.4)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 2, height: 16)
                }

                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(color)
                }

                if !isLast {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.4), Color(hex: "4A90D9").opacity(0.3)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 36)

            // Text
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(theme.textPrimary)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(theme.textSecondary)
            }
            .padding(.vertical, isFirst ? 0 : 4)

            Spacer()
        }
    }

    // MARK: - Features (shown when no trial)

    private var featuresSection: some View {
        VStack(spacing: 12) {
            featureRow(icon: "waveform.circle.fill", color: Color(hex: "00BCD4"),
                       title: String(localized: "All Sounds"), subtitle: String(localized: "Mix any combination"))
            featureRow(icon: "moon.stars.fill", color: Color(hex: "7C4DFF"),
                       title: String(localized: "Sleep Timer"), subtitle: String(localized: "Auto fade-out up to 8 hours"))
            featureRow(icon: "slider.horizontal.3", color: Color(hex: "F0B254"),
                       title: String(localized: "Sound Variants"), subtitle: String(localized: "Multiple versions per sound"))
            featureRow(icon: "heart.fill", color: Color(hex: "E57D7D"),
                       title: String(localized: "Support Development"), subtitle: String(localized: "Help us keep improving"))
        }
        .padding(16)
        .glassCard(cornerRadius: 20, opacity: 0.5)
        .padding(.top, 28)
    }

    private func featureRow(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(theme.textPrimary)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(theme.textSecondary)
            }

            Spacer()
        }
    }

    // MARK: - Pricing

    private var pricingSection: some View {
        VStack(spacing: 6) {
            if let priceText = viewModel.priceText {
                Text(priceText)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.textPrimary)

                if let monthlyPrice = viewModel.monthlyPriceText {
                    Text("(\(monthlyPrice))")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(theme.textSecondary)
                }

                if let trialText = viewModel.trialText {
                    Text(trialText)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color(hex: "7C4DFF"))
                }
            } else {
                ProgressView()
                    .tint(theme.textSecondary)
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundStyle(theme.error)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
        }
        .padding(.top, 24)
    }

    // MARK: - CTA

    private var ctaButton: some View {
        Button {
            Task { await viewModel.purchase() }
        } label: {
            Text(viewModel.ctaText)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "7C4DFF"), Color(hex: "5E35B1")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color(hex: "7C4DFF").opacity(0.4), radius: 12, y: 6)
        }
        .disabled(viewModel.isBusy || !viewModel.isReady)
        .padding(.top, 20)
    }

    // MARK: - Legal

    private var legalText: some View {
        Group {
            if let text = viewModel.legalText {
                Text(text)
                    .font(.system(size: 11))
                    .foregroundStyle(theme.textTertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 12)
    }

    // MARK: - Footer

    private var footerLinks: some View {
        HStack(spacing: 20) {
            Button(String(localized: "Restore Purchases")) {
                Task { await viewModel.restore() }
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(theme.textSecondary)

            if let termsURL = URL(string: "https://rusel95.github.io/rusel95-apps-legal/WhiteNoise/terms-of-service.html") {
                Link(String(localized: "Terms"), destination: termsURL)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(theme.textSecondary)
            }

            if let privacyURL = URL(string: "https://rusel95.github.io/rusel95-apps-legal/WhiteNoise/privacy-policy.html") {
                Link(String(localized: "Privacy"), destination: privacyURL)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(theme.textSecondary)
            }
        }
        .padding(.top, 16)
    }
}

// MARK: - Production Convenience Init

extension PaywallSheetView where ViewModel == PaywallViewModel {
    init(coordinator: any EntitlementsCoordinating) {
        self.init(viewModel: PaywallViewModel(coordinator: coordinator))
    }
}

#if DEBUG
#Preview {
    PaywallSheetView(viewModel: PreviewPaywallPresenter())
}
#endif
