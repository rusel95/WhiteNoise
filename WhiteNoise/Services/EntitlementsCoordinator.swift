//
//  EntitlementsCoordinator.swift
//  WhiteNoise
//
//  Handles RevenueCat entitlement checks and paywall presentation lifecycle.
//

import Foundation
import Observation
import RevenueCat

/// Coordinates subscription entitlements, paywall presentation, and trial reminders.
@Observable @MainActor
final class EntitlementsCoordinator {
    private(set) var hasActiveEntitlement: Bool = false
    var currentOffering: Offering?
    var isPaywallPresented: Bool = false

    let engagementService = EngagementService()
    private let trialReminderScheduler = TrialReminderScheduler()
    private let overrideKey = "whitenoise_entitlement_override_until"
    private let overrideDuration: TimeInterval = 600 // 10 minutes grace while awaiting customer info sync
    private var isRefreshing = false // Prevent concurrent refresh calls
    @ObservationIgnored private var refreshTask: Task<CustomerInfo?, Never>?

    private let entitlementIdentifier: String
    private let offeringIdentifier: String?

    init(entitlementIdentifier: String? = nil, offeringIdentifier: String? = nil) {
        self.entitlementIdentifier = Self.resolveValue(
            provided: entitlementIdentifier,
            plistKey: "REVENUECAT_ENTITLEMENT_ID",
            defaultValue: "Unlimited Access"
        )
        self.offeringIdentifier = Self.resolveOptionalValue(
            provided: offeringIdentifier,
            plistKey: "REVENUECAT_OFFERING_ID"
        )
        LoggingService.log("🔑 EntitlementsCoordinator.init - Using entitlement identifier: '\(self.entitlementIdentifier)'")
    }

    func onAppLaunch() {
        engagementService.recordSessionStart()
        LoggingService.log("🎯 EntitlementsCoordinator.onAppLaunch")
        scheduleRefresh(forceFetch: true)
    }

    func onForeground() {
        LoggingService.log("🎯 EntitlementsCoordinator.onForeground")
        // Force fetch on foreground to catch purchases made elsewhere (e.g., Settings app)
        scheduleRefresh(forceFetch: true)
    }

    func handlePurchaseCompleted(with customerInfo: CustomerInfo) {
        activateEntitlementOverride()
        scheduleReminderIfNeeded(from: customerInfo)
        grantAccess()
        AnalyticsService.capture(.purchaseCompleted(offering: currentOffering?.identifier))
        LoggingService.log("✅ EntitlementsCoordinator.handlePurchaseCompleted - Override active, hiding paywall")
        scheduleRefresh()
    }

    func handleRestoreCompleted(with customerInfo: CustomerInfo) {
        activateEntitlementOverride()
        scheduleReminderIfNeeded(from: customerInfo)
        let isActive = activeEntitlement(in: customerInfo)?.isActive == true
        hasActiveEntitlement = isActive
        isPaywallPresented = !hasActiveEntitlement && !isForceShowEnabled()
        AnalyticsService.capture(.restoreCompleted(hasEntitlement: isActive))
        LoggingService.log("♻️ EntitlementsCoordinator.handleRestoreCompleted - Override active, refreshing")
        scheduleRefresh()
    }

    func handlePaywallDismissed() {
        AnalyticsService.capture(.paywallDismissed)
        LoggingService.log("ℹ️ EntitlementsCoordinator.handlePaywallDismissed - User dismissed paywall")
        // Don't auto-refresh after dismissal to avoid showing paywall again
        // Only refresh in force-show debug mode for testing purposes
        if isForceShowEnabled() {
            LoggingService.log("🔧 EntitlementsCoordinator.handlePaywallDismissed - Force show enabled, refreshing for debug")
            scheduleRefresh(forceFetch: true)
        }
    }

    func handlePaywallRenderingFailure() {
        isPaywallPresented = false
        LoggingService.log("⚠️ EntitlementsCoordinator.handlePaywallRenderingFailure - Paywall rendering failed, dismissing")
        TelemetryService.captureNonFatal(
            message: "EntitlementsCoordinator.handlePaywallRenderingFailure - Paywall rendering failed"
        )
    }

    private func scheduleRefresh(forceFetch: Bool = false) {
        refreshTask?.cancel()
        refreshTask = Task { await refreshEntitlement(forceFetch: forceFetch) }
    }

    private func grantAccess() {
        hasActiveEntitlement = true
        isPaywallPresented = false
    }

