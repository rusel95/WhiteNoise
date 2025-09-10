//
//  AppConstants.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 2025-08-03.
//

import SwiftUI

enum AppConstants {
    
    enum Animation {
        static let springDuration: Double = 1.0
        static let fadeStandard: Double = 2.0 // Standard fade for button presses
        static let fadeLong: Double = 3.0 // Remote commands, interruptions
        static let fadeOut: Double = 5.0 // Timer expiry fade out
        static let fadeSteps: Int = 50 // Updates per second for fade
    }
    
    enum Audio {
        static let defaultVolume: Float = 0.0
        static let loopForever: Int = -1
        static let slowLoadThreshold: Double = 0.5 // seconds
        static let volumeThreshold: Float = 0.5 // threshold for volume check
    }
    
    enum UI {
        static let soundGridSpacing: CGFloat = 16
        static let soundCardCornerRadius: CGFloat = 20
        static let bottomControllerPadding: CGFloat = 100
        
        // Colors
        static let primaryGradientStart = Color(red: 0.2, green: 0.5, blue: 0.6)
        static let primaryGradientEnd = Color(red: 0.1, green: 0.4, blue: 0.5)
        static let secondaryGradientStart = Color(red: 0.1, green: 0.4, blue: 0.5)
        static let secondaryGradientEnd = Color(red: 0.05, green: 0.3, blue: 0.4)
        static let glassEffectOpacity: Double = 0.05
        static let glassHighlightOpacity: Double = 0.1
        static let volumeSliderBackgroundOpacity: Double = 0.8
        
        // Sizes
        #if os(macOS)
        static let minSoundCardWidth: CGFloat = 150
        static let maxSoundCardWidth: CGFloat = 400
        static let controlButtonSize: CGFloat = 30
        #elseif os(iOS)
        static let minSoundCardWidth: CGFloat = 100
        static let maxSoundCardWidth: CGFloat = 200
        static let controlButtonSize: CGFloat = 50
        static let controlButtonIconSize: CGFloat = 20
        static let soundIconSize: CGFloat = 44
        static let soundNameFontSize: CGFloat = 20
        static let soundCardIconSize: CGFloat = 24
        static let soundTitleFontSize: CGFloat = 14
        static let soundVariantFontSize: CGFloat = 11
        static let soundVariantChevronSize: CGFloat = 8
        static let soundVariantPaddingHorizontal: CGFloat = 10
        static let soundVariantPaddingVertical: CGFloat = 4
        static let soundVariantCornerRadius: CGFloat = 8
        #endif
    }
    
    enum Timer {
        static let updateInterval: UInt64 = 1_000_000_000 // 1 second in nanoseconds
        static let nowPlayingUpdateInterval: Int = 10 // seconds
    }
    
    enum UserDefaults {
        static let soundPrefix = "sound_"
    }
}

// MARK: - Gradient Extensions
extension LinearGradient {
    static var primaryGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                AppConstants.UI.primaryGradientStart,
                AppConstants.UI.primaryGradientEnd
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static var secondaryGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                AppConstants.UI.secondaryGradientStart,
                AppConstants.UI.secondaryGradientEnd
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static var glassEffect: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.white.opacity(AppConstants.UI.glassHighlightOpacity),
                Color.white.opacity(AppConstants.UI.glassEffectOpacity)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
