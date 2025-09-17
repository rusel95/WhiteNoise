//
//  TrialReminderScheduler.swift
//  WhiteNoise
//
//  Schedules a local notification to remind users one day before
//  their introductory trial expires.
//

import Foundation
import UserNotifications

#if canImport(Adapty)
import Adapty
#endif

final class TrialReminderScheduler {
    private let notificationCenter = UNUserNotificationCenter.current()
    private let defaults = UserDefaults.standard
    private let reminderIdentifier = "whitenoise_trial_reminder"
    private let scheduledDateKey = "trialReminderScheduledDate"

    func scheduleReminderIfNeeded(for accessLevel: AdaptyProfile.AccessLevel) {
        guard let expiresAt = accessLevel.expiresAt,
              accessLevel.activeIntroductoryOfferType == "free_trial",
              !accessLevel.isLifetime else {
            cancelReminder()
            return
        }

        guard let reminderDate = Calendar.current.date(byAdding: .day, value: -1, to: expiresAt),
              reminderDate > Date() else {
            cancelReminder()
            return
        }

        if let storedDate = defaults.object(forKey: scheduledDateKey) as? Date,
           abs(storedDate.timeIntervalSince(reminderDate)) < 1 {
            return
        }

        notificationCenter.getNotificationSettings { [weak self] settings in
            guard let self = self else { return }

            switch settings.authorizationStatus {
            case .notDetermined:
                self.notificationCenter.requestAuthorization(options: [.alert, .sound]) { granted, _ in
                    if granted {
                        self.createReminder(at: reminderDate)
                    }
                }
            case .authorized, .provisional:
                self.createReminder(at: reminderDate)
            default:
                break
            }
        }
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
            guard error == nil, let self = self else { return }
            self.defaults.set(date, forKey: self.scheduledDateKey)
        }
    }
}
