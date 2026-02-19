# RevenueCat Integration Guide

This guide explains how to wire RevenueCat for subscriptions, remote paywalls, and entitlement gating in WhiteNoise.

## 1) Add SDK (SPM)
- Xcode → File → Add Packages… → search `https://github.com/RevenueCat/purchases-ios`.
- Add both **RevenueCat** and **RevenueCatUI** products to the `WhiteNoise` target. See [RevenueCat docs](https://www.revenuecat.com/docs/getting-started) for the latest instructions.

## 2) Configure Keys
- In `WhiteNoise/Configuration/Local.xcconfig` add your public SDK key:
```
REVENUECAT_API_KEY = YOUR_REVENUECAT_API_KEY
```
- Optional overrides if you use custom identifiers in the dashboard:
```
REVENUECAT_ENTITLEMENT_ID = premium
REVENUECAT_OFFERING_ID = default
```
- `Info.plist` already exposes `REVENUECAT_API_KEY` via `$(REVENUECAT_API_KEY)` so it can be read at runtime.
- At runtime `RevenueCatService` checks environment variables first, then falls back to `Info.plist`.

## 3) Initialize Early
- `WhiteNoiseApp.init()` calls `RevenueCatService.configure()`:
  - Builds a `Configuration.Builder` with the API key and enables StoreKit 2 mode
    (`Purchases.configure(with: Configuration.Builder(withAPIKey: key).with(storeKitVersion: .storeKit2).build())`).
  - Configure before presenting any paywall to follow the [official quickstart](https://www.revenuecat.com/docs/getting-started). 
- Provide a `customerUserID` if/when the app gains first-party accounts.

## 4) Create a Remote Paywall
- In RevenueCat Dashboard → Paywalls:
  - Create the paywall (night-friendly theme) and associate it with the primary offering.
  - Attach the product with the 30-day free trial and quarterly subscription price.
  - Confirm Terms & Privacy URLs point to the docs in `/docs/`.
  - Publish the paywall so SDK fetches it through Offerings.

## 5) Fetch & Present the Paywall
- `EntitlementsCoordinator` uses `try await Purchases.shared.customerInfo()` to read entitlements on launch/foreground.
- When no premium entitlement is active (or `FORCE_SHOW_PAYWALL=1`), it loads an `Offering` via `try await Purchases.shared.offerings()` (respecting `REVENUECAT_OFFERING_ID` when provided).
- The resolved offering is stored in `@Published var currentOffering` and `RootView` presents a SwiftUI sheet.
- `PaywallSheetView` renders `RevenueCatUI.PaywallView(offering:)` and listens for the official callbacks (`onPurchaseCompleted`, `onRestoreCompleted`, `onRequestedDismissal`, etc.).

## 6) Entitlement Gating Flow
- `RootView` owns a `@StateObject EntitlementsCoordinator`, calls `.onAppear { coordinator.onAppLaunch() }`, and toggles `.sheet(isPresented:)` based on `isPaywallPresented`.
- After purchase/restore the coordinator enables a five-minute local grace window while the next `customerInfo()` sync completes, and schedules the trial-ending reminder when applicable. When RevenueCat reports the entitlement, the override clears and the sheet stays dismissed.

## 7) Offline Behaviour (MVP)
- If fetching `customerInfo()` or `offerings()` fails (e.g., offline), we currently allow playback by marking `hasActiveEntitlement = true`. Purchases/restores remain unavailable until connectivity returns.
- Future tightening: cache last verified entitlement and block playback if it is expired.

## 8) Debug & QA
- Set `FORCE_SHOW_PAYWALL=1` in the Run scheme to force the sheet on every launch.
- You can hook additional debug actions to `EntitlementsCoordinator` for cache resets if needed (`Purchases.shared.syncPurchases()` may also help during QA).

## 9) Logging
- Continue using the emoji logging standard:
  - `🎯 Paywall.presented`
  - `✅ Paywall.trialStarted`
  - `❌ Paywall.purchaseFailed`
  - `🏁 Paywall.dismissed`

## 10) App Store Connect
- Ensure the auto-renewable subscription is configured with a 30-day free trial and 3-month paid period.
- Match product identifiers between StoreKit configuration and RevenueCat catalog.
- Test with sandbox testers/TestFlight to confirm paywall presentation, Apple purchase sheet, and entitlement updates per [RevenueCat testing docs](https://www.revenuecat.com/docs/testing). 
