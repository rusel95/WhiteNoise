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
        SentrySDK.start { options in
            options.dsn = "https://c8cf829b48cb5afa4c6d0ef6a8fb72e8@o1271632.ingest.us.sentry.io/4510221384810496"

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

            // Uncomment the following lines to add more data to your events
            // options.attachScreenshot = true // This adds a screenshot to the error events
            // options.attachViewHierarchy = true // This adds the view hierarchy to the error events
            
            // Enable experimental logging features
            options.experimental.enableLogs = true
        }
        // Remove the next line after confirming that your Sentry integration is working.
        SentrySDK.capture(message: "This app uses Sentry! :)")

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
