//
//  TimerServiceTests.swift
//  WhiteNoiseUnitTests
//
//  Basic unit tests for TimerService lifecycle and tick behavior.
//

import XCTest
@testable import WhiteSoundRuslan1234

@MainActor
final class TimerServiceTests: XCTestCase {
    func testStartPauseResumeStop() async throws {
        let svc = TimerService()

        // Start a short timer
        svc.start(mode: .fiveMinutes)
        XCTAssertTrue(svc.isActive)
        let startRemaining = svc.remainingSeconds
        XCTAssertEqual(startRemaining, TimerService.TimerMode.fiveMinutes.totalSeconds)

        // Wait ~2 seconds and verify time decreased
        try await Task.sleep(nanoseconds: 2_200_000_000)
        let after2s = svc.remainingSeconds
        XCTAssertLessThan(after2s, startRemaining, "Timer should count down")

        // Pause and verify it holds steady after 1s
        svc.pause()
        let paused = svc.remainingSeconds
        try await Task.sleep(nanoseconds: 1_200_000_000)
        let pausedAfter = svc.remainingSeconds
        XCTAssertEqual(paused, pausedAfter, "Paused timer should not change remaining seconds")

        // Resume and verify it moves again
        svc.resume()
        try await Task.sleep(nanoseconds: 1_200_000_000)
        let resumedAfter = svc.remainingSeconds
        XCTAssertLessThan(resumedAfter, pausedAfter, "Resumed timer should continue counting down")

        // Stop and verify state cleared
        svc.stop()
        XCTAssertFalse(svc.isActive)
        XCTAssertEqual(svc.remainingSeconds, 0)
        XCTAssertEqual(svc.remainingTime, "")
    }
}
