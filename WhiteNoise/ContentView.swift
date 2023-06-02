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
        WhiteNoisesView(viewModel: WhiteNoisesViewModel())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
