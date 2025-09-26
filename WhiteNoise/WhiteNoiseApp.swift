//
//  WhiteNoiseApp.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 30.05.2023.
//

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
