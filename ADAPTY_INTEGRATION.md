# Adapty Integration Guide

This guide explains how to wire Adapty for subscriptions, remote paywalls, and entitlement gating in WhiteNoise.

## 1) Add SDK (SPM)
- Xcode → File → Add Packages… → search `https://github.com/adaptyteam/AdaptySDK-iOS`.
- Add both **Adapty** and **AdaptyUI** products to the `WhiteNoise` target.

## 2) Configure Keys
- In `WhiteNoise/Configuration/Local.xcconfig` add:
```
ADAPTY_API_KEY = YOUR_ADAPTY_API_KEY
```
- Add this key to `Info.plist` (already configured):
```
ADAPTY_API_KEY = $(ADAPTY_API_KEY)
```
- At runtime `AdaptyService` reads the API key from `ProcessInfo.environment["ADAPTY_API_KEY"]` first, then fallback to `Info.plist`.

## 3) Initialize Early
- `WhiteNoiseApp.init()` calls `AdaptyService.activate()`:
  - Builds an `AdaptyConfiguration` with the API key and activates Adapty.
  - Asynchronously calls `AdaptyUI.activate()` (inside a `Task`) so the UI toolkit is ready before any paywall presentation.
- Optionally supply a `customerUserId` if you maintain user accounts.

## 4) Create a Remote Paywall
- In Adapty Console → Paywalls Builder:
  - Create a paywall in the builder with the night-friendly theme.
  - Assign a placement (e.g., `main_paywall`).
  - Attach the product with the 30-day trial and quarterly subscription.
  - Ensure Terms & Privacy URLs point to the hosted docs created in `/docs/`.

## 5) Fetch & Present the Paywall
- `EntitlementsCoordinator` loads the Adapty profile on launch/foreground using `try await Adapty.getProfile()`.
- When no premium entitlement is active (or when `FORCE_SHOW_PAYWALL=1`), it fetches the paywall configuration:
  1. `let paywall = try await Adapty.getPaywall(placementId: "main_paywall")`
  2. `let config = try await AdaptyUI.getPaywallConfiguration(forPaywall: paywall)`
- The configuration is stored in `@Published var paywallConfiguration` and `RootView` presents a SwiftUI sheet.
- `PaywallSheetView` wraps `AdaptyPaywallView`, providing callbacks for purchase, restore, and error events.

## 6) Entitlement Gating Flow
- `RootView` owns a `@StateObject EntitlementsCoordinator` and calls `.onAppear { coordinator.onAppLaunch() }` and reacts to scene phase changes.
- `.sheet(isPresented: $coordinator.isPaywallPresented)` renders the paywall when entitlement is missing.
- After purchase/restore, the coordinator enables a short local grace window (≈5 minutes) while awaiting the next profile sync, keeping the sheet dismissed and scheduling the trial-ending reminder. When Adapty confirms the entitlement, the grace window is cleared.

## 7) Offline Behaviour (MVP)
- If the profile fetch fails (e.g., no internet), we set `hasActiveEntitlement = true` and skip the paywall to prioritise UX. Purchases/restores remain unavailable until connectivity returns.
- Long term: restrict offline access to users with cached active entitlements and show a dedicated offline placeholder otherwise.

## 8) Debug & QA
- Set `FORCE_SHOW_PAYWALL=1` in the Run scheme to force the sheet on every launch.
- Consider adding a hidden debug gesture to call `coordinator.onAppLaunch()` or to reset Adapty cache during testing.

## 9) Analytics
- Log key transitions using the existing emoji convention:
  - `🎯 Paywall.presented`
  - `✅ Paywall.trialStarted`
  - `❌ Paywall.purchaseFailed`
  - `🏁 Paywall.dismissed` (entitlement regained)

## 10) Clean-up
- Legacy local paywall scaffolding (`PaywallManager`, `PaywallView`, UIKit presenter) has been replaced with:
  - `WhiteNoise/Services/EntitlementsCoordinator.swift`
  - `WhiteNoise/Views/PaywallSheetView.swift`

## 11) App Store Connect
- Ensure auto-renewable subscription is configured with a 30-day free trial and 3-month paid period.
- Use matching product identifiers in Adapty and StoreKit.
- Test with sandbox testers and TestFlight to confirm paywall presentation, Apple pay sheet, and entitlement updates.
