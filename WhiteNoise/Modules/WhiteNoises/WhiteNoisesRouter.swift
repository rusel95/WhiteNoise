//
//  WhiteNoisesRouter.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 2025-08-14.
//

import SwiftUI

@MainActor
final class WhiteNoisesRouter: WhiteNoisesRouterProtocol {
    
    // MARK: - Properties
    
    weak var viewController: WhiteNoisesViewProtocol?
    
    // MARK: - WhiteNoisesRouterProtocol
    
    func navigateToSettings() {
        // Navigation to settings screen would be implemented here
        // For now, this is a placeholder
        print("Navigate to settings")
    }
    
    func presentTimerPicker(currentMode: TimerService.TimerMode, completion: @escaping (TimerService.TimerMode) -> Void) {
        // In a real implementation, this would present a timer picker
        // For now, we'll use the existing TimerPickerView
        print("Present timer picker with current mode: \(currentMode)")
        
        // The view will handle the presentation
    }
    
    func presentSoundVariantPicker(for sound: Sound, completion: @escaping (Sound.SoundVariant) -> Void) {
        // In a real implementation, this would present a sound variant picker
        // For now, we'll use the existing SoundVariantPickerView
        print("Present sound variant picker for: \(sound.name)")
        
        // The view will handle the presentation
    }
}