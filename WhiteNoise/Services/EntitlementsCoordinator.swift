//
//  EntitlementsCoordinator.swift
//  WhiteNoise
//
//  Handles Adapty entitlement checks and paywall presentation lifecycle.
//

import Foundation
import SwiftUI

#if canImport(Adapty)
import Adapty
#endif
#if canImport(AdaptyUI)
import AdaptyUI
#endif

@MainActor
final class EntitlementsCoordinator: ObservableObject {
    #if canImport(AdaptyUI)
    typealias PaywallConfigurationType = AdaptyUI.PaywallConfiguration
    #else
    typealias PaywallConfigurationType = Any
    #endif

    @Published private(set) var hasActiveEntitlement: Bool = false
    @Published var paywallConfiguration: PaywallConfigurationType?
    @Published var isPaywallPresented: Bool = false

    private let placementId = ProcessInfo.processInfo.environment["ADAPTY_PLACEMENT_ID"] ?? "main_paywall"

    func onAppLaunch() {
        Task { await refreshEntitlement(forceShow: isForceShowEnabled()) }
    }

    func onAppForeground() {
        Task { await refreshEntitlement(forceShow: false) }
    }

    func handlePurchaseCompleted() {
        Task { await refreshEntitlement(forceShow: false) }
    }

    func handleRestoreCompleted(with profile: AdaptyProfile) {
        let active = profile.accessLevels["premium"]?.isActive == true
        hasActiveEntitlement = active
        isPaywallPresented = !active && !isForceShowEnabled()
    }

    func handlePaywallDismissed() {
        if !hasActiveEntitlement && isForceShowEnabled() {
            Task { await refreshEntitlement(forceShow: true) }
        }
    }

    func handlePaywallRenderingFailure() {
        isPaywallPresented = false
    }

    private func refreshEntitlement(forceShow: Bool) async {
        #if canImport(Adapty)
        do {
            let profile = try await Adapty.getProfile()
            let active = profile.accessLevels["premium"]?.isActive == true
            hasActiveEntitlement = active

            if forceShow || !active {
                try await loadPaywallConfiguration()
                isPaywallPresented = true
            } else {
                isPaywallPresented = false
            }
        } catch {
            print("⚠️ EntitlementsCoordinator.refreshEntitlement - profile fetch failed: \(error.localizedDescription)")
            // MVP offline policy: allow playback when profile is unavailable.
            hasActiveEntitlement = true
            isPaywallPresented = false
        }
        #else
        hasActiveEntitlement = true
        isPaywallPresented = false
        #endif
    }

    private func loadPaywallConfiguration() async throws {
        #if canImport(Adapty) && canImport(AdaptyUI)
        paywallConfiguration = nil
        let paywall = try await Adapty.getPaywall(placementId: placementId)
        let configuration = try await AdaptyUI.getPaywallConfiguration(forPaywall: paywall)
        paywallConfiguration = configuration
        #else
        print("ℹ️ EntitlementsCoordinator.loadPaywallConfiguration - AdaptyUI not available")
        #endif
    }

    private func isForceShowEnabled() -> Bool {
        ProcessInfo.processInfo.environment["FORCE_SHOW_PAYWALL"] == "1"
    }
}
