//
//  ContentView.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 30.05.2023.
//

import SwiftUI

struct ContentView: View {

    @State private var viewModel = WhiteNoisesViewModel.makeDefault()
    
    var body: some View {
        WhiteNoisesView(viewModel: viewModel)
            .task { await viewModel.bootstrap() }
    }
}

#Preview {
    ContentView()
}
