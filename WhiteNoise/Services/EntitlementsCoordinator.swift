//
//  EntitlementsCoordinator.swift
//  WhiteNoise
//
//  Handles Adapty entitlement checks and paywall presentation lifecycle.
//

import Foundation
import SwiftUI
import UserNotifications

#if canImport(Adapty)
import Adapty
#endif
#if canImport(AdaptyUI)
import AdaptyUI
#endif

/// Coordinates subscription entitlements, paywall presentation, and trial reminders.
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

#if canImport(Adapty)
    private let trialReminderScheduler = TrialReminderScheduler()
    private let defaults = UserDefaults.standard
    private let overrideKey = "whitenoise_entitlement_override_until"
    private let overrideDuration: TimeInterval = 300 // 5 minutes grace while awaiting profile sync

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
#endif
    private let placementId = ProcessInfo.processInfo.environment["ADAPTY_PLACEMENT_ID"] ?? "main_paywall"

    func onAppLaunch() {
        print("🎯 EntitlementsCoordinator.onAppLaunch")
        Task { await refreshEntitlement(forceShow: isForceShowEnabled()) }
    }

    func onAppForeground() {
        print("🎯 EntitlementsCoordinator.onAppForeground")
        Task { await refreshEntitlement(forceShow: false) }
    }

    func handlePurchaseCompleted(profile: AdaptyProfile? = nil) {
#if canImport(Adapty)
        activateEntitlementOverride()
        if let access = profile?.accessLevels["premium"] {
            trialReminderScheduler.scheduleReminderIfNeeded(for: access)
        }
#endif
        hasActiveEntitlement = true
        isPaywallPresented = false
        print("✅ EntitlementsCoordinator.handlePurchaseCompleted - Override active, hiding paywall")
        Task { await refreshEntitlement(forceShow: false) }
    }

    func handleRestoreCompleted(with profile: AdaptyProfile) {
#if canImport(Adapty)
        activateEntitlementOverride()
        if let access = profile.accessLevels["premium"] {
            trialReminderScheduler.scheduleReminderIfNeeded(for: access)
        } else {
            trialReminderScheduler.cancelReminder()
        }
#endif
        hasActiveEntitlement = profile.accessLevels["premium"]?.isActive == true
        isPaywallPresented = !hasActiveEntitlement && !isForceShowEnabled()
        print("♻️ EntitlementsCoordinator.handleRestoreCompleted - Override active, refreshing")
        Task { await refreshEntitlement(forceShow: false) }
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
            if let access = profile.accessLevels["premium"], access.isActive {
#if canImport(Adapty)
                clearEntitlementOverride()
                trialReminderScheduler.scheduleReminderIfNeeded(for: access)
#endif
                hasActiveEntitlement = true
                isPaywallPresented = false
                print("✅ EntitlementsCoordinator.refreshEntitlement - Premium active via profile")
                return
            }

#if canImport(Adapty)
            if isEntitlementOverrideActive {
                hasActiveEntitlement = true
                isPaywallPresented = false
                print("⏱️ EntitlementsCoordinator.refreshEntitlement - Override active, keeping paywall hidden")
                return
            }
            trialReminderScheduler.cancelReminder()
#endif

            hasActiveEntitlement = false

            try await loadPaywallConfiguration()
            isPaywallPresented = true
            print("🔒 EntitlementsCoordinator.refreshEntitlement - Paywall shown (no entitlement)")
        } catch {
            print("⚠️ EntitlementsCoordinator.refreshEntitlement - profile fetch failed: \(error.localizedDescription)")
            // MVP offline policy: allow playback when profile is unavailable.
            #if canImport(Adapty)
            if isEntitlementOverrideActive {
                hasActiveEntitlement = true
                isPaywallPresented = false
                print("⏱️ EntitlementsCoordinator.refreshEntitlement - Override active during failure")
            } else {
                hasActiveEntitlement = true
                isPaywallPresented = false
            }
            #else
            hasActiveEntitlement = true
            isPaywallPresented = false
            #endif
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
        print("🧩 EntitlementsCoordinator.loadPaywallConfiguration - Loaded configuration for placement \(placementId)")
        #else
        print("ℹ️ EntitlementsCoordinator.loadPaywallConfiguration - AdaptyUI not available")
        #endif
    }

    private func isForceShowEnabled() -> Bool {
        ProcessInfo.processInfo.environment["FORCE_SHOW_PAYWALL"] == "1"
    }
}

#if canImport(Adapty)
/// Schedules a local notification one day before the trial expires.
private final class TrialReminderScheduler {
    private let notificationCenter = UNUserNotificationCenter.current()
    private let defaults = UserDefaults.standard
    private let reminderIdentifier = "whitenoise_trial_reminder"
    private let scheduledDateKey = "trialReminderScheduledDate"

    func scheduleReminderIfNeeded(for accessLevel: AdaptyProfile.AccessLevel) {
        guard let expiresAt = accessLevel.expiresAt,
              accessLevel.activeIntroductoryOfferType == "free_trial",
              !accessLevel.isLifetime else {
            cancelReminder()
            return
        }

        guard let reminderDate = Calendar.current.date(byAdding: .day, value: -1, to: expiresAt),
              reminderDate > Date() else {
            cancelReminder()
            return
        }

        if let stored = defaults.object(forKey: scheduledDateKey) as? Date,
           abs(stored.timeIntervalSince(reminderDate)) < 1 {
            return
        }

        notificationCenter.getNotificationSettings { [weak self] settings in
            guard let self = self else { return }
            switch settings.authorizationStatus {
            case .notDetermined:
                self.notificationCenter.requestAuthorization(options: [.alert, .sound]) { granted, _ in
                    if granted {
                        self.createReminder(at: reminderDate)
                    }
                }
            case .authorized, .provisional:
                self.createReminder(at: reminderDate)
            default:
                break
            }
        }
    }

    func cancelReminder() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [reminderIdentifier])
        defaults.removeObject(forKey: scheduledDateKey)
    }

    private func createReminder(at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Trial Ending Soon"
        content.body = "Your WhiteNoise trial ends tomorrow. Start your subscription to keep relaxing sounds playing without interruption."
        content.sound = .default

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: reminderIdentifier, content: content, trigger: trigger)

        notificationCenter.add(request) { [weak self] error in
            guard error == nil, let self = self else { return }
            self.defaults.set(date, forKey: self.scheduledDateKey)
        }
    }
}
#endif
