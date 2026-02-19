//
//  SettingsView.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 2025-11-20.
//

import SwiftUI
import MessageUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var entitlements: EntitlementsCoordinator
    @AppStorage("isDarkMode") private var isDarkMode = true
    @State private var showMailView = false
    @State private var result: Result<MFMailComposeResult, Error>?

    private var theme: ThemeColors {
        ThemeColors(colorScheme: colorScheme)
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }

    private var subscriptionPrice: String {
        if entitlements.hasActiveEntitlement {
            return String(localized: "Active")
        }

        if let package = entitlements.currentOffering?.availablePackages.first {
            return package.localizedPriceString + String(localized: "/month")
        }

        return String(localized: "Loading...")
    }

    private var currentLanguageName: String {
        let preferredLanguage = Bundle.main.preferredLocalizations.first ?? "en"
        let languageCode = preferredLanguage.components(separatedBy: "-").first ?? "en"
        let locale = Locale(identifier: preferredLanguage)
        return locale.localizedString(forLanguageCode: languageCode)?.capitalized ?? preferredLanguage
    }

    private func openAppLanguageSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    var body: some View {
        ZStack {
            // Animated glass background with warmer tones for Settings
            AnimatedGlassBackground(
                primaryColor: colorScheme == .dark ? Color(hex: "5E8B9E") : Color(hex: "4A7A8C"),
                secondaryColor: colorScheme == .dark ? Color(hex: "7AA3B0") : Color(hex: "6B95A5")
            )

            VStack(spacing: 0) {
                // Header
                glassHeader

                // Content
                ScrollView {
                    VStack(spacing: 12) {
                        darkModeRow
                        languageRow
                        subscriptionRow
                        feedbackRow

                        // Version Info
                        Text(appVersion)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(theme.textTertiary)
                            .padding(.top, 32)
                            .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showMailView) {
            MailView(result: $result)
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }

    // MARK: - Header

    private var glassHeader: some View {
        HStack {
            Text(String(localized: "Settings"))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(theme.textPrimary)

            Spacer()

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

    // MARK: - Setting Rows

    private var darkModeRow: some View {
        GlassSettingsRow(
            icon: "moon.fill",
            iconColor: theme.primary,
            title: String(localized: "Dark Mode")
        ) {
            Toggle("", isOn: $isDarkMode)
                .toggleStyle(SwitchToggleStyle(tint: theme.primary))
                .labelsHidden()
        }
    }

    private var languageRow: some View {
        Button {
            openAppLanguageSettings()
        } label: {
            GlassSettingsRow(
                icon: "globe",
                iconColor: theme.info,
                title: String(localized: "App Language")
            ) {
                HStack(spacing: 6) {
                    Text(currentLanguageName)
                        .font(.system(size: 15))
                        .foregroundStyle(theme.textSecondary)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(theme.textTertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var subscriptionRow: some View {
        GlassSettingsRow(
            icon: "star.fill",
            iconColor: theme.warning,
            title: String(localized: "Premium Plan")
        ) {
            Text(subscriptionPrice)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(entitlements.hasActiveEntitlement ? theme.success : theme.textSecondary)
        }
    }

    private var feedbackRow: some View {
        Button {
            if MFMailComposeViewController.canSendMail() {
                showMailView = true
            } else {
                if let url = URL(string: "mailto:support@whitenoise.app") {
                    UIApplication.shared.open(url)
                }
            }
        } label: {
            GlassSettingsRow(
                icon: "envelope.fill",
                iconColor: theme.secondary,
                title: String(localized: "Send Feedback")
            ) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(theme.textTertiary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Mail View Helper

struct MailView: UIViewControllerRepresentable {
    @Binding var result: Result<MFMailComposeResult, Error>?

    @MainActor
    class Coordinator: NSObject, @preconcurrency MFMailComposeViewControllerDelegate {
        @Binding var result: Result<MFMailComposeResult, Error>?

        init(result: Binding<Result<MFMailComposeResult, Error>?>) {
            _result = result
        }

        deinit {}

        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            defer {
                controller.dismiss(animated: true)
            }
            if let error = error {
                self.result = .failure(error)
            } else {
                self.result = .success(result)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(result: $result)
    }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setToRecipients(["support@whitenoise.app"])
        vc.setSubject(String(localized: "WhiteNoise App Feedback"))
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
}
