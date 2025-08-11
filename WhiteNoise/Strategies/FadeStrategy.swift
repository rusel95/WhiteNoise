//
//  FadeStrategy.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 2025-08-11.
//

import Foundation

// MARK: - Strategy Protocol

protocol FadeStrategy {
    func calculateVolume(at progress: Double, from startVolume: Float, to endVolume: Float) -> Float
}

// MARK: - Concrete Strategies

struct LinearFadeStrategy: FadeStrategy {
    func calculateVolume(at progress: Double, from startVolume: Float, to endVolume: Float) -> Float {
        let volumeDelta = endVolume - startVolume
        return startVolume + (volumeDelta * Float(progress))
    }
}

struct ExponentialFadeStrategy: FadeStrategy {
    private let exponent: Double = 2.0
    
    func calculateVolume(at progress: Double, from startVolume: Float, to endVolume: Float) -> Float {
        let volumeDelta = endVolume - startVolume
        let exponentialProgress = pow(progress, exponent)
        return startVolume + (volumeDelta * Float(exponentialProgress))
    }
}

struct LogarithmicFadeStrategy: FadeStrategy {
    func calculateVolume(at progress: Double, from startVolume: Float, to endVolume: Float) -> Float {
        let volumeDelta = endVolume - startVolume
        let logarithmicProgress = log10(1 + 9 * progress)
        return startVolume + (volumeDelta * Float(logarithmicProgress))
    }
}

struct SCurveFadeStrategy: FadeStrategy {
    func calculateVolume(at progress: Double, from startVolume: Float, to endVolume: Float) -> Float {
        let volumeDelta = endVolume - startVolume
        let sCurveProgress = progress * progress * (3 - 2 * progress)
        return startVolume + (volumeDelta * Float(sCurveProgress))
    }
}

// MARK: - Fade Type Enum

enum FadeType {
    case linear
    case exponential
    case logarithmic
    case sCurve
    
    var strategy: FadeStrategy {
        switch self {
        case .linear:
            return LinearFadeStrategy()
        case .exponential:
            return ExponentialFadeStrategy()
        case .logarithmic:
            return LogarithmicFadeStrategy()
        case .sCurve:
            return SCurveFadeStrategy()
        }
    }
}

// MARK: - Fade Context

final class FadeContext {
    private let strategy: FadeStrategy
    
    init(fadeType: FadeType = .linear) {
        self.strategy = fadeType.strategy
    }
    
    func calculateVolume(at progress: Double, from startVolume: Float, to endVolume: Float) -> Float {
        strategy.calculateVolume(at: progress, from: startVolume, to: endVolume)
    }
}