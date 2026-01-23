//
//  SettingsView.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 2025-11-20.
//

import SwiftUI
import MessageUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var entitlements: EntitlementsCoordinator
    @AppStorage("isDarkMode") private var isDarkMode = true
    @State private var showMailView = false
    @State private var result: Result<MFMailComposeResult, Error>? = nil
    
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
        // Get the app's preferred language (respects per-app language settings in iOS Settings)
        let preferredLanguage = Bundle.main.preferredLocalizations.first ?? "en"
        let locale = Locale(identifier: preferredLanguage)
        // Display the language name in its native form (e.g., "Deutsch" for German)
        return locale.localizedString(forLanguageCode: preferredLanguage)?.capitalized ?? preferredLanguage
    }
    
    private func openAppLanguageSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    var body: some View {
        ZStack {
            // Background
            Color(UIColor.systemBackground).ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                HStack {
                    Text(String(localized: "Settings"))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.primary.opacity(0.6))
                    }
                }
                .padding(.top, 20)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Appearance Section
                        SettingsSection(title: String(localized: "Appearance")) {
                            Toggle(isOn: $isDarkMode) {
                                HStack {
                                    Image(systemName: "moon.fill")
                                        .foregroundColor(.primary)
                                    Text(String(localized: "Dark Mode"))
                                        .foregroundColor(.primary)
                                }
                            }
                            .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.1, green: 0.4, blue: 0.5)))
                        }
                        
                        // Language Section
                        SettingsSection(title: String(localized: "Language")) {
                            Button(action: {
                                openAppLanguageSettings()
                            }) {
                                HStack {
                                    Image(systemName: "globe")
                                        .foregroundColor(.primary)
                                    Text(String(localized: "App Language"))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text(currentLanguageName)
                                        .foregroundColor(.primary.opacity(0.6))
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.primary.opacity(0.6))
                                }
                            }
                        }
                        
                        // Subscription Section
                        SettingsSection(title: String(localized: "Subscription")) {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text(String(localized: "Premium Plan"))
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(subscriptionPrice)
                                    .foregroundColor(entitlements.hasActiveEntitlement ? .green : .primary.opacity(0.8))
                                    .font(.system(size: 16, weight: .medium))
                            }
                        }
                        
                        // Feedback Section
                        SettingsSection(title: String(localized: "Support")) {
                            Button(action: {
                                if MFMailComposeViewController.canSendMail() {
                                    showMailView = true
                                } else {
                                    // Fallback for simulators or devices without mail
                                    if let url = URL(string: "mailto:support@whitenoise.app") {
                                        UIApplication.shared.open(url)
                                    }
                                }
                            }) {
                                HStack {
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(.primary)
                                    Text(String(localized: "Send Feedback"))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.primary.opacity(0.6))
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // Version Info
                        Text(appVersion)
                            .font(.footnote)
                            .foregroundColor(.primary.opacity(0.4))
                            .padding(.top, 20)
                    }
                }
            }
            .padding(.horizontal, 24)
        }
        .sheet(isPresented: $showMailView) {
            MailView(result: $result)
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary.opacity(0.6))
                .textCase(.uppercase)
                .padding(.leading, 4)
            
            VStack(spacing: 0) {
                content
                    .padding(16)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.primary.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
}

// Mail View Helper
struct MailView: UIViewControllerRepresentable {
    @Binding var result: Result<MFMailComposeResult, Error>?

    class Coordinator: NSObject, @preconcurrency MFMailComposeViewControllerDelegate {
        @Binding var result: Result<MFMailComposeResult, Error>?

        init(result: Binding<Result<MFMailComposeResult, Error>?>) {
            _result = result
        }

        @MainActor
        func mailComposeController(_ controller: MFMailComposeViewController,
                                 didFinishWith result: MFMailComposeResult,
                                 error: Error?) {
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

    func makeUIViewController(context: UIViewControllerRepresentableContext<MailView>) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setToRecipients(["support@whitenoise.app"])
        vc.setSubject("WhiteNoise App Feedback")
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController,
                              context: UIViewControllerRepresentableContext<MailView>) {
    }
}
