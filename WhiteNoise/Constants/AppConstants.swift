//
//  AppConstants.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 2025-08-03.
//

import SwiftUI
#if os(iOS)
import UIKit
#endif

enum AppConstants {
    
    enum Animation {
        static let springDuration: Double = 1.0
        static let fadeStandard: Double = 2.0 // Standard fade for button presses
        static let fadeLong: Double = 3.0 // Remote commands, interruptions
        static let fadeOut: Double = 5.0 // Timer expiry fade out
        static let fadeSteps: Int = 50 // Updates per second for fade
        static let initialVolumeDuration: Double = 1.0
    }
    
    enum Audio {
        static let defaultVolume: Float = 0.0
        static let loopForever: Int = -1
        static let slowLoadThreshold: Double = 0.5 // seconds
        static let volumeThreshold: Float = 0.5 // threshold for volume check
    }
    
    enum UI {
        static var soundGridSpacing: CGFloat {
#if os(macOS)
            16
#else
            isPad ? 18 : 12
#endif
        }
        static let soundCardCornerRadius: CGFloat = 20
        static var bottomControllerPadding: CGFloat {
#if os(iOS)
            isPad ? 140 : 100
#else
            100
#endif
        }
        
        // Asset Catalog Colors - using Swift generated asset symbols
        static let primaryGradientStart = Color.primaryGradientStart
        static let primaryGradientEnd = Color.primaryGradientEnd
        static let secondaryGradientStart = Color.secondaryGradientStart
        static let secondaryGradientEnd = Color.secondaryGradientEnd
        static let glassEffectOpacity: Double = 0.05
        static let glassHighlightOpacity: Double = 0.1
        static let volumeSliderBackgroundOpacity: Double = 0.8
        
        // Sizes
        #if os(macOS)
        static let minSoundCardWidth: CGFloat = 150
        static let maxSoundCardWidth: CGFloat = 400
        static let controlButtonSize: CGFloat = 30
        #elseif os(iOS)
        static var minSoundCardWidth: CGFloat {
            isPad ? 220 : phoneMinSoundCardWidth
        }

        static var maxSoundCardWidth: CGFloat {
            isPad ? 400 : phoneMaxSoundCardWidth
        }

        static var controlButtonSize: CGFloat {
            isPad ? 100 : 50
        }

        static var controlButtonIconSize: CGFloat {
            isPad ? 40 : 20
        }

        static var soundIconSize: CGFloat {
            isPad ? 96 : 44
        }

        static var soundNameFontSize: CGFloat {
            isPad ? 40 : 20
        }

        static var soundCardIconSize: CGFloat {
            isPad ? 52 : 24
        }

        static var soundTitleFontSize: CGFloat {
            isPad ? 24 : 14
        }

        static var soundVariantFontSize: CGFloat {
            isPad ? 18 : 11
        }

        static var soundVariantChevronSize: CGFloat {
            isPad ? 14 : 8
        }

        static var soundVariantPaddingHorizontal: CGFloat {
            isPad ? 20 : 10
        }

        static var soundVariantPaddingVertical: CGFloat {
            isPad ? 10 : 4
        }

        static var soundVariantCornerRadius: CGFloat {
            isPad ? 14 : 8
        }

        static var controlContainerHorizontalPadding: CGFloat {
            isPad ? controlContainerVerticalPadding : 80
        }

        static var controlContainerVerticalPadding: CGFloat {
            isPad ? 16 : 12
        }

        static var controlStackSpacing: CGFloat {
            isPad ? 40 : 20
        }

        static var controlTrayCornerRadius: CGFloat {
            isPad ? 36 : 25
        }

        static var controlTrayMaxWidth: CGFloat {
            (controlButtonSize * 2) + controlStackSpacing
        }

        static var gridHorizontalPadding: CGFloat {
            isPad ? 44 : 16
        }

        static var controlTrayHorizontalInsets: CGFloat {
            isPad ? controlButtonSize * 1.8 : phoneControlTrayHorizontalInsets
        }

        static var controlTrayBottomPadding: CGFloat {
            isPad ? 40 : 20
        }

        static var controlButtonCornerRadius: CGFloat {
            isPad ? 32 : phoneControlButtonCornerRadius
        }

        static let phoneMinSoundCardWidth: CGFloat = 100
        static let phoneMaxSoundCardWidth: CGFloat = 200
        static let phoneControlContainerHorizontalPadding: CGFloat = 80
        static let phoneControlContainerVerticalPadding: CGFloat = 12
        static let phoneControlStackSpacing: CGFloat = 20
        static let phoneControlTrayCornerRadius: CGFloat = 25
        static let phoneControlTrayHorizontalInsets: CGFloat = phoneControlContainerVerticalPadding
        static let phoneControlTrayBottomPadding: CGFloat = 20
        static let phoneControlButtonCornerRadius: CGFloat = 16

        static var soundCardVerticalPadding: CGFloat {
            isPad ? 28 : 12
        }
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

#if os(iOS)
private extension AppConstants.UI {
    static var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
}
#endif

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
