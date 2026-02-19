//
//  RevenueCatService.swift
//  WhiteNoise
//
//  Centralizes RevenueCat configuration using Info.plist values.
//

import Foundation

#if os(iOS)
import RevenueCat
#endif

@MainActor
enum RevenueCatService {
    /// Whether RevenueCat was successfully configured
    static private(set) var isConfigured = false

    static func configure() {
        #if os(iOS)
        guard let rawKey = Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_API_KEY") as? String else {
            print("⚠️ RevenueCatService.configure - Missing REVENUECAT_API_KEY (Info.plist)")
            TelemetryService.captureNonFatal(
                message: "RevenueCatService.configure - Missing API key",
                level: .error
            )
            return
        }

        let key = rawKey.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !key.isEmpty else {
            print("⚠️ RevenueCatService.configure - Empty REVENUECAT_API_KEY (Info.plist)")
            TelemetryService.captureNonFatal(
                message: "RevenueCatService.configure - Empty API key",
                level: .error
            )
            return
        }

        // Validate key format (should be appl_xxxxxxxxxxxxxxxxxxxxxxx)
        guard key.hasPrefix("appl_"), !key.contains("your_"), !key.contains("placeholder") else {
            print("⚠️ RevenueCatService.configure - Invalid API key format")
            TelemetryService.captureNonFatal(
                message: "RevenueCatService.configure - Invalid API key format",
                level: .error,
                extra: ["keyPrefix": String(key.prefix(10))]
            )
            return
        }

        print("🎯 RevenueCatService.configure - Configuring RevenueCat SDK")

        let logLevelString = Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_LOG_LEVEL") as? String

        #if DEBUG
        let defaultLogLevel: LogLevel = .debug
        #else
        let defaultLogLevel: LogLevel = .info
        #endif

        let resolvedLogLevel: LogLevel = {
            switch logLevelString?.lowercased() {
            case "verbose": return .verbose
            case "debug": return .debug
            case "info": return .info
            case "warn", "warning": return .warn
            case "error": return .error
            default: return defaultLogLevel
            }
        }()

        Purchases.logLevel = resolvedLogLevel

        let configuration = Configuration.Builder(withAPIKey: key)
            .with(storeKitVersion: .storeKit2)
            .build()

        Purchases.configure(with: configuration)
        isConfigured = true
        print("✅ RevenueCatService.configure - RevenueCat configured")
        #endif
    }
}
