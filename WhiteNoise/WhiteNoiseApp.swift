//
//  WhiteNoiseApp.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 30.05.2023.
//

import Foundation
import SwiftUI

@main
struct WhiteNoiseApp: App {
    init() {
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
