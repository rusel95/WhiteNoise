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

final class TrialReminderScheduler {
    private let notificationCenter = UNUserNotificationCenter.current()
    private let defaults = UserDefaults.standard
    private let reminderIdentifier = "whitenoise_trial_reminder"
    private let scheduledDateKey = "trialReminderScheduledDate"

    func scheduleReminderIfNeeded(for entitlement: EntitlementInfo) {
        guard let reminderDate = reminderDate(for: entitlement) else {
            cancelReminder()
            return
        }

        guard !isReminderScheduled(for: reminderDate) else { return }

        notificationCenter.getNotificationSettings { [weak self] settings in
            guard let self = self else {
                TelemetryService.captureNonFatal(
                    message: "TrialReminderScheduler.getNotificationSettings lost self"
                )
                return
            }

            switch settings.authorizationStatus {
            case .notDetermined:
                self.notificationCenter.requestAuthorization(options: [.alert, .sound]) { granted, _ in
                    if granted {
                        self.createReminder(at: reminderDate)
                    } else {
                        TelemetryService.captureNonFatal(
                            message: "TrialReminderScheduler authorization not granted",
                            extra: ["identifier": self.reminderIdentifier]
                        )
                    }
                }
            case .authorized, .provisional:
                self.createReminder(at: reminderDate)
            default:
                break
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
        content.title = "Trial Ending Soon"
        content.body = "Your WhiteNoise trial ends tomorrow. Start your subscription to keep relaxing sounds playing without interruption."
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: reminderIdentifier, content: content, trigger: trigger)

        notificationCenter.add(request) { [weak self] error in
            if let error {
                TelemetryService.captureNonFatal(
                    error: error,
                    message: "TrialReminderScheduler failed to schedule reminder",
                    extra: [
                        "identifier": self?.reminderIdentifier ?? "unknown",
                        "fireDate": date.description
                    ]
                )
                return
            }

            guard let self = self else {
                TelemetryService.captureNonFatal(
                    message: "TrialReminderScheduler scheduling completion lost self",
                    extra: [
                        "identifier": self?.reminderIdentifier ?? "unknown"
                    ]
                )
                return
            }

            self.defaults.set(date, forKey: self.scheduledDateKey)
        }
    }

    private func reminderDate(for entitlement: EntitlementInfo) -> Date? {
        guard entitlement.periodType == .trial,
              let expiresAt = entitlement.expirationDate else {
            return nil
        }

        guard let reminderDate = Calendar.current.date(byAdding: .day, value: -1, to: expiresAt),
              reminderDate > Date() else {
            return nil
        }

        return reminderDate
    }

    private func isReminderScheduled(for date: Date) -> Bool {
        guard let storedDate = defaults.object(forKey: scheduledDateKey) as? Date else { return false }
        return abs(storedDate.timeIntervalSince(date)) < 1
    }
}
