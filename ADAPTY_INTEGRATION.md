# Adapty Integration Guide

This guide explains how to wire Adapty for subscriptions, remote paywalls, and entitlement gating in WhiteNoise.

## 1) Add SDK (SPM)
- Xcode → File → Add Packages… → search `https://github.com/adaptyteam/AdaptySDK-iOS`.
- Add to the `WhiteNoise` target.

## 2) Configure Keys
- In `WhiteNoise/Configuration/Local.xcconfig` add:
```
ADAPTY_API_KEY = YOUR_ADAPTY_API_KEY
```
- Add this key to `Info.plist` (already configured):
```
ADAPTY_API_KEY = $(ADAPTY_API_KEY)
```
- At runtime `AdaptyService` reads the API key from `ProcessInfo.environment["ADAPTY_API_KEY"]` first, then falls back to `Info.plist`.

## 3) Initialize Early
- `WhiteNoiseApp.init()` calls `AdaptyService.activate()`, which activates Adapty using env/Info.plist value.
- Optionally set a user identifier if needed for analytics (default anonymous is fine).

## 4) Create a Remote Paywall
- In Adapty Console → Paywalls Builder:
  - Create a dark-themed paywall that matches the app (headline, value list, trial/promo copy, Terms/Privacy links).
  - Assign a placement (e.g., `main_paywall`).
  - Attach the product with the 30-day trial and quarterly subscription.

## 5) Present Paywall
- Fetch/Present via Adapty SDK using your placement ID. Wire the primary CTA to `Adapty.makePurchase` (or the builder’s built-in purchase handling if using Adapty UI).
- Handle callbacks to update entitlement-driven UI state.

## 6) Entitlement Gating
- On app launch and when returning to foreground:
  - Request Adapty profile and check the premium entitlement.
  - If inactive → present Adapty Paywall and block playback.
  - If active → dismiss paywall and unlock playback.

## 7) Debug & QA
- Add a DEBUG flag to force-show the paywall on startup for testing.
- Add a hidden gesture to reset and re-check entitlements (useful during QA).

## 8) Analytics
- Log events using existing emoji logging standard:
  - `🎯 Paywall.presented`
  - `✅ Paywall.trialStarted`
  - `❌ Paywall.purchaseFailed`
  - `🏁 Paywall.dismissed` (entitlement active)

## 9) Clean-up
- Custom local paywall scaffolding has been removed:
  - `WhiteNoise/Services/PaywallManager.swift`
  - `WhiteNoise/Views/PaywallView.swift`

## 10) App Store Connect
- Ensure the auto-renewable subscription has a 30-day introductory free trial and 3-month period.
- Use the same product identifier in Adapty.
- Test with Sandbox and TestFlight to verify the Apple pay sheet appears and entitlements activate.
