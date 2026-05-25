//
//  ReviewPromptManager.swift
//  Gomoku
//
//  Triggers SKStoreReviewController after the user has had enough wins,
//  rate-limited to once per app version so we don't badger people.
//

import UIKit
import StoreKit

class ReviewPromptManager {
    static let shared = ReviewPromptManager()

    private let aiWinCountKey = "reviewPromptAIWinCount"
    private let lastPromptVersionKey = "reviewPromptLastVersion"
    private let winsRequiredBeforePrompt = 3

    private init() {}

    /// Called from StatisticsManager when the user wins against the AI.
    func recordAIWin() {
        let newCount = UserDefaults.standard.integer(forKey: aiWinCountKey) + 1
        UserDefaults.standard.set(newCount, forKey: aiWinCountKey)
    }

    /// Returns true if we should prompt: enough wins AND not yet prompted on this version.
    var shouldPrompt: Bool {
        guard UserDefaults.standard.integer(forKey: aiWinCountKey) >= winsRequiredBeforePrompt else {
            return false
        }
        let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        let lastVersion = UserDefaults.standard.string(forKey: lastPromptVersionKey)
        return lastVersion != currentVersion
    }

    /// Request the system review prompt if eligible. Returns true if we asked the system to show it.
    /// (The system itself decides whether to actually display.)
    @discardableResult
    func requestPromptIfAppropriate(in windowScene: UIWindowScene?) -> Bool {
        guard shouldPrompt, let scene = windowScene else { return false }

        let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        UserDefaults.standard.set(currentVersion, forKey: lastPromptVersionKey)

        AppStore.requestReview(in: scene)
        return true
    }
}
