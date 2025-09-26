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

enum RevenueCatService {
    static func configure() {
        #if os(iOS)
        guard let key = Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_API_KEY") as? String,
              !key.isEmpty else {
            print("⚠️ RevenueCatService.configure - Missing REVENUECAT_API_KEY (Info.plist)")
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
        print("✅ RevenueCatService.configure - RevenueCat configured")
        #endif
    }
}
