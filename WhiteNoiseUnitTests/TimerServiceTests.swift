//
//  TimerServiceTests.swift
//  WhiteNoiseUnitTests
//
//  Basic unit tests for TimerService lifecycle and tick behavior.
//  Note: Add a Unit Test target in Xcode and include this file.
//

import XCTest

final class TimerServiceTests: XCTestCase {
    func testStartPauseResumeStop() async throws {
        let svc = await MainActor.run { TimerService() }

        // Start a short timer (use oneMinute but only wait a couple of seconds)
        await MainActor.run { svc.start(mode: .oneMinute) }
        XCTAssertTrue(await MainActor.run { svc.isActive })
        let startRemaining = await MainActor.run { svc.remainingSecondsValue }
        XCTAssertEqual(startRemaining, TimerService.TimerMode.oneMinute.totalSeconds)

        // Wait ~2 seconds and verify time decreased
        try await Task.sleep(nanoseconds: 2_200_000_000)
        let after2s = await MainActor.run { svc.remainingSecondsValue }
        XCTAssertLessThan(after2s, startRemaining, "Timer should count down")

        // Pause and verify it holds steady after 1s
        await MainActor.run { svc.pause() }
        let paused = await MainActor.run { svc.remainingSecondsValue }
        try await Task.sleep(nanoseconds: 1_200_000_000)
        let pausedAfter = await MainActor.run { svc.remainingSecondsValue }
        XCTAssertEqual(paused, pausedAfter, "Paused timer should not change remaining seconds")

        // Resume and verify it moves again
        await MainActor.run { svc.resume() }
        try await Task.sleep(nanoseconds: 1_200_000_000)
        let resumedAfter = await MainActor.run { svc.remainingSecondsValue }
        XCTAssertLessThan(resumedAfter, pausedAfter, "Resumed timer should continue counting down")

        // Stop and verify state cleared
        await MainActor.run { svc.stop() }
        XCTAssertFalse(await MainActor.run { svc.isActive })
        XCTAssertEqual(await MainActor.run { svc.remainingSecondsValue }, 0)
        XCTAssertEqual(await MainActor.run { svc.remainingTime }, "")
    }
}

