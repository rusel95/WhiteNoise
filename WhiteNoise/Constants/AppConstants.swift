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
        static let initialVolumeDuration: Double = 1.0
    }

    enum Audio {
        static let defaultVolume: Float = 0.0
        static let loopForever: Int = -1
        static let slowLoadThreshold: Double = 0.5 // seconds
        static let volumeThreshold: Float = 0.5 // threshold for volume check
    }

    enum UI {
        // Shared constants (same for all sizes)
        static let soundCardCornerRadius: CGFloat = 20

        // Asset Catalog Colors - using Swift generated asset symbols
        static let primaryGradientStart = Color.primaryGradientStart
        static let primaryGradientEnd = Color.primaryGradientEnd
        static let secondaryGradientStart = Color.secondaryGradientStart
        static let secondaryGradientEnd = Color.secondaryGradientEnd
        static let glassEffectOpacity: Double = 0.05
        static let glassHighlightOpacity: Double = 0.1
        static let volumeSliderBackgroundOpacity: Double = 0.8

        // Size-specific constants for compact (iPhone) layouts
        enum Compact {
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
            static let controlContainerHorizontalPadding: CGFloat = 80
            static let controlContainerVerticalPadding: CGFloat = 12
            static let controlStackSpacing: CGFloat = 20
            static let controlTrayCornerRadius: CGFloat = 25
            static let controlTrayHorizontalInsets: CGFloat = 12
            static let controlTrayBottomPadding: CGFloat = 20
            static let controlButtonCornerRadius: CGFloat = 16
            static let soundCardVerticalPadding: CGFloat = 12
            static let soundGridSpacing: CGFloat = 12
            static let gridHorizontalPadding: CGFloat = 16
            static let bottomControllerPadding: CGFloat = 100
            static let gridBottomExtraPadding: CGFloat = 20
            static let timeLabelFontSize: CGFloat = 9
        }

        // Size-specific constants for regular (iPad) layouts
        enum Regular {
            static let minSoundCardWidth: CGFloat = 220
            static let maxSoundCardWidth: CGFloat = 400
            static let controlButtonSize: CGFloat = 100
            static let controlButtonIconSize: CGFloat = 40
            static let soundIconSize: CGFloat = 96
            static let soundNameFontSize: CGFloat = 40
            static let soundCardIconSize: CGFloat = 52
            static let soundTitleFontSize: CGFloat = 24
            static let soundVariantFontSize: CGFloat = 18
            static let soundVariantChevronSize: CGFloat = 14
            static let soundVariantPaddingHorizontal: CGFloat = 20
            static let soundVariantPaddingVertical: CGFloat = 10
            static let soundVariantCornerRadius: CGFloat = 14
            static let controlContainerHorizontalPadding: CGFloat = 16
            static let controlContainerVerticalPadding: CGFloat = 16
            static let controlStackSpacing: CGFloat = 40
            static let controlTrayCornerRadius: CGFloat = 36
            static let controlTrayHorizontalInsets: CGFloat = 180
            static let controlTrayBottomPadding: CGFloat = 40
            static let controlButtonCornerRadius: CGFloat = 32
            static let soundCardVerticalPadding: CGFloat = 28
            static let soundGridSpacing: CGFloat = 18
            static let gridHorizontalPadding: CGFloat = 44
            static let bottomControllerPadding: CGFloat = 140
            static let gridBottomExtraPadding: CGFloat = 30
            static let timeLabelFontSize: CGFloat = 14
        }
    }

    enum Timer {
        static let updateInterval: UInt64 = 1_000_000_000 // 1 second in nanoseconds
        static let nowPlayingUpdateInterval: Int = 10 // seconds
    }

    enum UserDefaults {
        static let soundPrefix = "sound_"
    }
}

// MARK: - Adaptive Layout Helper

/// Provides size-class-aware UI constants without requiring @MainActor
struct AdaptiveLayout {
    let isRegular: Bool

    init(horizontalSizeClass: UserInterfaceSizeClass?) {
        self.isRegular = horizontalSizeClass == .regular
    }

    // MARK: - Adaptive Properties

    var minSoundCardWidth: CGFloat {
        isRegular ? AppConstants.UI.Regular.minSoundCardWidth : AppConstants.UI.Compact.minSoundCardWidth
    }

    var maxSoundCardWidth: CGFloat {
        isRegular ? AppConstants.UI.Regular.maxSoundCardWidth : AppConstants.UI.Compact.maxSoundCardWidth
    }

    var controlButtonSize: CGFloat {
        isRegular ? AppConstants.UI.Regular.controlButtonSize : AppConstants.UI.Compact.controlButtonSize
    }

