//
//  AdaptyService.swift
//  WhiteNoise
//
//  Centralizes Adapty activation using environment or Info.plist value.
//

import Foundation

#if os(iOS)
import Adapty
import AdaptyUI
#endif

enum AdaptyService {
    static func activate() {
        #if os(iOS)
        let envKey = ProcessInfo.processInfo.environment["ADAPTY_API_KEY"]
        let plistKey = Bundle.main.object(forInfoDictionaryKey: "ADAPTY_API_KEY") as? String
        let apiKey = (envKey?.isEmpty == false ? envKey : nil) ?? (plistKey?.isEmpty == false ? plistKey : nil)

        guard let key = apiKey, !key.isEmpty else {
            print("⚠️ AdaptyService.activate - Missing ADAPTY_API_KEY (env or Info.plist)")
            return
        }

        print("🎯 AdaptyService.activate - Activating Adapty SDK")
        let configuration = AdaptyConfiguration
            .builder(withAPIKey: key)
            .build()

        Adapty.activate(with: configuration)
        print("✅ AdaptyService.activate - Adapty activated")

        Task {
            do {
                try await AdaptyUI.activate()
                print("✅ AdaptyService.activate - AdaptyUI activated")
            } catch {
                print("⚠️ AdaptyService.activate - Failed to activate AdaptyUI: \(error)")
            }
        }
        #endif
    }
}
