//
//  ContentView.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 30.05.2023.
//

import SwiftUI

struct ContentView: View {

    @State private var viewModel = WhiteNoisesViewModel.makeDefault()
    @Environment(EntitlementsCoordinator.self) private var entitlements

    var body: some View {
        WhiteNoisesView(viewModel: viewModel)
            .task { await viewModel.bootstrap() }
            .onDisappear { viewModel.cleanup() }
            .onChange(of: viewModel.isPlaying) { _, isPlaying in
                entitlements.engagementService.reportPlaybackActive(isPlaying)
            }
    }
}

#Preview {
    ContentView()
}
