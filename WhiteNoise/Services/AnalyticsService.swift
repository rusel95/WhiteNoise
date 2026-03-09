//
//  AnalyticsService.swift
//  WhiteNoise
//
//  Thin wrapper around PostHog for product analytics.
//  All event names and property keys are centralised here.
//

import Foundation
import PostHog

// MARK: - Event Definitions

enum AnalyticsEvent {
    // Playback
    case playbackStarted(soundCount: Int, soundNames: [String])
    case playbackPaused(soundCount: Int, listeningSeconds: Int)
    case soundToggled(name: String, variant: String, isOn: Bool)
    case soundVolumeChanged(name: String, volume: Float)
    case soundVariantChanged(name: String, from: String, to: String)

    // Timer
    case timerStarted(mode: String, durationSeconds: Int)
    case timerCompleted(mode: String, durationSeconds: Int)
    case timerCancelled(mode: String, remainingSeconds: Int)

    // Paywall & Subscription
    case paywallShown(offering: String?)
    case paywallDismissed
    case purchaseCompleted(offering: String?)
    case purchaseFailed(error: String)
    case purchaseCancelled
    case restoreCompleted(hasEntitlement: Bool)
    case restoreFailed(error: String)

    // Settings
    case settingsOpened
    case darkModeToggled(isOn: Bool)
    case shareAppTapped
    case feedbackTapped

    // App Lifecycle
    case appLaunched(sessionNumber: Int)
    case appForegrounded

    var name: String {
        switch self {
        case .playbackStarted: return "playback_started"
        case .playbackPaused: return "playback_paused"
        case .soundToggled: return "sound_toggled"
        case .soundVolumeChanged: return "sound_volume_changed"
        case .soundVariantChanged: return "sound_variant_changed"
        case .timerStarted: return "timer_started"
        case .timerCompleted: return "timer_completed"
        case .timerCancelled: return "timer_cancelled"
        case .paywallShown: return "paywall_shown"
        case .paywallDismissed: return "paywall_dismissed"
        case .purchaseCompleted: return "purchase_completed"
        case .purchaseFailed: return "purchase_failed"
        case .purchaseCancelled: return "purchase_cancelled"
        case .restoreCompleted: return "restore_completed"
        case .restoreFailed: return "restore_failed"
        case .settingsOpened: return "settings_opened"
        case .darkModeToggled: return "dark_mode_toggled"
        case .shareAppTapped: return "share_app_tapped"
        case .feedbackTapped: return "feedback_tapped"
        case .appLaunched: return "app_launched"
        case .appForegrounded: return "app_foregrounded"
        }
    }

    var properties: [String: Any] {
        switch self {
        case .playbackStarted(let soundCount, let soundNames):
            return ["sound_count": soundCount, "sound_names": soundNames]
        case .playbackPaused(let soundCount, let listeningSeconds):
            return ["sound_count": soundCount, "listening_seconds": listeningSeconds]
        case .soundToggled(let name, let variant, let isOn):
            return ["sound_name": name, "variant": variant, "is_on": isOn]
        case .soundVolumeChanged(let name, let volume):
            return ["sound_name": name, "volume": volume]
        case .soundVariantChanged(let name, let from, let to):
            return ["sound_name": name, "from_variant": from, "to_variant": to]
        case .timerStarted(let mode, let durationSeconds):
            return ["timer_mode": mode, "duration_seconds": durationSeconds]
        case .timerCompleted(let mode, let durationSeconds):
            return ["timer_mode": mode, "duration_seconds": durationSeconds]
        case .timerCancelled(let mode, let remainingSeconds):
            return ["timer_mode": mode, "remaining_seconds": remainingSeconds]
        case .paywallShown(let offering):
            return offering.map { ["offering": $0] } ?? [:]
        case .paywallDismissed:
            return [:]
        case .purchaseCompleted(let offering):
            return offering.map { ["offering": $0] } ?? [:]
        case .purchaseFailed(let error):
            return ["error": error]
        case .purchaseCancelled:
            return [:]
        case .restoreCompleted(let hasEntitlement):
            return ["has_entitlement": hasEntitlement]
        case .restoreFailed(let error):
            return ["error": error]
        case .settingsOpened:
            return [:]
        case .darkModeToggled(let isOn):
            return ["is_dark_mode": isOn]
        case .shareAppTapped:
            return [:]
        case .feedbackTapped:
            return [:]
        case .appLaunched(let sessionNumber):
            return ["session_number": sessionNumber]
        case .appForegrounded:
            return [:]
        }
    }
}

// MARK: - Implementation

@MainActor
enum AnalyticsService {
    static func capture(_ event: AnalyticsEvent) {
        PostHogSDK.shared.capture(event.name, properties: event.properties)
    }

    static func identify(userId: String, properties: [String: Any] = [:]) {
        PostHogSDK.shared.identify(userId, userProperties: properties)
    }
}
