//
//  SentryManager.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 2025-08-17.
//

import Foundation
import Sentry

/// Centralized manager for Sentry error tracking and logging
final class SentryManager {
    
    static let shared = SentryManager()
    
    private init() {}
    
    /// Initialize Sentry SDK with configuration from .sentryclirc
    static func initialize() {
        
        SentrySDK.start { options in
            // Set environment
            #if DEBUG
            options.environment = "development"
            #else
            options.environment = "production"
            #endif
            
            // Enable automatic breadcrumb tracking
            options.enableAutoBreadcrumbTracking = true
            
            // Enable automatic session tracking
            options.enableAutoSessionTracking = true
            
            // Set sample rate for performance monitoring
            options.tracesSampleRate = 1.0
            
            // Enable debug in development
            #if DEBUG
            options.debug = true
            #endif
            
            // Set release version
            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
               let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                options.releaseName = "\(version)-\(build)"
            }
        }
    }
    
    // MARK: - Error Logging
    
    /// Log an error to Sentry with additional context
    /// - Parameters:
    ///   - error: The error to log
    ///   - context: Additional context about where the error occurred
    ///   - userInfo: Additional user information
    static func logError(_ error: Error, 
                        context: String,
                        userInfo: [String: Any]? = nil,
                        level: SentryLevel = .error) {
        
        // Create event
        let event = Event(error: error)
        event.level = level
        
        // Add context
        event.context?["operation"] = ["description": context]
        
        // Add user info if provided
        if let userInfo = userInfo {
            event.context?["user_info"] = userInfo
        }
        
        // Add breadcrumb
        let breadcrumb = Breadcrumb()
        breadcrumb.level = level
        breadcrumb.category = "error"
        breadcrumb.message = "\(context): \(error.localizedDescription)"
        breadcrumb.data = userInfo
        SentrySDK.addBreadcrumb(breadcrumb)
        
        // Send to Sentry
        SentrySDK.capture(event: event)
        
        // Also log to console in debug
        #if DEBUG
        print("🔴 Sentry [\(level)]: \(context)")
        print("   Error: \(error)")
        if let userInfo = userInfo {
            print("   UserInfo: \(userInfo)")
        }
        #endif
    }
    
    /// Log an AppError specifically
    /// - Parameters:
    ///   - error: The AppError to log
    ///   - context: Additional context about where the error occurred
    static func logAppError(_ error: AppError, 
                           context: String,
                           userInfo: [String: Any]? = nil) {
        
        // Determine severity based on error type
        let level: SentryLevel = error.isRecoverable ? .warning : .error
        
        // Create enriched user info
        var enrichedInfo = userInfo ?? [:]
        enrichedInfo["error_type"] = String(describing: error)
        enrichedInfo["is_recoverable"] = error.isRecoverable
        if let suggestion = error.recoverySuggestion {
            enrichedInfo["recovery_suggestion"] = suggestion
        }
        
        logError(error, context: context, userInfo: enrichedInfo, level: level)
    }
    
    // MARK: - Message Logging
    
    /// Log a message to Sentry (not an error)
    /// - Parameters:
    ///   - message: The message to log
    ///   - level: The severity level
    ///   - extras: Additional data to attach
    static func logMessage(_ message: String,
                          level: SentryLevel = .info,
                          extras: [String: Any]? = nil) {
        
        let event = Event(level: level)
        event.message = SentryMessage(formatted: message)
        
        if let extras = extras {
            event.extra = extras
        }
        
        SentrySDK.capture(event: event)
        
        #if DEBUG
        print("📝 Sentry [\(level)]: \(message)")
        if let extras = extras {
            print("   Extras: \(extras)")
        }
        #endif
    }
    
    // MARK: - Breadcrumbs
    
    /// Add a breadcrumb for tracking user actions
    /// - Parameters:
    ///   - message: The breadcrumb message
    ///   - category: The category of the breadcrumb
    ///   - data: Additional data
    static func addBreadcrumb(_ message: String,
                             category: String,
                             data: [String: Any]? = nil) {
        
        let breadcrumb = Breadcrumb()
        breadcrumb.message = message
        breadcrumb.category = category
        breadcrumb.data = data
        breadcrumb.level = .info
        
        SentrySDK.addBreadcrumb(breadcrumb)
        
        #if DEBUG
        print("🍞 Breadcrumb [\(category)]: \(message)")
        #endif
    }
    
    // MARK: - User Context
    
    /// Set user information for error tracking
    /// - Parameter user: The user information
    static func setUser(id: String? = nil,
                       email: String? = nil,
                       username: String? = nil) {
        
        let user = User()
        user.userId = id
        user.email = email
        user.username = username
        
        SentrySDK.setUser(user)
    }
    
    /// Clear user information (e.g., on logout)
    static func clearUser() {
        SentrySDK.setUser(nil)
    }
    
    // MARK: - Performance Monitoring
    
    /// Start a transaction for performance monitoring
    /// - Parameters:
    ///   - name: The transaction name
    ///   - operation: The operation being performed
    /// - Returns: The transaction span
    @discardableResult
    static func startTransaction(name: String,
                                operation: String) -> Span? {
        let transaction = SentrySDK.startTransaction(
            name: name,
            operation: operation
        )
        
        #if DEBUG
        print("⏱ Transaction started: \(name) - \(operation)")
        #endif
        
        return transaction
    }
    
    // MARK: - Crash Reporting
    
    /// Manually report a crash (for critical errors)
    /// - Parameters:
    ///   - error: The critical error
    ///   - context: Context about the crash
    static func reportCrash(_ error: Error, context: String) {
        logError(error, context: "CRASH: \(context)", level: .fatal)
    }
}

// MARK: - Convenience Extensions

extension SentryManager {
    
    /// Log audio-related errors
    static func logAudioError(_ error: Error, operation: String) {
        logError(error, 
                context: "Audio Operation Failed",
                userInfo: ["operation": operation],
                level: .error)
    }
    
    /// Log persistence-related errors
    static func logPersistenceError(_ error: Error, operation: String) {
        logError(error,
                context: "Persistence Operation Failed",
                userInfo: ["operation": operation],
                level: .warning)
    }
    
    /// Log configuration errors
    static func logConfigurationError(_ error: Error, resource: String) {
        logError(error,
                context: "Configuration Loading Failed",
                userInfo: ["resource": resource],
                level: .error)
    }
    
    /// Log sound creation errors
    static func logSoundCreationError(_ error: Error, soundName: String) {
        logError(error,
                context: "Sound Creation Failed",
                userInfo: ["sound_name": soundName],
                level: .error)
    }
    
    /// Log timer-related errors
    static func logTimerError(_ error: Error, mode: String) {
        logError(error,
                context: "Timer Operation Failed",
                userInfo: ["timer_mode": mode],
                level: .warning)
    }
    
    /// Log VIPER architecture errors
    static func logArchitectureError(_ error: Error, module: String, action: String) {
        logError(error,
                context: "VIPER Architecture Error",
                userInfo: ["module": module, "action": action],
                level: .error)
    }
}
