# Paywall & Monetization Strategy

This document captures the agreed monetization approach, paywall UX, and implementation checkpoints for the WhiteNoise app. Keep it updated as the plan evolves.

## Monetization Snapshot
- **Model**: Trial-only paywall managed by Adapty (no perpetual free tier).
- **Free Tier**: None. App access requires trial activation, then paid subscription for continued use.
- **Trigger**: Paywall appears on first launch for users without an active entitlement. Debug builds force-show for QA.
- **Offer**: 30-day free trial, then **$0.99 every 3 months** (auto-renewing subscription). Existing subscribers are grandfathered if pricing increases later.

## Paywall Experience
- **Presentation**: Adapty Paywall (remote template) rendered through `AdaptyPaywallView` inside a SwiftUI sheet, matching the dark glass aesthetic.
- **Content Blocks (configured in Adapty)**:
  1. Headline – “Unlock Deep Sleep” + brief value subcopy.
  2. Value list – premium sounds, advanced fades, offline mode, sleep timer automations.
  3. Trial banner – “30 days free, cancel anytime.”
  4. Pricing footer – “Then $0.99 every 3 months.”
  5. Primary CTA – Start free trial.
  6. Secondary – Restore purchases (no free dismiss in production).
  7. Legal – Auto-renewal blurb + Terms/Privacy links.
- **Theme**: Use builder tokens to keep typography, gradients, and spacing consistent with the rest of the app.

## Trigger Logic
- **Debug mode**: Set `FORCE_SHOW_PAYWALL=1` to present the sheet immediately for QA.
- **Production**:
  - `EntitlementsCoordinator` loads the Adapty profile on launch/foreground; if entitlement inactive, it fetches the paywall configuration and toggles the sheet.
  - Playback stays unlocked only while entitlement is active; on lapse/cancellation the sheet reappears.
- **Trial handling**: Adapty purchase with 30-day intro trial. On success or restore, entitlements refresh and the sheet dismisses. On expiry, entitlements drop→sheet shows again.

## Implementation Plan (Adapty)
1. **SDK initialization**
   - Add Adapty + AdaptyUI (SPM). `AdaptyService.activate()` builds a configuration, activates Adapty, then awaits `AdaptyUI.activate()`.
2. **Remote paywall setup**
   - Design paywall in Adapty Builder, attach quarterly product with trial, set placement ID (default `main_paywall`), align copy/colors.
3. **Entitlement coordinator**
   - `EntitlementsCoordinator` uses async/await (`Adapty.getProfile`, `AdaptyUI.getPaywallConfiguration`) to determine access and cache paywall configuration.
4. **UI wiring**
   - `RootView` owns the coordinator and presents `PaywallSheetView` via `.sheet(isPresented:)`.
   - `PaywallSheetView` hosts `AdaptyPaywallView` and forwards purchase/restore/rendering callbacks back to the coordinator.
5. **Debug controls**
   - `FORCE_SHOW_PAYWALL` env variable for QA; consider hidden reset gesture.
6. **Analytics & logging**
   - Log `🎯 Paywall.presented`, `✅ Paywall.trialStarted`, `❌ Paywall.purchaseFailed`, `🏁 Paywall.dismissed`.
7. **Offline policy (MVP)**
   - If profile fetch fails (offline), mark entitlement as active and skip the sheet to prioritize UX. Revisit later to tighten revenue guardrails.

## Progress Tracker
- [x] Monetization model defined (trial-only paywall + 30-day trial + $0.99/quarter).
- [x] Removed local paywall scaffolding (custom manager/view).
- [x] Adapty SDK integrated (SPM + init + keys via env/Info.plist).
- [ ] Remote paywall created in Adapty (placement + design).
- [x] Entitlement gating wired on launch/foreground (EntitlementsCoordinator + RootView).
- [x] Debug/test hooks implemented (FORCE_SHOW_PAYWALL env + sheet wiring).
- [ ] Analytics and documentation updates.

## Open Questions
- Final list of premium-only sounds/features for paywall value copy.
- Copy localization requirements (if supporting additional languages).
- Whether to support annual plans (`$3.49/year` equivalent) alongside quarterly option.

Update this document after each milestone so the team can track paywall readiness.