    @discardableResult
    private func refreshEntitlement(forceFetch: Bool = false) async -> CustomerInfo? {
        // Prevent concurrent refreshes from causing race conditions
        guard !isRefreshing else {
            LoggingService.log("⚠️ EntitlementsCoordinator.refreshEntitlement - Already refreshing, skipping")
            return nil
        }

        isRefreshing = true
        defer { isRefreshing = false }

        // When RevenueCat is not configured (missing/invalid API key), grant access
        // to avoid crashes and let users use the app without subscription enforcement
        guard RevenueCatService.isConfigured else {
            LoggingService.log("⚠️ EntitlementsCoordinator.refreshEntitlement - RevenueCat not configured, granting access")
            TelemetryService.captureNonFatal(
                message: "EntitlementsCoordinator.refreshEntitlement - RevenueCat not configured, bypassing paywall",
                level: .warning
            )
            grantAccess()
            return nil
        }

        do {
            let customerInfo = try await Purchases.shared.customerInfo(fetchPolicy: forceFetch ? .fetchCurrent : .cachedOrFetched)

            if let entitlement = activeEntitlement(in: customerInfo) {
                clearEntitlementOverride()
                trialReminderScheduler.ensureReminderScheduled(for: entitlement)
                grantAccess()
                LoggingService.log("✅ EntitlementsCoordinator.refreshEntitlement - Premium active via customer info")
                return customerInfo
            }

            if isEntitlementOverrideActive {
                grantAccess()
                LoggingService.log("⏱️ EntitlementsCoordinator.refreshEntitlement - Override active, keeping paywall hidden")
                return customerInfo
            }

            trialReminderScheduler.cancelReminder()

            guard engagementService.hasMetPaywallThreshold || isForceShowEnabled() else {
                grantAccess()
                LoggingService.log("🆓 EntitlementsCoordinator.refreshEntitlement - Engagement threshold not met, granting access")
                return customerInfo
            }

            hasActiveEntitlement = false

            try await loadOffering()
            isPaywallPresented = true
            AnalyticsService.capture(.paywallShown(offering: currentOffering?.identifier))
            LoggingService.log("🔒 EntitlementsCoordinator.refreshEntitlement - Paywall shown (no entitlement)")
            return customerInfo
        } catch {
            LoggingService.log("⚠️ EntitlementsCoordinator.refreshEntitlement - customer info fetch failed: \(error.localizedDescription)")
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
                grantAccess()
                LoggingService.log("⏱️ EntitlementsCoordinator.refreshEntitlement - Override active during failure")
            } else if (isForceShowEnabled() || !isFailOpenEnabled()) && engagementService.hasMetPaywallThreshold {
                // In debug or when explicitly requested, try to show the paywall
                // even if customer info failed, as long as we can load an offering.
                do {
                    try await loadOffering()
                    hasActiveEntitlement = false
                    isPaywallPresented = true
                    LoggingService.log("🔒 EntitlementsCoordinator.refreshEntitlement - Showing paywall despite failure (debug)")
                } catch {
                    grantAccess()
                    LoggingService.log("⚠️ EntitlementsCoordinator.refreshEntitlement - Fallback to fail-open after offering load failure")
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
                grantAccess()
                LoggingService.log("⚠️ EntitlementsCoordinator.refreshEntitlement - Fail-open: granting access after customer info failure")
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
                    LoggingService.log("⚠️ EntitlementsCoordinator.loadOffering - Offering \(identifier) not found, falling back to current offering")
                }
            } else {
                offeringToUse = offerings.current
            }

            guard let offering = offeringToUse else {
                let identifier = offeringIdentifier ?? "current"
                LoggingService.log("⚠️ EntitlementsCoordinator.loadOffering - No offering found for identifier \(identifier)")
                TelemetryService.captureNonFatal(
                    message: "EntitlementsCoordinator.loadOffering missing offering",
                    extra: ["requestedIdentifier": identifier]
                )
                throw PaywallLoadingError.offeringNotFound
            }

            currentOffering = offering
            LoggingService.log("🧩 EntitlementsCoordinator.loadOffering - Loaded offering \(offering.identifier)")
        } catch {
            currentOffering = nil
            LoggingService.log("ℹ️ EntitlementsCoordinator.loadOffering - Failed to load offering: \(error.localizedDescription)")
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
            // Debug logging to help identify entitlement identifier mismatches
            let availableEntitlements = info.entitlements.all.map { "\($0.key):\($0.value.isActive ? "active" : "inactive")" }.joined(separator: ", ")
            LoggingService.log("ℹ️ EntitlementsCoordinator - No active entitlement for '\(entitlementIdentifier)'. Available: [\(availableEntitlements)]")
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
        get { KeychainService.loadDate(forKey: overrideKey) }
        set {
            if let value = newValue {
                KeychainService.saveDate(value, forKey: overrideKey)
            } else {
                KeychainService.deleteValue(forKey: overrideKey)
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
            LoggingService.log("⏱️ EntitlementsCoordinator - Activated override until \(until)")
        }
    }

    private func clearEntitlementOverride() {
        entitlementOverrideUntil = nil
        LoggingService.log("⏱️ EntitlementsCoordinator - Cleared entitlement override")
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
