//
//  ContentView.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 30.05.2023.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel = SoundsViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    ForEach(viewModel.sounds) { sound in
                        SoundView(sound: sound)
                            .padding(.vertical)
                    }
                }
                .navigationTitle("Sounds")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
