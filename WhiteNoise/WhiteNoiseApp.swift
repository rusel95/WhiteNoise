//
//  WhiteNoiseApp.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 30.05.2023.
//

import SwiftUI
import Sentry

@main
struct WhiteNoiseApp: App {
    init() {
        SentrySDK.start { options in
            options.dsn = "https://5123cbe3bc6f831ea8b851829c10b5f2@o1271632.ingest.us.sentry.io/4509872613294080"
            options.debug = false // Enabled debug when first installing is always helpful

            // Adds IP for users.
            // For more information, visit: https://docs.sentry.io/platforms/apple/data-management/data-collected/
            options.sendDefaultPii = true

            // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
            // We recommend adjusting this value in production.
            options.tracesSampleRate = 1.0

            // Configure profiling. Visit https://docs.sentry.io/platforms/apple/profiling/ to learn more.
            options.configureProfiling = {
                $0.sessionSampleRate = 1.0 // We recommend adjusting this value in production.
                $0.lifecycle = .trace
            }

            // Uncomment the following lines to add more data to your events
            // options.attachScreenshot = true // This adds a screenshot to the error events
            // options.attachViewHierarchy = true // This adds the view hierarchy to the error events
            
            // Enable experimental logging features
            options.experimental.enableLogs = true
        }
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