    var controlButtonIconSize: CGFloat {
        isRegular ? AppConstants.UI.Regular.controlButtonIconSize : AppConstants.UI.Compact.controlButtonIconSize
    }

    var soundIconSize: CGFloat {
        isRegular ? AppConstants.UI.Regular.soundIconSize : AppConstants.UI.Compact.soundIconSize
    }

    var soundNameFontSize: CGFloat {
        isRegular ? AppConstants.UI.Regular.soundNameFontSize : AppConstants.UI.Compact.soundNameFontSize
    }

    var soundCardIconSize: CGFloat {
        isRegular ? AppConstants.UI.Regular.soundCardIconSize : AppConstants.UI.Compact.soundCardIconSize
    }

    var soundTitleFontSize: CGFloat {
        isRegular ? AppConstants.UI.Regular.soundTitleFontSize : AppConstants.UI.Compact.soundTitleFontSize
    }

    var soundVariantFontSize: CGFloat {
        isRegular ? AppConstants.UI.Regular.soundVariantFontSize : AppConstants.UI.Compact.soundVariantFontSize
    }

    var soundVariantChevronSize: CGFloat {
        isRegular ? AppConstants.UI.Regular.soundVariantChevronSize : AppConstants.UI.Compact.soundVariantChevronSize
    }

    var soundVariantPaddingHorizontal: CGFloat {
        isRegular ? AppConstants.UI.Regular.soundVariantPaddingHorizontal : AppConstants.UI.Compact.soundVariantPaddingHorizontal
    }

    var soundVariantPaddingVertical: CGFloat {
        isRegular ? AppConstants.UI.Regular.soundVariantPaddingVertical : AppConstants.UI.Compact.soundVariantPaddingVertical
    }

    var soundVariantCornerRadius: CGFloat {
        isRegular ? AppConstants.UI.Regular.soundVariantCornerRadius : AppConstants.UI.Compact.soundVariantCornerRadius
    }

    var controlContainerHorizontalPadding: CGFloat {
        isRegular ? AppConstants.UI.Regular.controlContainerHorizontalPadding : AppConstants.UI.Compact.controlContainerHorizontalPadding
    }

    var controlContainerVerticalPadding: CGFloat {
        isRegular ? AppConstants.UI.Regular.controlContainerVerticalPadding : AppConstants.UI.Compact.controlContainerVerticalPadding
    }

    var controlStackSpacing: CGFloat {
        isRegular ? AppConstants.UI.Regular.controlStackSpacing : AppConstants.UI.Compact.controlStackSpacing
    }

    var controlTrayCornerRadius: CGFloat {
        isRegular ? AppConstants.UI.Regular.controlTrayCornerRadius : AppConstants.UI.Compact.controlTrayCornerRadius
    }

    var controlTrayHorizontalInsets: CGFloat {
        isRegular ? AppConstants.UI.Regular.controlTrayHorizontalInsets : AppConstants.UI.Compact.controlTrayHorizontalInsets
    }

    var controlTrayBottomPadding: CGFloat {
        isRegular ? AppConstants.UI.Regular.controlTrayBottomPadding : AppConstants.UI.Compact.controlTrayBottomPadding
    }

    var controlButtonCornerRadius: CGFloat {
        isRegular ? AppConstants.UI.Regular.controlButtonCornerRadius : AppConstants.UI.Compact.controlButtonCornerRadius
    }

    var soundCardVerticalPadding: CGFloat {
        isRegular ? AppConstants.UI.Regular.soundCardVerticalPadding : AppConstants.UI.Compact.soundCardVerticalPadding
    }

    var soundGridSpacing: CGFloat {
        isRegular ? AppConstants.UI.Regular.soundGridSpacing : AppConstants.UI.Compact.soundGridSpacing
    }

    var gridHorizontalPadding: CGFloat {
        isRegular ? AppConstants.UI.Regular.gridHorizontalPadding : AppConstants.UI.Compact.gridHorizontalPadding
    }

    var bottomControllerPadding: CGFloat {
        isRegular ? AppConstants.UI.Regular.bottomControllerPadding : AppConstants.UI.Compact.bottomControllerPadding
    }

    var gridBottomExtraPadding: CGFloat {
        isRegular ? AppConstants.UI.Regular.gridBottomExtraPadding : AppConstants.UI.Compact.gridBottomExtraPadding
    }

    var controlTrayMaxWidth: CGFloat {
        (controlButtonSize * 2) + controlStackSpacing
    }

    var timeLabelFont: Font {
        .system(size: isRegular ? AppConstants.UI.Regular.timeLabelFontSize : AppConstants.UI.Compact.timeLabelFontSize, weight: .medium)
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
                Color.primary.opacity(AppConstants.UI.glassHighlightOpacity),
                Color.primary.opacity(AppConstants.UI.glassEffectOpacity)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
