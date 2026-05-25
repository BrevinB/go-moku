//
//  NotificationManager.swift
//  Gomoku
//
//  Local notifications for re-engagement.
//  GameKit handles "your turn" notifications via its own push system, so we don't duplicate those.
//

import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()

    private let reactivationIdentifier = "reactivation"
    private let longLapseIdentifier = "longLapse"
    private let authRequestedKey = "notifAuthRequested"

    private init() {}

    // MARK: - Authorization

    /// Request authorization the first time we try to schedule. The first prompt is
    /// the only one the OS will show — after that the user must change it in Settings,
    /// so we save the fact that we asked and skip re-prompting.
    private func ensureAuthorization(_ completion: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                completion(true)
            case .denied:
                completion(false)
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                    UserDefaults.standard.set(true, forKey: self.authRequestedKey)
                    completion(granted)
                }
            @unknown default:
                completion(false)
            }
        }
    }

    // MARK: - Reactivation Nudge

    /// Schedule (or replace) the "come back" notifications. Call on every app foreground
    /// so the timer keeps rolling forward — they only fire if the user stays away.
    func scheduleReactivationReminders() {
        ensureAuthorization { granted in
            guard granted else { return }
            self.cancelReactivationReminders()

            let center = UNUserNotificationCenter.current()

            // 3-day nudge — daily bonus angle
            let three = UNMutableNotificationContent()
            three.title = "Your daily bonus is waiting"
            three.body = "Hop in for free coins and a quick match. Your streak is yours to take."
            three.sound = .default
            let threeTrigger = UNTimeIntervalNotificationTrigger(
                timeInterval: 3 * 24 * 60 * 60,
                repeats: false
            )
            center.add(UNNotificationRequest(
                identifier: self.reactivationIdentifier,
                content: three,
                trigger: threeTrigger
            ))

            // 7-day deeper lapse — gentler tone, fresh hook
            let seven = UNMutableNotificationContent()
            seven.title = "Up for a quick game?"
            seven.body = "A fresh board is waiting. One round, five in a row — see you inside."
            seven.sound = .default
            let sevenTrigger = UNTimeIntervalNotificationTrigger(
                timeInterval: 7 * 24 * 60 * 60,
                repeats: false
            )
            center.add(UNNotificationRequest(
                identifier: self.longLapseIdentifier,
                content: seven,
                trigger: sevenTrigger
            ))
        }
    }

    func cancelReactivationReminders() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [reactivationIdentifier, longLapseIdentifier]
        )
    }
}
