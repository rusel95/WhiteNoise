//
//  ScreenshotTests.swift
//  WhiteNoiseUnitTests
//
//  Snapshot tests for all major screens.
//  Run with `record = true` once to generate reference images,
//  then set back to `false` for regression testing.
//

import XCTest
import SwiftUI
import SnapshotTesting
@testable import WhiteSoundRuslan1234

@MainActor
final class ScreenshotTests: XCTestCase {

    // Set to true to record new reference snapshots, then flip back to false.
    private let isRecording = false

    // MARK: - Main Screen (WhiteNoisesView)

    func testMainScreen_dark() {
        let view = WhiteNoisesView(viewModel: .makeDefault())
            .environment(EntitlementsCoordinator())
            .preferredColorScheme(.dark)

        assertSnapshot(
            of: UIHostingController(rootView: view),
            as: .image(on: .iPhone13Pro),
            record: isRecording
        )
    }

    func testMainScreen_light() {
        let view = WhiteNoisesView(viewModel: .makeDefault())
            .environment(EntitlementsCoordinator())
            .preferredColorScheme(.light)

        assertSnapshot(
            of: UIHostingController(rootView: view),
            as: .image(on: .iPhone13Pro),
            record: isRecording
        )
    }

    // MARK: - Settings

    func testSettingsView_dark() {
        let view = SettingsView()
            .environment(EntitlementsCoordinator())
            .preferredColorScheme(.dark)

        assertSnapshot(
            of: UIHostingController(rootView: view),
            as: .image(on: .iPhone13Pro),
            record: isRecording
        )
    }

    func testSettingsView_light() {
        let view = SettingsView()
            .environment(EntitlementsCoordinator())
            .preferredColorScheme(.light)

        assertSnapshot(
            of: UIHostingController(rootView: view),
            as: .image(on: .iPhone13Pro),
            record: isRecording
        )
    }

    // MARK: - Timer Picker

    func testTimerPickerView_dark() {
        let view = TimerPickerView(timerMode: .constant(.off))
            .preferredColorScheme(.dark)

        assertSnapshot(
            of: UIHostingController(rootView: view),
            as: .image(on: .iPhone13Pro),
            record: isRecording
        )
    }

    func testTimerPickerView_light() {
        let view = TimerPickerView(timerMode: .constant(.off))
            .preferredColorScheme(.light)

        assertSnapshot(
            of: UIHostingController(rootView: view),
            as: .image(on: .iPhone13Pro),
            record: isRecording
        )
    }

    func testTimerPickerView_withActiveTimer() {
        let view = TimerPickerView(timerMode: .constant(.thirtyMinutes))
            .preferredColorScheme(.dark)

        assertSnapshot(
            of: UIHostingController(rootView: view),
            as: .image(on: .iPhone13Pro),
            record: isRecording
        )
    }

    // MARK: - Paywall

    func testPaywallSheetView() {
        let view = PaywallSheetView(coordinator: EntitlementsCoordinator())
            .preferredColorScheme(.dark)

        assertSnapshot(
            of: UIHostingController(rootView: view),
            as: .image(on: .iPhone13Pro),
            record: isRecording
        )
    }

    // MARK: - iPad Variants

    func testMainScreen_iPad() {
        let view = WhiteNoisesView(viewModel: .makeDefault())
            .environment(EntitlementsCoordinator())
            .preferredColorScheme(.dark)

        assertSnapshot(
            of: UIHostingController(rootView: view),
            as: .image(on: .iPadPro12_9),
            record: isRecording
        )
    }

    func testSettingsView_iPad() {
        let view = SettingsView()
            .environment(EntitlementsCoordinator())
            .preferredColorScheme(.dark)

        assertSnapshot(
            of: UIHostingController(rootView: view),
            as: .image(on: .iPadPro12_9),
            record: isRecording
        )
    }

    func testTimerPickerView_iPad() {
        let view = TimerPickerView(timerMode: .constant(.off))
            .preferredColorScheme(.dark)

        assertSnapshot(
            of: UIHostingController(rootView: view),
            as: .image(on: .iPadPro12_9),
            record: isRecording
        )
    }

    func testPaywallSheetView_iPad() {
        let view = PaywallSheetView(coordinator: EntitlementsCoordinator())
            .preferredColorScheme(.dark)

        assertSnapshot(
            of: UIHostingController(rootView: view),
            as: .image(on: .iPadPro12_9),
            record: isRecording
        )
    }
}
