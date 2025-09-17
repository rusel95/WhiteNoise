# Paywall & Monetization Strategy

This document captures the agreed monetization approach, paywall UX, and implementation checkpoints for the WhiteNoise app. Keep it updated as the plan evolves.

## Monetization Snapshot
- **Model**: Trial-only paywall managed by Adapty (no perpetual free tier).
- **Free Tier**: None. App access requires trial activation, then paid subscription for continued use.
- **Trigger**: Paywall appears on first launch for users without an active entitlement. Debug builds force-show for QA.
- **Offer**: 30-day free trial, then **$0.99 every 3 months** (auto-renewing subscription). Existing subscribers are grandfathered if pricing increases later.

## Paywall Experience
- **Presentation**: Adapty Paywall (remote template) styled to match our night-friendly glass/gradient theme.
- **Content Blocks (in Adapty)**:
  1. Headline – “Unlock Deep Sleep” + brief value subcopy.
  2. Value List – premium sounds, advanced fades, offline mode, sleep timer automations.
  3. Trial Banner – “30 days free, cancel anytime.”
  4. Pricing Footer – “Then $0.99 every 3 months.”
  5. Primary CTA – Start free trial.
  6. Secondary – Restore purchases (no dismiss without entitlement in production).
  7. Legal – Auto-renewal blurb + Terms/Privacy links.
- **Theme**: Use Adapty builder tokens to match dark palette, rounded corners, and spacing.

## Trigger Logic
- **Debug Mode**: Force-show Adapty paywall on app start (feature flag or `#if DEBUG`).
- **Production**:
  - Query Adapty entitlements on launch/foreground; if inactive, present Adapty paywall.
  - Unlock playback only while entitlement is active.
  - On lapse/cancellation, re-present paywall and block playback.
- **Trial Handling**: Use Adapty purchase with intro offer (30-day trial). On success, entitlement active → dismiss paywall; on expiry, entitlement inactive → show paywall.

## Implementation Plan (Adapty)
1. **SDK Integration**
   - Add Adapty via SPM; initialize with API Key on launch (before UI).
   - Store keys in `Configuration/Local.xcconfig`; avoid hardcoding.
2. **Remote Paywall**
   - Create a paywall in Adapty (builder), set placement ID, style to dark/night.
   - Fetch and present Adapty paywall; handle purchase callbacks.
3. **Entitlements Gating**
   - Observe Adapty profile/entitlements; gate playback when inactive.
   - Dismiss paywall on activation; re-present on lapse.
4. **Debug Controls**
   - Force-show paywall in Debug builds; add a hidden reset/restore tester action.
5. **Analytics & Logging**
   - Log `🎯 Paywall.presented`, `✅ Paywall.trialStarted`, `❌ Paywall.purchaseFailed` aligned with Adapty events.
6. **Clean-up**
   - Remove local paywall scaffolding (custom manager/view) in favor of Adapty.

## Progress Tracker
- [x] Monetization model defined (trial-only paywall + 30-day trial + $0.99/quarter).
- [x] Removed local paywall scaffolding (custom manager/view).
- [ ] Adapty SDK integrated (SPM + init + keys).
- [ ] Remote paywall created in Adapty (placement + design).
- [ ] Entitlement gating wired on launch/foreground.
- [ ] Debug/test hooks implemented.
- [ ] Analytics and documentation updates.

## Open Questions
- Final list of premium-only sounds/features for paywall value copy.
- Copy localization requirements (if supporting additional languages).
- Whether to support annual plans (`$3.49/year` equivalent) alongside quarterly option.

Update this document after each milestone so the team can track paywall readiness.
