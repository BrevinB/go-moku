//
//  GameCenterManager.swift
//  Gomoku
//
//  Created by Brevin Blalock on 10/13/25.
//

import GameKit
import UIKit

// MARK: - Leaderboard Identifiers
enum LeaderboardID: String, CaseIterable {
    case bestWinStreak = "com.gomoku.leaderboard.bestWinStreak"
    case totalWins = "com.gomoku.leaderboard.totalWins"
    case fastestWin = "com.gomoku.leaderboard.fastestWin"
}

// MARK: - Achievement Identifiers
enum AchievementID: String, CaseIterable {
    // First wins
    case firstWin = "com.gomoku.achievement.firstWin"
    case firstAIWin = "com.gomoku.achievement.firstAIWin"
    case firstOnlineWin = "com.gomoku.achievement.firstOnlineWin"

    // Difficulty achievements
    case beatEasyAI = "com.gomoku.achievement.beatEasyAI"
    case beatMediumAI = "com.gomoku.achievement.beatMediumAI"
    case beatHardAI = "com.gomoku.achievement.beatHardAI"

    // Streak achievements
    case winStreak5 = "com.gomoku.achievement.winStreak5"
    case winStreak10 = "com.gomoku.achievement.winStreak10"
    case winStreak25 = "com.gomoku.achievement.winStreak25"

    // Mastery achievements
    case played10Games = "com.gomoku.achievement.played10Games"
    case played50Games = "com.gomoku.achievement.played50Games"
    case played100Games = "com.gomoku.achievement.played100Games"

    // Speed achievement
    case quickWin = "com.gomoku.achievement.quickWin" // Win in 9 moves (minimum possible)
}

// MARK: - Game Center Manager
class GameCenterManager: NSObject {
    static let shared = GameCenterManager()

    private(set) var isAuthenticated = false
    private(set) var localPlayer: GKLocalPlayer?
    private(set) var activeMatches: [GKTurnBasedMatch] = []

    var authenticationViewController: UIViewController?

    /// Returns matches where it's the local player's turn
    var pendingTurnMatches: [GKTurnBasedMatch] {
        activeMatches.filter { match in
            match.status == .open &&
            match.currentParticipant?.player == GKLocalPlayer.local
        }
    }

    /// Returns true if there are any matches requiring attention
    var hasPendingMatches: Bool {
        !pendingTurnMatches.isEmpty
    }

    private override init() {
        super.init()
    }

    // MARK: - Authentication

