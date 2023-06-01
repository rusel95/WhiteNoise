//
//  ContentView.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 30.05.2023.
//

import SwiftUI

struct ContentView: View {

    @ObservedObject var viewModel = WhiteNoisesViewModel()

    var body: some View {
        NavigationView {
            WhiteNoisesView(viewModel: WhiteNoisesViewModel())
                .background(Color.black.opacity(0.9))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
