//
//  VolumeView.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 02.08.2024.
//

import SwiftUI
import MediaPlayer

struct VolumeView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let volumeView = MPVolumeView(frame: .zero)
//        volumeView.showsVolumeSlider(true)
        view.addSubview(volumeView)

        // Constraints to ensure the volume view fits its container
        volumeView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            volumeView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            volumeView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            volumeView.topAnchor.constraint(equalTo: view.topAnchor),
            volumeView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // No update logic needed for static MPVolumeView
    }
}

#Preview {
    VolumeView()
}
