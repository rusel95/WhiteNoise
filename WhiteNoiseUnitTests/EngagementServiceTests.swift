//
//  EngagementServiceTests.swift
//  WhiteNoiseUnitTests
//
//  Unit tests for EngagementService paywall threshold and review prompt logic.
//

import XCTest
// @testable import WhiteNoise  // Uncomment when test target is properly configured

final class EngagementServiceTests: XCTestCase {

    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "EngagementServiceTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
    }

    override func tearDown() {
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    // MARK: - Paywall Threshold

    @MainActor
    func testPaywallThresholdNotMetInitially() {
        let svc = EngagementService(defaults: defaults)
        XCTAssertFalse(svc.hasMetPaywallThreshold)
    }

    @MainActor
    func testPaywallThresholdRequiresBothSessionsAndListening() {
        let svc = EngagementService(defaults: defaults)

        // Record 2 sessions — threshold still not met (no listening time)
        svc.recordSessionStart()
        svc.recordSessionStart()
        XCTAssertFalse(svc.hasMetPaywallThreshold, "Sessions alone should not meet threshold")

        // Simulate 300 seconds of listening via UserDefaults
        defaults.set(300, forKey: "engagement_total_listening_seconds")
        XCTAssertTrue(svc.hasMetPaywallThreshold, "2 sessions + 300s listening should meet threshold")
    }

    @MainActor
    func testPaywallThresholdNotMetWithOnlyListening() {
        let svc = EngagementService(defaults: defaults)

        // Only listening, no sessions recorded
        defaults.set(500, forKey: "engagement_total_listening_seconds")
        XCTAssertFalse(svc.hasMetPaywallThreshold, "Listening alone should not meet threshold")
    }

    @MainActor
    func testPaywallThresholdNotMetWithOnlyOneSessions() {
        let svc = EngagementService(defaults: defaults)

        svc.recordSessionStart()
        defaults.set(500, forKey: "engagement_total_listening_seconds")
        XCTAssertFalse(svc.hasMetPaywallThreshold, "1 session should not meet threshold even with listening")
    }

    // MARK: - Session Counting

    @MainActor
    func testRecordSessionStartIncrementsCount() {
        let svc = EngagementService(defaults: defaults)

        svc.recordSessionStart()
        XCTAssertEqual(defaults.integer(forKey: "engagement_session_count"), 1)

        svc.recordSessionStart()
        XCTAssertEqual(defaults.integer(forKey: "engagement_session_count"), 2)

        svc.recordSessionStart()
        XCTAssertEqual(defaults.integer(forKey: "engagement_session_count"), 3)
    }

    // MARK: - Review Prompt

    @MainActor
    func testShouldRequestReviewFalseBeforeThreshold() {
        let svc = EngagementService(defaults: defaults)

        for _ in 1...4 {
            svc.recordSessionStart()
        }
        XCTAssertFalse(svc.shouldRequestReview, "Should not request review before 5th session")
    }

    @MainActor
    func testShouldRequestReviewTrueAtThreshold() {
        let svc = EngagementService(defaults: defaults)

        for _ in 1...5 {
            svc.recordSessionStart()
        }
        XCTAssertTrue(svc.shouldRequestReview, "Should request review at 5th session")
    }

    @MainActor
    func testShouldRequestReviewTrueAfterThreshold() {
        let svc = EngagementService(defaults: defaults)

        for _ in 1...7 {
            svc.recordSessionStart()
        }
        XCTAssertTrue(svc.shouldRequestReview, "Should request review after threshold if not yet requested")
    }

    @MainActor
    func testShouldRequestReviewFalseAfterMarked() {
        let svc = EngagementService(defaults: defaults)

        for _ in 1...5 {
            svc.recordSessionStart()
        }
        XCTAssertTrue(svc.shouldRequestReview)

        svc.markReviewRequested()
        XCTAssertFalse(svc.shouldRequestReview, "Should not request review after marking as requested")
    }

    @MainActor
    func testMarkReviewRequestedPersists() {
        let svc = EngagementService(defaults: defaults)

        for _ in 1...5 {
            svc.recordSessionStart()
        }
        svc.markReviewRequested()

        // Create a new instance with the same defaults — simulates app relaunch
        let svc2 = EngagementService(defaults: defaults)
        XCTAssertFalse(svc2.shouldRequestReview, "Review requested flag should persist across instances")
    }

    // MARK: - Listening Timer

    @MainActor
    func testReportPlaybackActiveAccumulatesTime() async throws {
        let svc = EngagementService(defaults: defaults)

        svc.reportPlaybackActive(true)
        try await Task.sleep(nanoseconds: 2_500_000_000) // ~2.5 seconds
        svc.reportPlaybackActive(false)

        let seconds = defaults.integer(forKey: "engagement_total_listening_seconds")
        XCTAssertGreaterThanOrEqual(seconds, 2, "Should accumulate at least 2 seconds")
        XCTAssertLessThanOrEqual(seconds, 3, "Should not accumulate more than 3 seconds")
    }

    @MainActor
    func testReportPlaybackStopsAccumulatingWhenInactive() async throws {
        let svc = EngagementService(defaults: defaults)

        svc.reportPlaybackActive(true)
        try await Task.sleep(nanoseconds: 1_500_000_000)
        svc.reportPlaybackActive(false)

        let secondsAfterStop = defaults.integer(forKey: "engagement_total_listening_seconds")

        // Wait more and verify it doesn't increase
        try await Task.sleep(nanoseconds: 1_500_000_000)
        let secondsLater = defaults.integer(forKey: "engagement_total_listening_seconds")
        XCTAssertEqual(secondsAfterStop, secondsLater, "Listening time should not increase after stopping")
    }
}
