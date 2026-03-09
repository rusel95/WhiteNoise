//
//  EngagementService.swift
//  WhiteNoise
//
//  Tracks user engagement (session count and cumulative listening time)
//  to gate the paywall behind meaningful usage.
//

import Foundation

@MainActor
protocol EngagementServiceProtocol {
    var hasMetPaywallThreshold: Bool { get }
    var shouldRequestReview: Bool { get }
    func recordSessionStart()
    func reportPlaybackActive(_ isActive: Bool)
    func markReviewRequested()
}

@Observable @MainActor
final class EngagementService: EngagementServiceProtocol {

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    private enum Keys {
        static let sessionCount = "engagement_session_count"
        static let totalListeningSeconds = "engagement_total_listening_seconds"
        static let hasRequestedReview = "engagement_has_requested_review"
    }

    private enum Thresholds {
        static let minimumSessions = 2
        static let minimumListeningSeconds = 300 // 5 minutes
        static let reviewSessionThreshold = 5
    }

    /// Whether the user has met the engagement threshold to see the paywall.
    var hasMetPaywallThreshold: Bool {
        sessionCount >= Thresholds.minimumSessions
            && totalListeningSeconds >= Thresholds.minimumListeningSeconds
    }

    /// Whether the app should request an App Store review this session.
    var shouldRequestReview: Bool {
        sessionCount >= Thresholds.reviewSessionThreshold && !hasRequestedReview
    }

    private var sessionCount: Int {
        get { defaults.integer(forKey: Keys.sessionCount) }
        set { defaults.set(newValue, forKey: Keys.sessionCount) }
    }

    private var totalListeningSeconds: Int {
        get { defaults.integer(forKey: Keys.totalListeningSeconds) }
        set { defaults.set(newValue, forKey: Keys.totalListeningSeconds) }
    }

    private var hasRequestedReview: Bool {
        get { defaults.bool(forKey: Keys.hasRequestedReview) }
        set { defaults.set(newValue, forKey: Keys.hasRequestedReview) }
    }

    @ObservationIgnored
    private var listeningTimer: Task<Void, Never>?

    // MARK: - Public

    /// Call once per app launch to increment the session counter.
    func recordSessionStart() {
        sessionCount += 1
        AnalyticsService.capture(.appLaunched(sessionNumber: sessionCount))
        LoggingService.log(
            "EngagementService: session \(sessionCount), "
            + "total listening \(totalListeningSeconds)s, "
            + "threshold met: \(hasMetPaywallThreshold)"
        )
    }

    /// Start or stop accumulating listening time based on playback state.
    func reportPlaybackActive(_ isActive: Bool) {
        if isActive {
            startListeningTimer()
        } else {
            stopListeningTimer()
        }
    }

    /// Mark that the review prompt has been shown so it won't repeat.
    func markReviewRequested() {
        hasRequestedReview = true
    }

    // MARK: - Private

    private func startListeningTimer() {
        guard listeningTimer == nil else { return }

        listeningTimer = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled, let self else { return }
                self.totalListeningSeconds += 1
            }
        }
    }

    private func stopListeningTimer() {
        listeningTimer?.cancel()
        listeningTimer = nil
    }
}
