//
//  EntitlementsCoordinator.swift
//  WhiteNoise
//
//  Handles RevenueCat entitlement checks and paywall presentation lifecycle.
//

import Foundation
import RevenueCat
import SwiftUI

/// Coordinates subscription entitlements, paywall presentation, and trial reminders.
@MainActor
final class EntitlementsCoordinator: ObservableObject {
    @Published private(set) var hasActiveEntitlement: Bool = false
    @Published var currentOffering: Offering?
    @Published var isPaywallPresented: Bool = false

    private let trialReminderScheduler = TrialReminderScheduler()
    private let defaults = UserDefaults.standard
    private let overrideKey = "whitenoise_entitlement_override_until"
    private let overrideDuration: TimeInterval = 300 // 5 minutes grace while awaiting customer info sync

    private let entitlementIdentifier: String
    private let offeringIdentifier: String?

    init(entitlementIdentifier: String? = nil, offeringIdentifier: String? = nil) {
        self.entitlementIdentifier = Self.resolveValue(
            provided: entitlementIdentifier,
            plistKey: "REVENUECAT_ENTITLEMENT_ID",
            defaultValue: "premium"
        )
        self.offeringIdentifier = Self.resolveOptionalValue(
            provided: offeringIdentifier,
            plistKey: "REVENUECAT_OFFERING_ID"
        )
    }

    func onAppLaunch() {
        print("🎯 EntitlementsCoordinator.onAppLaunch")
        Task { await refreshEntitlement() }
    }

    func handlePurchaseCompleted(with customerInfo: CustomerInfo) {
        activateEntitlementOverride()
        scheduleReminderIfNeeded(from: customerInfo)
        hasActiveEntitlement = true
        isPaywallPresented = false
        print("✅ EntitlementsCoordinator.handlePurchaseCompleted - Override active, hiding paywall")
        Task { await refreshEntitlement() }
    }

    func handleRestoreCompleted(with customerInfo: CustomerInfo) {
        activateEntitlementOverride()
        scheduleReminderIfNeeded(from: customerInfo)
        hasActiveEntitlement = activeEntitlement(in: customerInfo)?.isActive == true
        isPaywallPresented = !hasActiveEntitlement && !isForceShowEnabled()
        print("♻️ EntitlementsCoordinator.handleRestoreCompleted - Override active, refreshing")
        Task { await refreshEntitlement() }
    }

    func handlePaywallDismissed() {
        if !hasActiveEntitlement && isForceShowEnabled() {
            Task { await refreshEntitlement() }
        }
    }

    func handlePaywallRenderingFailure() {
        isPaywallPresented = false
    }

