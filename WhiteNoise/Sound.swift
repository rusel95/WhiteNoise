//
//  Sound.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 30.05.2023.
//

import AVFoundation

class Sound: ObservableObject, Identifiable {

    let id: UUID = UUID()
    let name: String
    let fileName: String
    var player: AVAudioPlayer?

    @Published var volume: Float = 0.3 {
        didSet {
            player?.volume = volume
        }
    }

    init(name: String, fileName: String) {
        self.name = name
        self.fileName = fileName

        guard let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") else {
            // TODO: - handle exception
            print("wrong")
            return
        }

        do {
            self.player = try AVAudioPlayer(contentsOf: url)
            self.player?.volume = self.volume
            self.player?.prepareToPlay()
            self.player?.numberOfLoops = -1 // to loop the sound
        } catch {
            // TODO: - handle exception
            print("Error loading audio file: \(error)")
        }
    }

    func playSound() {
        player?.play()
    }

    func stopSound() {
        player?.stop()
    }

}
