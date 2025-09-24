//
//  RevenueCatService.swift
//  WhiteNoise
//
//  Centralizes RevenueCat configuration using environment or Info.plist value.
//

import Foundation

#if os(iOS)
import RevenueCat
#endif

enum RevenueCatService {
    static func configure() {
        #if os(iOS)
        let envKey = ProcessInfo.processInfo.environment["REVENUECAT_API_KEY"]
        let plistKey = Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_API_KEY") as? String
        let apiKey = (envKey?.isEmpty == false ? envKey : nil) ?? (plistKey?.isEmpty == false ? plistKey : nil)

        guard let key = apiKey, !key.isEmpty else {
            print("⚠️ RevenueCatService.configure - Missing REVENUECAT_API_KEY (env or Info.plist)")
            return
        }

        print("🎯 RevenueCatService.configure - Configuring RevenueCat SDK")
        let configuration = Configuration.Builder(withAPIKey: key)
            .with(storeKitVersion: .storeKit2)
            .build()

        Purchases.configure(with: configuration)
        print("✅ RevenueCatService.configure - RevenueCat configured")
        #endif
    }
}
