//
//  SoundViewModel.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 30.05.2023.
//

import Combine
import Foundation
import AVFAudio

class SoundsViewModel: ObservableObject {
    
    @Published var sounds = [
        Sound(name: "Birds", fileName: "birds"),
        Sound(name: "Whitenoise", fileName: "whitenoise"),
        Sound(name: "Jungle", fileName: "jungle"),
        Sound(name: "Sea", fileName: "sea"),
        Sound(name: "Wind", fileName: "wind"),
        Sound(name: "Windstorm", fileName: "windstorm")
    ]

    init() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Setting category to AVAudioSessionCategoryPlayback failed.")
        }
    }
}
