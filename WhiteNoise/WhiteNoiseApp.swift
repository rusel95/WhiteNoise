//
//  WhiteNoiseApp.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 30.05.2023.
//

import SwiftUI

@main
struct WhiteNoiseApp: App {
    
    init() {
        // Initialize Sentry for error tracking
        SentryManager.initialize()
        
        // Log app launch
        SentryManager.addBreadcrumb("App Launched", 
                                   category: "app_lifecycle",
                                   data: ["version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"])
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    SentryManager.addBreadcrumb("Main View Appeared", category: "navigation")
                }
        }
    }
}