    @discardableResult
    private func refreshEntitlement() async -> CustomerInfo? {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()

            if let entitlement = activeEntitlement(in: customerInfo) {
                clearEntitlementOverride()
                trialReminderScheduler.ensureReminderScheduled(for: entitlement)
                hasActiveEntitlement = true
                isPaywallPresented = false
                print("✅ EntitlementsCoordinator.refreshEntitlement - Premium active via customer info")
                return customerInfo
            }

            if isEntitlementOverrideActive {
                hasActiveEntitlement = true
                isPaywallPresented = false
                print("⏱️ EntitlementsCoordinator.refreshEntitlement - Override active, keeping paywall hidden")
                return customerInfo
            }

            trialReminderScheduler.cancelReminder()
            hasActiveEntitlement = false

            try await loadOffering()
            isPaywallPresented = true
            print("🔒 EntitlementsCoordinator.refreshEntitlement - Paywall shown (no entitlement)")
            return customerInfo
        } catch {
            print("⚠️ EntitlementsCoordinator.refreshEntitlement - customer info fetch failed: \(error.localizedDescription)")
            TelemetryService.captureNonFatal(
                error: error,
                message: "EntitlementsCoordinator.refreshEntitlement failed to fetch customer info",
                extra: [
                    "overrideActive": isEntitlementOverrideActive,
                    "forceShowEnabled": isForceShowEnabled(),
                    "failOpenEnabled": isFailOpenEnabled()
                ]
            )
            if isEntitlementOverrideActive {
                hasActiveEntitlement = true
                isPaywallPresented = false
                print("⏱️ EntitlementsCoordinator.refreshEntitlement - Override active during failure")
            } else if isForceShowEnabled() || !isFailOpenEnabled() {
                // In debug or when explicitly requested, try to show the paywall
                // even if customer info failed, as long as we can load an offering.
                do {
                    try await loadOffering()
                    hasActiveEntitlement = false
                    isPaywallPresented = true
                    print("🔒 EntitlementsCoordinator.refreshEntitlement - Showing paywall despite failure (debug)")
                } catch {
                    hasActiveEntitlement = true
                    isPaywallPresented = false
                    print("⚠️ EntitlementsCoordinator.refreshEntitlement - Fallback to fail-open after offering load failure")
                    TelemetryService.captureNonFatal(
                        error: error,
                        message: "EntitlementsCoordinator.refreshEntitlement fallback offering load failed",
                        extra: [
                            "overrideActive": isEntitlementOverrideActive,
                            "forceShowEnabled": isForceShowEnabled()
                        ]
                    )
                }
            } else {
                hasActiveEntitlement = true
                isPaywallPresented = false
            }
            return nil
        }
    }

    private func loadOffering() async throws {
        do {
            currentOffering = nil
            let offerings = try await Purchases.shared.offerings()

            var offeringToUse: Offering?
            if let identifier = offeringIdentifier, !identifier.isEmpty {
                offeringToUse = offerings.offering(identifier: identifier)
                if offeringToUse == nil {
                    // Fallback to current to keep debugging smooth when identifier mismatches.
                    offeringToUse = offerings.current
                    print("⚠️ EntitlementsCoordinator.loadOffering - Offering \(identifier) not found, falling back to current offering")
                }
            } else {
                offeringToUse = offerings.current
            }

            guard let offering = offeringToUse else {
                let identifier = offeringIdentifier ?? "current"
                print("⚠️ EntitlementsCoordinator.loadOffering - No offering found for identifier \(identifier)")
                TelemetryService.captureNonFatal(
                    message: "EntitlementsCoordinator.loadOffering missing offering",
                    extra: ["requestedIdentifier": identifier]
                )
                throw PaywallLoadingError.offeringNotFound
            }

            if !offering.hasPaywall {
                print("⚠️ EntitlementsCoordinator.loadOffering - Offering \(offering.identifier) has no configured paywall")
                TelemetryService.captureNonFatal(
                    message: "EntitlementsCoordinator.loadOffering offering missing paywall",
                    extra: ["offeringIdentifier": offering.identifier]
                )
            }

            currentOffering = offering
            print("🧩 EntitlementsCoordinator.loadOffering - Loaded offering \(offering.identifier)")
        } catch {
            currentOffering = nil
            print("ℹ️ EntitlementsCoordinator.loadOffering - Failed to load offering: \(error.localizedDescription)")
            TelemetryService.captureNonFatal(
                error: error,
                message: "EntitlementsCoordinator.loadOffering failed",
                extra: [
                    "offeringIdentifier": offeringIdentifier ?? "current"
                ]
            )
            throw error
        }
    }

    private func activeEntitlement(in info: CustomerInfo) -> EntitlementInfo? {
        guard let entitlement = info.entitlements[entitlementIdentifier], entitlement.isActive else {
            return nil
        }
        return entitlement
    }

    private func scheduleReminderIfNeeded(from info: CustomerInfo) {
        if let entitlement = activeEntitlement(in: info) {
            trialReminderScheduler.ensureReminderScheduled(for: entitlement)
        } else {
            trialReminderScheduler.cancelReminder()
        }
    }

    private var entitlementOverrideUntil: Date? {
        get { defaults.object(forKey: overrideKey) as? Date }
        set {
            if let value = newValue {
                defaults.set(value, forKey: overrideKey)
            } else {
                defaults.removeObject(forKey: overrideKey)
            }
        }
    }

    private var isEntitlementOverrideActive: Bool {
        guard let until = entitlementOverrideUntil else { return false }
        if until > Date() { return true }
        entitlementOverrideUntil = nil
        return false
    }

    private func activateEntitlementOverride(duration: TimeInterval? = nil) {
        entitlementOverrideUntil = Date().addingTimeInterval(duration ?? overrideDuration)
        if let until = entitlementOverrideUntil {
            print("⏱️ EntitlementsCoordinator - Activated override until \(until)")
        }
    }

    private func clearEntitlementOverride() {
        entitlementOverrideUntil = nil
        print("⏱️ EntitlementsCoordinator - Cleared entitlement override")
    }

    private func isForceShowEnabled() -> Bool {
        ProcessInfo.processInfo.environment["FORCE_SHOW_PAYWALL"] == "1"
    }

    private func isFailOpenEnabled() -> Bool {
        // Defaults to current behavior (fail-open) unless explicitly disabled.
        if let value = ProcessInfo.processInfo.environment["PAYWALL_FAILS_OPEN"]?.lowercased() {
            return value != "0" && value != "false"
        }
        return true
    }

    private static func resolveValue(
        provided: String?,
        plistKey: String,
        defaultValue: String
    ) -> String {
        if let provided, !provided.isEmpty { return provided }
        if let plist = Bundle.main.object(forInfoDictionaryKey: plistKey) as? String, !plist.isEmpty {
            return plist
        }
        return defaultValue
    }

    private static func resolveOptionalValue(
        provided: String?,
        plistKey: String
    ) -> String? {
        if let provided, !provided.isEmpty { return provided }
        if let plist = Bundle.main.object(forInfoDictionaryKey: plistKey) as? String, !plist.isEmpty {
            return plist
        }
        return nil
    }

    private enum PaywallLoadingError: Error {
        case offeringNotFound
    }
}
