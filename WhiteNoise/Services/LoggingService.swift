//
//  LoggingService.swift
//  WhiteNoise
//
//  PERFORMANCE: Centralized logging that can be disabled in production builds
//

import Foundation

enum LoggingService {
    /// PERFORMANCE FIX: Logs only in DEBUG builds to reduce overhead in production
    static func log(_ items: Any..., separator: String = " ", terminator: String = "\n") {
        #if DEBUG
        let message = items.map { "\($0)" }.joined(separator: separator)
        print(message, terminator: terminator)
        #endif
    }

    /// Always logs regardless of build configuration (use sparingly for critical errors)
    static func logAlways(_ items: Any..., separator: String = " ", terminator: String = "\n") {
        let message = items.map { "\($0)" }.joined(separator: separator)
        print(message, terminator: terminator)
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
