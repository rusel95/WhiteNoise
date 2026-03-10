//
//  EngagementServiceTests.swift
//  WhiteNoiseUnitTests
//
//  Unit tests for EngagementService threshold transitions,
//  timer accumulation, and review suppression.
//

import XCTest
@testable import WhiteSoundRuslan1234

@MainActor
final class EngagementServiceTests: XCTestCase {

    private var sut: EngagementService!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "EngagementServiceTests")!
        defaults.removePersistentDomain(forName: "EngagementServiceTests")
        sut = EngagementService(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "EngagementServiceTests")
        defaults = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Session Count

    func testRecordSessionStartIncrementsCount() {
        sut.recordSessionStart()
        sut.recordSessionStart()

        // After 2 sessions, threshold requires >= 2 sessions AND >= 300s listening
        // With 0 listening seconds, threshold should NOT be met
        XCTAssertFalse(sut.hasMetPaywallThreshold)
    }

    // MARK: - Paywall Threshold

    func testPaywallThresholdNotMetWithOnlyOneSessions() {
        sut.recordSessionStart()
        // Simulate listening by directly setting defaults
        defaults.set(500, forKey: "engagement_total_listening_seconds")

        XCTAssertFalse(sut.hasMetPaywallThreshold, "1 session should not meet threshold even with enough listening time")
    }

    func testPaywallThresholdNotMetWithInsufficientListening() {
        sut.recordSessionStart()
        sut.recordSessionStart()
        defaults.set(100, forKey: "engagement_total_listening_seconds")

        XCTAssertFalse(sut.hasMetPaywallThreshold, "Insufficient listening time should not meet threshold")
    }

    func testPaywallThresholdMetWhenBothConditionsSatisfied() {
        sut.recordSessionStart()
        sut.recordSessionStart()
        defaults.set(300, forKey: "engagement_total_listening_seconds")

        XCTAssertTrue(sut.hasMetPaywallThreshold, "2+ sessions and 300+ seconds should meet threshold")
    }

    // MARK: - Review Request

    func testShouldRequestReviewAfterFiveSessions() {
        for _ in 1...5 {
            sut.recordSessionStart()
        }

        XCTAssertTrue(sut.shouldRequestReview, "Should request review after 5 sessions")
    }

    func testShouldNotRequestReviewBeforeFiveSessions() {
        for _ in 1...4 {
            sut.recordSessionStart()
        }

        XCTAssertFalse(sut.shouldRequestReview, "Should not request review before 5 sessions")
    }

    func testMarkReviewRequestedSuppressesFutureRequests() {
        for _ in 1...5 {
            sut.recordSessionStart()
        }
        XCTAssertTrue(sut.shouldRequestReview)

        sut.markReviewRequested()
        XCTAssertFalse(sut.shouldRequestReview, "Review should not be requested after being marked")
    }

    // MARK: - Listening Timer

    func testReportPlaybackActiveStartsTimer() async throws {
        sut.reportPlaybackActive(true)

        // Wait ~2 seconds for the timer to accumulate
        try await Task.sleep(nanoseconds: 2_200_000_000)

        sut.reportPlaybackActive(false)

        let seconds = defaults.integer(forKey: "engagement_total_listening_seconds")
        XCTAssertGreaterThanOrEqual(seconds, 1, "Timer should have accumulated at least 1 second")
    }

    func testReportPlaybackInactiveStopsTimer() async throws {
        sut.reportPlaybackActive(true)
        try await Task.sleep(nanoseconds: 1_200_000_000)
        sut.reportPlaybackActive(false)

        let secondsAfterStop = defaults.integer(forKey: "engagement_total_listening_seconds")
        try await Task.sleep(nanoseconds: 1_200_000_000)
        let secondsLater = defaults.integer(forKey: "engagement_total_listening_seconds")

        XCTAssertEqual(secondsAfterStop, secondsLater, "Timer should not accumulate after stopping")
    }
}
