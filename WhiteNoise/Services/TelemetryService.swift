//
//  TelemetryService.swift
//  WhiteNoise
//
//  Centralised Sentry integration for non-fatal telemetry events.
//

import Foundation
import Sentry

enum TelemetryLevel: String {
    case info
    case warning
    case error

    var sentryLevel: SentryLevel {
        switch self {
        case .info:
            return .info
        case .warning:
            return .warning
        case .error:
            return .error
        }
    }

    var consolePrefix: String {
        switch self {
        case .info:
            return "ℹ️"
        case .warning:
            return "⚠️"
        case .error:
            return "❌"
        }
    }
}

enum TelemetryService {
    static func captureNonFatal(
        message: String,
        level: TelemetryLevel = .warning,
        extra: [String: Any] = [:],
        file: StaticString = #fileID,
        function: StaticString = #function,
        line: UInt = #line
    ) {
        let formattedMessage = format(message: message, file: file, function: function, line: line)
        var payload = baseExtras(file: file, function: function, line: line)
        payload.merge(sanitised(extras: extra)) { _, new in new }

        SentrySDK.capture(message: formattedMessage) { scope in
            scope.setLevel(level.sentryLevel)
            scope.setExtras(payload)
            scope.setTag(value: level.rawValue, key: "telemetry.level")
        }

        logToConsole(level: level, message: formattedMessage)
    }

    static func captureNonFatal(
        error: Error,
        message: String? = nil,
        level: TelemetryLevel = .error,
        extra: [String: Any] = [:],
        file: StaticString = #fileID,
        function: StaticString = #function,
        line: UInt = #line
    ) {
        let formattedMessage = format(
            message: message ?? "Captured non-fatal error",
            file: file,
            function: function,
            line: line
        )

        var payload = baseExtras(file: file, function: function, line: line)
        payload["error.description"] = String(describing: error)

        if let nsError = error as NSError? {
            payload["error.domain"] = nsError.domain
            payload["error.code"] = nsError.code
        }

        payload.merge(sanitised(extras: extra)) { _, new in new }

        SentrySDK.capture(error: error) { scope in
            scope.setLevel(level.sentryLevel)
            scope.setExtras(payload)
            scope.setTag(value: level.rawValue, key: "telemetry.level")
            scope.setExtra(value: formattedMessage, key: "telemetry.message")
        }

        logToConsole(level: level, message: formattedMessage + " - error: \(error)")
    }
}

private extension TelemetryService {
    static func format(
        message: String,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) -> String {
        "\(message) [\(file):\(line) \(function)]"
    }

    static func baseExtras(
        file: StaticString,
        function: StaticString,
        line: UInt
    ) -> [String: Any] {
        [
            "source.file": String(describing: file),
            "source.function": String(describing: function),
            "source.line": Int(line)
        ]
    }

    static func sanitised(extras: [String: Any]) -> [String: Any] {
        extras.reduce(into: [String: Any]()) { partialResult, entry in
            switch entry.value {
            case let value as String:
                partialResult[entry.key] = value
            case let value as Int:
                partialResult[entry.key] = value
            case let value as Double:
                partialResult[entry.key] = value
            case let value as Float:
                partialResult[entry.key] = value
            case let value as Bool:
                partialResult[entry.key] = value
            case let value as CustomStringConvertible:
                partialResult[entry.key] = value.description
            default:
                partialResult[entry.key] = String(describing: entry.value)
            }
        }
    }

    static func logToConsole(level: TelemetryLevel, message: String) {
        print("\(level.consolePrefix) Telemetry - \(message)")
    }
}
