//
//  View+Extensions.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 2025-08-03.
//

import SwiftUI

extension View {
    /// Applies a glass morphism effect to the view
    func glassMorphism(cornerRadius: CGFloat = AppConstants.UI.soundCardCornerRadius) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(LinearGradient.glassEffect)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.white.opacity(AppConstants.UI.glassEffectOpacity), lineWidth: 1)
                    )
            )
    }
    
    /// Applies primary gradient background
    func primaryGradientBackground(cornerRadius: CGFloat = 16) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(LinearGradient.primaryGradient)
            )
    }
    
    /// Applies secondary gradient background
    func secondaryGradientBackground(cornerRadius: CGFloat = 16) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(LinearGradient.secondaryGradient)
            )
    }
}