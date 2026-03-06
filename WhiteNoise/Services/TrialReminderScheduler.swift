//
//  TrialReminderScheduler.swift
//  WhiteNoise
//
//  Schedules a local notification to remind users one day before
//  their introductory trial expires.
//

import Foundation
import UserNotifications

import RevenueCat

@MainActor
final class TrialReminderScheduler {
    private let notificationCenter = UNUserNotificationCenter.current()
    private let defaults = UserDefaults.standard
    private let reminderIdentifier = "whitenoise_trial_reminder"
    private let scheduledDateKey = "trialReminderScheduledDate"

    /// Preferred hour (local time) to deliver the reminder notification.
    private let preferredDeliveryHour = 10

    func scheduleReminderIfNeeded(for entitlement: EntitlementInfo) {
        guard let reminderDate = reminderDate(for: entitlement) else {
            cancelReminder()
            return
        }

        guard !isReminderScheduled(for: reminderDate) else { return }

        let identifier = reminderIdentifier
        Task { [weak self] in
            guard let self else {
                TelemetryService.captureNonFatal(
                    message: "TrialReminderScheduler.getNotificationSettings lost self"
                )
                return
            }

            let settings = await self.notificationCenter.notificationSettings()
            let authStatus = settings.authorizationStatus

            switch authStatus {
            case .notDetermined:
                do {
                    let granted = try await self.notificationCenter.requestAuthorization(options: [.alert, .sound])
                    if granted {
                        self.createReminder(at: reminderDate)
                    } else {
                        TelemetryService.captureNonFatal(
                            message: "TrialReminderScheduler authorization not granted",
                            extra: ["identifier": identifier]
                        )
                    }
                } catch {
                    TelemetryService.captureNonFatal(
                        error: error,
                        message: "TrialReminderScheduler authorization request failed",
                        extra: ["identifier": identifier]
                    )
                }
            case .authorized, .provisional:
                self.createReminder(at: reminderDate)
            default:
                LoggingService.log("TrialReminderScheduler: notifications denied by user, skipping")
            }
        }
    }

    func ensureReminderScheduled(for entitlement: EntitlementInfo) {
        guard let reminderDate = reminderDate(for: entitlement) else {
            cancelReminder()
            return
        }

        if isReminderScheduled(for: reminderDate) {
            return
        }

        scheduleReminderIfNeeded(for: entitlement)
    }

    func cancelReminder() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [reminderIdentifier])
        defaults.removeObject(forKey: scheduledDateKey)
    }

    private func createReminder(at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Trial Ending Soon")
        content.body = String(localized: "Your WhiteNoise trial ends tomorrow. Subscribe now to keep your relaxing sounds playing.")
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: reminderIdentifier, content: content, trigger: trigger)

        let identifier = reminderIdentifier
        let dateKey = scheduledDateKey
        let notificationCenter = self.notificationCenter
        let defaults = self.defaults
        Task {
            do {
                try await notificationCenter.add(request)
                defaults.set(date, forKey: dateKey)
                LoggingService.log("TrialReminderScheduler: scheduled reminder for \(date)")
            } catch {
                TelemetryService.captureNonFatal(
                    error: error,
                    message: "TrialReminderScheduler failed to schedule reminder",
                    extra: [
                        "identifier": identifier,
                        "fireDate": date.description
                    ]
                )
            }
        }
    }

    /// Returns a date at `preferredDeliveryHour` (local time) on the day before the trial expires,
    /// or `nil` if the trial is not active or the reminder date has already passed.
    private func reminderDate(for entitlement: EntitlementInfo) -> Date? {
        guard entitlement.periodType == .trial,
              let expiresAt = entitlement.expirationDate else {
            return nil
        }

        let calendar = Calendar.current

        // Get the day before expiry
        guard let dayBefore = calendar.date(byAdding: .day, value: -1, to: expiresAt) else {
            return nil
        }

        // Schedule at preferredDeliveryHour on that day (local time)
        var components = calendar.dateComponents([.year, .month, .day], from: dayBefore)
        components.hour = preferredDeliveryHour
        components.minute = 0

        guard let reminderDate = calendar.date(from: components),
              reminderDate > Date() else {
            return nil
        }

        return reminderDate
    }

    private func isReminderScheduled(for date: Date) -> Bool {
        guard let storedDate = defaults.object(forKey: scheduledDateKey) as? Date else { return false }
        return abs(storedDate.timeIntervalSince(date)) < 60
    }
}
