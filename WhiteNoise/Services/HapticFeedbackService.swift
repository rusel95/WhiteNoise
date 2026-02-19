//
//  HapticFeedbackService.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 06.08.2025.
//

import Foundation
#if os(iOS)
import UIKit
#endif

@MainActor
protocol HapticFeedbackServiceProtocol: Sendable {
    func impact(style: HapticFeedbackStyle)
    func notification(type: HapticNotificationType)
    func selection()
}

enum HapticFeedbackStyle: Sendable {
    case light
    case medium
    case heavy
    case soft
    case rigid
}

enum HapticNotificationType: Sendable {
    case success
    case warning
    case error
}

@MainActor
final class HapticFeedbackService: HapticFeedbackServiceProtocol {

    static let shared = HapticFeedbackService()
    
    private init() {}
    
    func impact(style: HapticFeedbackStyle) {
        #if os(iOS)
        let impactStyle: UIImpactFeedbackGenerator.FeedbackStyle
        
        switch style {
        case .light:
            impactStyle = .light
        case .medium:
            impactStyle = .medium
        case .heavy:
            impactStyle = .heavy
        case .soft:
            if #available(iOS 13.0, *) {
                impactStyle = .soft
            } else {
                impactStyle = .light
            }
        case .rigid:
            if #available(iOS 13.0, *) {
                impactStyle = .rigid
            } else {
                impactStyle = .heavy
            }
        }
        
        let generator = UIImpactFeedbackGenerator(style: impactStyle)
        generator.prepare()
        generator.impactOccurred()
        #endif
    }
    
    func notification(type: HapticNotificationType) {
        #if os(iOS)
        let notificationType: UINotificationFeedbackGenerator.FeedbackType
        
        switch type {
        case .success:
            notificationType = .success
        case .warning:
            notificationType = .warning
        case .error:
            notificationType = .error
        }
        
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(notificationType)
        #endif
    }
    
    func selection() {
        #if os(iOS)
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
        #endif
    }
}