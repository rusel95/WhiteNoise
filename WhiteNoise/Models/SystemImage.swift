//
//  SystemImage.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 2025-10-21.
//
//  Type-safe wrapper for SF Symbols used throughout the app.
//  This provides autocomplete and compile-time checking for system image names.
//

import Foundation

/// Enum representing all SF Symbols used in the WhiteNoise app
/// Provides type-safe access to SF Symbol names with IDE autocomplete
enum SystemImage: String, CaseIterable {
    // Sounds
    case cloudRain = "cloud.rain"
    case flame
    case tree
    case waveformPath = "waveform.path"
    case waterWaves = "water.waves"
    case cloudBolt = "cloud.bolt"
    case bird
    case fireplace

    // Playback Controls
    case pauseFill = "pause.fill"
    case play
    case playFill = "play.fill"
    case pause

    // Navigation & UI
    case timer
    case chevronDown = "chevron.down"
    case xMark = "xmark"
    case gearshape
    case ellipsis

    /// The SF Symbol name as used by Image(systemName:)
    var systemName: String {
        self.rawValue
    }
}

// MARK: - SwiftUI Extensions

import SwiftUI

extension Image {
    /// Creates an Image using a type-safe SystemImage
    /// Example: Image(system: .cloudRain)
    init(system: SystemImage) {
        self.init(systemName: system.systemName)
    }
}

#if os(iOS)
import UIKit

extension UIImage {
    /// Creates a UIImage using a type-safe SystemImage
    /// Example: UIImage(system: .cloudRain)
    convenience init?(system: SystemImage) {
        self.init(systemName: system.systemName)
    }
}
#endif
