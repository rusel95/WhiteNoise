//
//  AppError.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 2025-08-17.
//

import Foundation

enum AppError: LocalizedError {
    case audioSessionFailure(String)
    case fileNotFound(String)
    case playbackFailure(String)
    case invalidSoundConfiguration(String)
    case soundCreationFailure(String)
    case persistenceFailure(String)
    case timerConfigurationError(String)
    case networkError(String)
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .audioSessionFailure(let details):
            return "Failed to configure audio session: \(details)"
        case .fileNotFound(let file):
            return "Audio file not found: \(file)"
        case .playbackFailure(let reason):
            return "Playback failed: \(reason)"
        case .invalidSoundConfiguration(let reason):
            return "Invalid sound configuration: \(reason)"
        case .soundCreationFailure(let reason):
            return "Failed to create sound: \(reason)"
        case .persistenceFailure(let reason):
            return "Failed to save/load data: \(reason)"
        case .timerConfigurationError(let reason):
            return "Timer configuration error: \(reason)"
        case .networkError(let reason):
            return "Network error: \(reason)"
        case .unknown(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .audioSessionFailure:
            return "Please check your device's audio settings and try again."
        case .fileNotFound:
            return "The audio file may be missing. Try reinstalling the app."
        case .playbackFailure:
            return "Try pausing and playing again, or restart the app."
        case .invalidSoundConfiguration:
            return "The sound configuration is invalid. Try resetting to defaults."
        case .soundCreationFailure:
            return "Unable to create sound. Check if the app has necessary permissions."
        case .persistenceFailure:
            return "Check device storage space and app permissions."
        case .timerConfigurationError:
            return "Try setting the timer again with a valid duration."
        case .networkError:
            return "Check your internet connection and try again."
        case .unknown:
            return "Try restarting the app. If the problem persists, contact support."
        }
    }
    
    var isRecoverable: Bool {
        switch self {
        case .fileNotFound, .invalidSoundConfiguration:
            return false
        default:
            return true
        }
    }
}

// MARK: - Result Extensions for Error Handling

extension Result where Failure == AppError {
    @discardableResult
    func logIfFailed(context: String = "") -> Self {
        if case .failure(let error) = self {
            print("❌ Error\(context.isEmpty ? "" : " in \(context)"): \(error.localizedDescription)")
            if let suggestion = error.recoverySuggestion {
                print("💡 Suggestion: \(suggestion)")
            }
        }
        return self
    }
}