//
//  WhiteNoiseApp.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 30.05.2023.
//

import Foundation
import SwiftUI
import Sentry

@main
struct WhiteNoiseApp: App {
    init() {
        let sentryDSN = Self.resolveSentryDSN()

        SentrySDK.start { options in
            if let sentryDSN {
                options.dsn = sentryDSN
            } else {
                #if DEBUG
                assertionFailure("Missing SENTRY_DSN. Provide it via environment or Local.xcconfig.")
                #endif
                print("⚠️ Sentry DSN missing; telemetry is disabled")
                options.enabled = false
            }

            // Adds IP for users.
            // For more information, visit: https://docs.sentry.io/platforms/apple/data-management/data-collected/
            options.sendDefaultPii = true

            // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
            // We recommend adjusting this value in production.
            options.tracesSampleRate = 1.0

            // Configure profiling. Visit https://docs.sentry.io/platforms/apple/profiling/ to learn more.
            options.configureProfiling = {
                $0.sessionSampleRate = 1.0 // We recommend adjusting this value in production.
                $0.lifecycle = .trace
            }

            // Enable experimental logging features
            options.experimental.enableLogs = true
        }

        RevenueCatService.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

private extension WhiteNoiseApp {
    static func resolveSentryDSN() -> String? {
        if let envValue = ProcessInfo.processInfo.environment["SENTRY_DSN"],
           envValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
            return envValue
        }

        if let infoValue = Bundle.main.object(forInfoDictionaryKey: "SENTRY_DSN") as? String,
           infoValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
            return infoValue
        }

        return nil
    }
}

struct RootView: View {
    @StateObject private var entitlements = EntitlementsCoordinator()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ContentView()
            .onAppear { entitlements.onAppLaunch() }
            .sheet(isPresented: $entitlements.isPaywallPresented) {
                PaywallSheetView(coordinator: entitlements)
            }
    }
}
