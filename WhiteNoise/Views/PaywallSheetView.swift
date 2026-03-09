//
//  PaywallSheetView.swift
//  WhiteNoise
//
//  Custom glass-design paywall using RevenueCat SDK for purchases.
//

import SwiftUI
import RevenueCat

struct PaywallSheetView: View {
    let coordinator: EntitlementsCoordinator

    @Environment(\.colorScheme) private var colorScheme
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var errorMessage: String?

    private var theme: ThemeColors {
        ThemeColors(colorScheme: colorScheme)
    }

    private var package: Package? {
        coordinator.currentOffering?.availablePackages.first
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
                    featuresSection
                    pricingSection
                    ctaButton
                    legalText
                    footerLinks
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }

            if isPurchasing || isRestoring {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.3)
            }
        }
        .preferredColorScheme(.dark)
        .interactiveDismissDisabled(isPurchasing || isRestoring)
    }

    // MARK: - Dismiss Handle

    private var dismissHandle: some View {
        HStack {
            Spacer()
            Button {
                coordinator.isPaywallPresented = false
                coordinator.handlePaywallDismissed()
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
            Text(String(localized: "Unlock Full Access"))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(theme.textPrimary)

            Text(String(localized: "Enjoy all sounds without limits"))
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(theme.textSecondary)
        }
        .multilineTextAlignment(.center)
        .padding(.top, 20)
    }

    // MARK: - Features

    private var featuresSection: some View {
        VStack(spacing: 12) {
            featureRow(icon: "waveform.circle.fill", color: Color(hex: "00BCD4"),
                       title: String(localized: "All 9 Sounds"), subtitle: String(localized: "Mix any combination"))
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
            if let pkg = package {
                let product = pkg.storeProduct
                Text(product.localizedPriceString + " / " + periodLabel(for: product))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.textPrimary)

                if let intro = product.introductoryDiscount {
                    Text(trialLabel(for: intro))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color(hex: "7C4DFF"))
                }
            } else {
                ProgressView()
                    .tint(theme.textSecondary)
            }

            if let error = errorMessage {
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
            Task { await purchase() }
        } label: {
            HStack(spacing: 8) {
                if let intro = package?.storeProduct.introductoryDiscount, intro.price == 0 {
                    Text(String(localized: "Start Free Trial"))
                        .font(.system(size: 17, weight: .bold))
                } else {
                    Text(String(localized: "Subscribe Now"))
                        .font(.system(size: 17, weight: .bold))
                }
            }
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
        .disabled(isPurchasing || isRestoring || package == nil)
        .padding(.top, 20)
    }

    // MARK: - Legal

    private var legalText: some View {
        Group {
            if let pkg = package {
                let product = pkg.storeProduct
                Text(String(localized: "Auto-renews every \(periodLabel(for: product)) unless cancelled at least 24h before the period ends. Billed to your Apple ID. Manage in Settings."))
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
                Task { await restore() }
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(theme.textSecondary)

            if let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") {
                Link(String(localized: "Terms"), destination: termsURL)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(theme.textSecondary)
            }

            if let privacyURL = URL(string: "https://www.apple.com/legal/privacy/") {
                Link(String(localized: "Privacy"), destination: privacyURL)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(theme.textSecondary)
            }
        }
        .padding(.top, 16)
    }

    // MARK: - Purchase Logic

    private func purchase() async {
        guard let pkg = package else { return }
        isPurchasing = true
        errorMessage = nil

        do {
            let result = try await Purchases.shared.purchase(package: pkg)
            if !result.userCancelled {
                coordinator.handlePurchaseCompleted(with: result.customerInfo)
                coordinator.isPaywallPresented = false
            } else {
                AnalyticsService.capture(.purchaseCancelled)
                LoggingService.log("PaywallSheetView - Purchase cancelled by user")
            }
        } catch {
            errorMessage = String(localized: "Something went wrong. Please try again.")
            AnalyticsService.capture(.purchaseFailed(error: error.localizedDescription))
            TelemetryService.captureNonFatal(
                error: error,
                message: "PaywallSheetView - Purchase failed"
            )
            LoggingService.log("PaywallSheetView - Purchase failed: \(error.localizedDescription)")
        }

        isPurchasing = false
    }

    private func restore() async {
        isRestoring = true
        errorMessage = nil

        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            coordinator.handleRestoreCompleted(with: customerInfo)
        } catch {
            errorMessage = String(localized: "Restore failed. Please try again.")
            AnalyticsService.capture(.restoreFailed(error: error.localizedDescription))
            TelemetryService.captureNonFatal(
                error: error,
                message: "PaywallSheetView - Restore failed"
            )
            LoggingService.log("PaywallSheetView - Restore failed: \(error.localizedDescription)")
        }

        isRestoring = false
    }

    // MARK: - Helpers

    private func periodLabel(for product: StoreProduct) -> String {
        guard let period = product.subscriptionPeriod else { return "" }
        switch period.unit {
        case .day: return period.value == 7 ? String(localized: "week") : String(localized: "\(period.value) days")
        case .week: return String(localized: "week")
        case .month: return period.value == 1 ? String(localized: "month") : String(localized: "\(period.value) months")
        case .year: return String(localized: "year")
        @unknown default:
            LoggingService.log("⚠️ PaywallSheetView.periodLabel - Unknown subscription period unit")
            return ""
        }
    }

    private func trialLabel(for discount: StoreProductDiscount) -> String {
        let period = discount.subscriptionPeriod
        let value = period.value
        let unitName: String
        switch period.unit {
        case .day: unitName = String(localized: "day")
        case .week: unitName = String(localized: "week")
        case .month: unitName = String(localized: "month")
        case .year: unitName = String(localized: "year")
        @unknown default:
            LoggingService.log("⚠️ PaywallSheetView.trialLabel - Unknown subscription period unit")
            return ""
        }
        return String(localized: "Includes \(value) \(unitName) free trial")
    }
}