    func authenticate(presentingViewController: UIViewController? = nil, completion: ((Bool, Error?) -> Void)? = nil) {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            guard let self = self else { return }

            if let viewController = viewController {
                // Player needs to log in - present the Game Center login view
                self.authenticationViewController = viewController
                if let presenting = presentingViewController {
                    presenting.present(viewController, animated: true)
                }
                completion?(false, nil)
            } else if GKLocalPlayer.local.isAuthenticated {
                // Player is authenticated
                self.isAuthenticated = true
                self.localPlayer = GKLocalPlayer.local
                self.registerForTurnBasedEvents()
                // Auto-load existing matches
                self.refreshActiveMatches()
                completion?(true, nil)
            } else {
                // Authentication failed
                self.isAuthenticated = false
                self.localPlayer = nil
                completion?(false, error)
            }
        }
    }

    // MARK: - Leaderboards

    func submitScore(_ score: Int, to leaderboard: LeaderboardID, completion: ((Error?) -> Void)? = nil) {
        guard isAuthenticated else {
            completion?(NSError(domain: "GameCenter", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"]))
            return
        }

        GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local, leaderboardIDs: [leaderboard.rawValue]) { error in
            completion?(error)
        }
    }

    func submitAllScores(stats: GameStatistics) {
        guard isAuthenticated else { return }

        // Submit best win streak
        if stats.bestWinStreak > 0 {
            submitScore(stats.bestWinStreak, to: .bestWinStreak)
        }

        // Submit total wins
        let totalWins = stats.aiWins + stats.blackWins + stats.whiteWins
        if totalWins > 0 {
            submitScore(totalWins, to: .totalWins)
        }

        // Submit fastest win (lower is better)
        if stats.fastestWin > 0 {
            submitScore(stats.fastestWin, to: .fastestWin)
        }
    }

    func showLeaderboards(from viewController: UIViewController) {
        guard isAuthenticated else { return }

        let gcViewController = GKGameCenterViewController(state: .leaderboards)
        gcViewController.gameCenterDelegate = self
        viewController.present(gcViewController, animated: true)
    }

    func showLeaderboard(_ leaderboard: LeaderboardID, from viewController: UIViewController) {
        guard isAuthenticated else { return }

        let gcViewController = GKGameCenterViewController(leaderboardID: leaderboard.rawValue, playerScope: .global, timeScope: .allTime)
        gcViewController.gameCenterDelegate = self
        viewController.present(gcViewController, animated: true)
    }

    // MARK: - Achievements

    func unlockAchievement(_ achievement: AchievementID, percentComplete: Double = 100.0, completion: ((Error?) -> Void)? = nil) {
        guard isAuthenticated else {
            completion?(NSError(domain: "GameCenter", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"]))
            return
        }

        let gkAchievement = GKAchievement(identifier: achievement.rawValue)
        gkAchievement.percentComplete = percentComplete
        gkAchievement.showsCompletionBanner = true

        GKAchievement.report([gkAchievement]) { error in
            completion?(error)
        }
    }

    func checkAndUnlockAchievements(stats: GameStatistics, difficulty: AIDifficulty? = nil, moveCount: Int? = nil, isOnlineWin: Bool = false) {
        guard isAuthenticated else { return }

        // First win achievement
        let totalWins = stats.aiWins + stats.blackWins + stats.whiteWins
        if totalWins >= 1 {
            unlockAchievement(.firstWin)
        }

        // First AI win
        if stats.aiWins >= 1 {
            unlockAchievement(.firstAIWin)
        }

        // First online win
        if isOnlineWin {
            unlockAchievement(.firstOnlineWin)
        }

        // Difficulty achievements
        if let difficulty = difficulty {
            switch difficulty {
            case .easy:
                if stats.aiEasyWins >= 1 { unlockAchievement(.beatEasyAI) }
            case .medium:
                if stats.aiMediumWins >= 1 { unlockAchievement(.beatMediumAI) }
            case .hard:
                if stats.aiHardWins >= 1 { unlockAchievement(.beatHardAI) }
            }
        }

        // Streak achievements
        if stats.bestWinStreak >= 5 { unlockAchievement(.winStreak5) }
        if stats.bestWinStreak >= 10 { unlockAchievement(.winStreak10) }
        if stats.bestWinStreak >= 25 { unlockAchievement(.winStreak25) }

        // Games played achievements
        if stats.totalGames >= 10 { unlockAchievement(.played10Games) }
        if stats.totalGames >= 50 { unlockAchievement(.played50Games) }
        if stats.totalGames >= 100 { unlockAchievement(.played100Games) }

        // Quick win achievement (9 moves is minimum for a win: 5 for winner + 4 for opponent)
        if let moves = moveCount, moves <= 9 {
            unlockAchievement(.quickWin)
        }
    }

    func showAchievements(from viewController: UIViewController) {
        guard isAuthenticated else { return }

        let gcViewController = GKGameCenterViewController(state: .achievements)
        gcViewController.gameCenterDelegate = self
        viewController.present(gcViewController, animated: true)
    }

    func resetAchievements(completion: ((Error?) -> Void)? = nil) {
        GKAchievement.resetAchievements { error in
            completion?(error)
        }
    }

    // MARK: - Turn-Based Multiplayer

    private func registerForTurnBasedEvents() {
        GKLocalPlayer.local.register(self)
    }

    private var matchmakerViewController: GKTurnBasedMatchmakerViewController?
    private var matchFoundCompletion: ((GKTurnBasedMatch?, Error?) -> Void)?

    func findMatch(from viewController: UIViewController, completion: @escaping (GKTurnBasedMatch?, Error?) -> Void) {
        guard isAuthenticated else {
            completion(nil, NSError(domain: "GameCenter", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"]))
            return
        }

        // Store completion to call when match is found via listener
        matchFoundCompletion = completion

        let request = GKMatchRequest()
        request.minPlayers = 2
        request.maxPlayers = 2

        let matchmakerVC = GKTurnBasedMatchmakerViewController(matchRequest: request)
        matchmakerVC.turnBasedMatchmakerDelegate = self
        matchmakerViewController = matchmakerVC

        viewController.present(matchmakerVC, animated: true)
    }

    func dismissMatchmaker() {
        matchmakerViewController?.dismiss(animated: true)
        matchmakerViewController = nil
    }

    func loadMatches(completion: @escaping ([GKTurnBasedMatch]?, Error?) -> Void) {
        guard isAuthenticated else {
            completion(nil, NSError(domain: "GameCenter", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"]))
            return
        }

        GKTurnBasedMatch.loadMatches { matches, error in
            completion(matches, error)
        }
    }

    /// Refreshes the active matches list and posts notification
    func refreshActiveMatches(completion: (([GKTurnBasedMatch]?) -> Void)? = nil) {
        guard isAuthenticated else {
            completion?(nil)
            return
        }

        GKTurnBasedMatch.loadMatches { [weak self] matches, error in
            guard let self = self else { return }

            if let matches = matches {
                // End any open matches where the opponent has quit
                for match in matches where match.status == .open {
                    if match.currentParticipant?.player == GKLocalPlayer.local {
                        let opponent = match.participants.first { $0.player != GKLocalPlayer.local }
                        if opponent?.matchOutcome == .quit {
                            self.endMatchForOpponentQuit(match)
                        }
                    }
                }

                // Filter to only open matches (excluding ones where opponent quit)
                self.activeMatches = matches.filter { match in
                    guard match.status == .open else { return false }
                    let opponent = match.participants.first { $0.player != GKLocalPlayer.local }
                    return opponent?.matchOutcome != .quit
                }
                // Post notification so UI can update
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .gameCenterMatchesRefreshed, object: nil)
                }
            }
            completion?(matches)
        }
    }
}

// MARK: - GKGameCenterControllerDelegate
extension GameCenterManager: GKGameCenterControllerDelegate {
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
}

// MARK: - GKTurnBasedMatchmakerViewControllerDelegate
extension GameCenterManager: GKTurnBasedMatchmakerViewControllerDelegate {
    func turnBasedMatchmakerViewControllerWasCancelled(_ viewController: GKTurnBasedMatchmakerViewController) {
        viewController.dismiss(animated: true)
        matchmakerViewController = nil
        matchFoundCompletion = nil
    }

    func turnBasedMatchmakerViewController(_ viewController: GKTurnBasedMatchmakerViewController, didFailWithError error: Error) {
        viewController.dismiss(animated: true)
        matchmakerViewController = nil
        let completion = matchFoundCompletion
        matchFoundCompletion = nil
        completion?(nil, error)
    }
}

// MARK: - GKLocalPlayerListener
extension GameCenterManager: GKLocalPlayerListener {
    func player(_ player: GKPlayer, receivedTurnEventFor match: GKTurnBasedMatch, didBecomeActive: Bool) {
        // Check if opponent quit - if so, end the match automatically
        if match.status == .open && match.currentParticipant?.player == GKLocalPlayer.local {
            let opponent = match.participants.first { $0.player != GKLocalPlayer.local }
            if opponent?.matchOutcome == .quit {
                endMatchForOpponentQuit(match)
                return
            }
        }

        // Refresh active matches list
        refreshActiveMatches()

        // If we have a pending matchmaker completion, this is a new match
        if let completion = matchFoundCompletion {
            matchFoundCompletion = nil
            dismissMatchmaker()
            completion(match, nil)
            return
        }

        // If the app became active due to this notification (cold launch or background),
        // post a notification to navigate to the match
        if didBecomeActive {
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .gameCenterShouldOpenMatch,
                    object: match
                )
            }
            return
        }

        // Otherwise, post notification for active matches to handle
        NotificationCenter.default.post(
            name: .gameCenterTurnReceived,
            object: match,
            userInfo: ["didBecomeActive": didBecomeActive]
        )
    }

    func player(_ player: GKPlayer, matchEnded match: GKTurnBasedMatch) {
        NotificationCenter.default.post(
            name: .gameCenterMatchEnded,
            object: match
        )
    }

    func player(_ player: GKPlayer, wantsToQuitMatch match: GKTurnBasedMatch) {
        // Opponent wants to quit - end the match with local player winning
        endMatchForOpponentQuit(match)
    }

    /// Ends a match where the opponent has quit, awarding the local player a win
    private func endMatchForOpponentQuit(_ match: GKTurnBasedMatch) {
        for participant in match.participants {
            if participant.player == GKLocalPlayer.local {
                participant.matchOutcome = .won
            } else {
                participant.matchOutcome = .quit
            }
        }

        match.endMatchInTurn(withMatch: match.matchData ?? Data()) { [weak self] error in
            if let error = error {
                print("Error ending match after opponent quit: \(error.localizedDescription)")
            }
            self?.refreshActiveMatches()
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .gameCenterMatchEnded, object: match)
            }
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let gameCenterTurnReceived = Notification.Name("gameCenterTurnReceived")
    static let gameCenterMatchEnded = Notification.Name("gameCenterMatchEnded")
    static let gameCenterMatchesRefreshed = Notification.Name("gameCenterMatchesRefreshed")
    static let gameCenterShouldOpenMatch = Notification.Name("gameCenterShouldOpenMatch")
}
