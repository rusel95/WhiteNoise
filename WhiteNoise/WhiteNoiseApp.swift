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
        AdaptyService.activate()
    }
 
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
