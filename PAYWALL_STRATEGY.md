# Paywall & Monetization Strategy

This document captures the agreed monetization approach, paywall UX, and implementation checkpoints for the WhiteNoise app. Keep it updated as the plan evolves.

## Monetization Snapshot
- **Model**: Freemium with delayed paywall and free trial.
- **Free Tier**: Core experience remains free (baseline sound set, essential controls).
- **Trigger**: Paywall appears after 7 full days of free usage. Debug builds override to present immediately on launch.
- **Offer**: 30-day free trial, then **$0.99 every 3 months** (auto-renewing subscription). Existing subscribers are grandfathered if pricing increases later.

## Paywall Experience
- **Presentation**: Full-screen SwiftUI overlay using existing dark/glass gradients.
- **Content Blocks**:
  1. **Headline** – “Unlock Deep Sleep” + sub-copy highlighting unlimited access.
  2. **Value List** – 3-4 bullet highlights (premium sounds, advanced fades, offline mode, sleep timer automations).
  3. **Trial Banner** – “30 days free, cancel anytime.”
  4. **Pricing Footer** – “Then $0.99 every 3 months.”
  5. **Primary CTA** – `Start 30-Day Free Trial` (gradient button).
  6. **Secondary CTA** – `Not Now` (only available while user still in the free 7-day window).
  7. **Legal Notice** – Auto-renewal blurb plus links to Terms & Privacy.
- **Theme**: Matches night-friendly black/teal palette from `AppConstants.UI` and supports safe areas on iPhone/iPad.

## Trigger Logic
- **Debug Mode**: Always present paywall at app start (`PaywallManager.shouldShowPaywall == true`).
- **Production**:
  - Store first-run timestamp in `UserDefaults` (`installDate`).
  - After 7 days elapsed, present paywall unless the user has an active trial/subscription or is mid-session.
  - Offer daily reminders post 7-day mark until the trial is started.
- **Trial Handling**: On successful purchase/trial activation, dismiss paywall and store entitlement via RevenueCat/Adapty SDK status.

## Implementation Plan
1. **Service Layer**
   - Create `PaywallManager` to encapsulate gating (install date, debug override, entitlement checks).
   - Integrate SDK entitlement observer (e.g., RevenueCat `CustomerInfo` or Adapty `Profile`) to update app state.
2. **State Management**
   - Expose `@Published var isPaywallPresented` in a dedicated `PaywallViewModel` or extend `WhiteNoisesViewModel`.
   - Hook manager checks into app launch (`WhiteNoiseApp` or `ContentView` `onAppear`).
3. **UI**
   - Build `PaywallView` (SwiftUI) using gradients from `AppConstants` and componentizing buttons for reuse.
   - Provide preview data for design iteration.
4. **Debug Controls**
   - Inject overrides via `#if DEBUG` or environment variable.
   - Add UITest that ensures paywall appears in debug configuration.
5. **Analytics & Logging**
   - Log events using emoji standard (`🎯 Paywall.presented`, `✅ Paywall.trialStarted`, `⚠️ Paywall.dismissedWithoutPurchase`).
6. **A/B Test Readiness**
   - Define configuration interface compatible with Adapty/RevenueCat remote paywalls for future experiments.

## Progress Tracker
- [x] Monetization model defined (delayed paywall + 30-day trial + $0.99/quarter).
- [ ] `PaywallManager` scaffolding.
- [ ] Paywall SwiftUI layout.
- [ ] SDK integration for purchases/trials.
- [ ] Debug/test hooks implemented.
- [ ] Analytics and documentation updates.

## Open Questions
- Final list of premium-only sounds/features for paywall value copy.
- Copy localization requirements (if supporting additional languages).
- Whether to support annual plans (`$3.49/year` equivalent) alongside quarterly option.

Update this document after each milestone so the team can track paywall readiness.
