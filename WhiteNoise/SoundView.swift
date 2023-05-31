//
//  SoundView.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 30.05.2023.
//

import SwiftUI

struct SoundView: View {

    @ObservedObject var sound: Sound

    @State private var isPlaying = false

    var body: some View {
        VStack {
            #if os(tvOS)
            Text(sound.name)
                .font(.headline)
            HStack {
                Button(action: {
                    sound.volume = max(sound.volume - 0.1, 0)
                }) {
                    Text("-")
                }
                Text("Volume: \(Int(sound.volume * 100))")
                Button(action: {
                    sound.volume = min(sound.volume + 0.1, 1)
                }) {
                    Text("+")
                }
            }
            Button(action: {
                if isPlaying {
                    sound.stopSound()
                } else {
                    sound.playSound()
                }
                isPlaying.toggle()
            }) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
            }
            #else
            Text(sound.name)
                .font(.headline)
            Slider(value: $sound.volume, in: 0...1)
                .padding(.horizontal)
            #endif
        }
    }
    
}

