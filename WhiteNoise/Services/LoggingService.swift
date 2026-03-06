//
//  LoggingService.swift
//  WhiteNoise
//
//  PERFORMANCE: Centralized logging that can be disabled in production builds
//

import Foundation
import os.log

enum LoggingService {
    private static let osLog = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "WhiteNoise", category: "app")
    /// PERFORMANCE FIX: Logs only in DEBUG builds to reduce overhead in production
    static func log(_ items: Any..., separator: String = " ", terminator: String = "\n") {
        #if DEBUG
        let message = items.map { "\($0)" }.joined(separator: separator)
        print(message, terminator: terminator)
        #endif
    }

    /// Logs regardless of build configuration — uses os_log with private visibility
    /// so messages are redacted in non-debug environments (device console, sysdiagnose).
    static func logAlways(_ items: Any..., separator: String = " ", terminator: String = "\n") {
        let message = items.map { "\($0)" }.joined(separator: separator)
        os_log("%{private}s", log: Self.osLog, type: .error, message)
    }

    /// Logs with a specific prefix emoji for categorization
    static func log(_ prefix: String, _ items: Any..., separator: String = " ") {
        #if DEBUG
        let message = items.map { "\($0)" }.joined(separator: separator)
        print("\(prefix) \(message)")
        #endif
    }
}

// MARK: - Convenience Extensions

extension LoggingService {
    // Category-specific logging methods
    static func logAudio(_ message: String) {
        log("🎵", message)
    }

    static func logTimer(_ message: String) {
        log("⏱️", message)
    }

    static func logState(_ message: String) {
        log("📊", message)
    }

    static func logAction(_ message: String) {
        log("🎯", message)
    }

    static func logWarning(_ message: String) {
        log("⚠️", message)
    }

    static func logError(_ message: String) {
        logAlways("❌", message)  // Always log errors
    }

    static func logSuccess(_ message: String) {
        log("✅", message)
    }

    static func logFlow(_ message: String) {
        log("🔄", message)
    }
}
