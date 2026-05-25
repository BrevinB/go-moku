//
//  AppDelegate.swift
//  Gomoku
//
//  Created by Brevin Blalock on 10/13/25.
//

import UIKit
import GameKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Configure RevenueCat for in-app purchases
        StoreManager.shared.configure()

        // Start collecting MetricKit crash / hang / performance payloads.
        MetricsManager.shared.start()

        // Authenticate with Game Center
        GameCenterManager.shared.authenticate { success, error in
            if success {
                print("Game Center authentication successful")
                // Submit any pending scores from previous sessions
                GameCenterManager.shared.submitAllScores(stats: StatisticsManager.shared.stats)
            } else if let error = error {
                print("Game Center authentication failed: \(error.localizedDescription)")
            }
        }

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Refresh Game Center matches when returning to foreground
        if GameCenterManager.shared.isAuthenticated {
            GameCenterManager.shared.refreshActiveMatches()
            // Nudge opponents in any matches that have gone idle on their side.
            TurnBasedMatchManager.shared.sendRemindersForIdleMatches()
        }
        // Cancel any pending re-engagement reminders — they're moot now that the user is back.
        NotificationManager.shared.cancelReactivationReminders()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Reschedule the 3-/7-day reactivation nudges from "now". If the user comes back
        // before they fire, they're cancelled in applicationWillEnterForeground.
        NotificationManager.shared.scheduleReactivationReminders()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive.
    }


}

