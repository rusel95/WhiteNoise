//
//  WhiteNoiseApp.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 30.05.2023.
//

import Foundation
import Sentry

import SwiftUI

@main
struct WhiteNoiseApp: App {
    init() {
        // Initialize Sentry for error tracking
        let sentryDsn = Bundle.main.object(forInfoDictionaryKey: "SENTRY_DSN") as? String
        SentrySDK.start { options in
            options.dsn = sentryDsn
            options.sendDefaultPii = false

            #if DEBUG
            options.tracesSampleRate = 1.0
            options.configureProfiling = {
                $0.sessionSampleRate = 1.0
                $0.lifecycle = .trace
            }
            #else
            options.tracesSampleRate = 0.1
            options.configureProfiling = {
                $0.sessionSampleRate = 0.05
                $0.lifecycle = .trace
            }
            #endif

            options.experimental.enableLogs = true
        }

        // Initialize RevenueCat for subscriptions
        RevenueCatService.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}


struct RootView: View {
    @State private var entitlements = EntitlementsCoordinator()
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("isDarkMode") private var isDarkMode = true

    var body: some View {
        @Bindable var entitlements = entitlements
        ContentView()
            .environment(entitlements)
            .preferredColorScheme(isDarkMode ? .dark : .light)
            .onAppear { self.entitlements.onAppLaunch() }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    self.entitlements.onForeground()
                }
            }
            .sheet(isPresented: $entitlements.isPaywallPresented) {
                PaywallSheetView(coordinator: self.entitlements)
            }
    }
}
