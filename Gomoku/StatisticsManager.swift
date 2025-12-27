//
//  StatisticsManager.swift
//  Gomoku
//
//  Created by Brevin Blalock on 10/13/25.
//

import Foundation

struct GameStatistics: Codable {
    var totalGames: Int = 0

    // VS AI Stats
    var aiWins: Int = 0
    var aiLosses: Int = 0
    var aiEasyWins: Int = 0
    var aiMediumWins: Int = 0
    var aiHardWins: Int = 0

    // VS Friend Stats
    var friendGamesPlayed: Int = 0
    var blackWins: Int = 0
    var whiteWins: Int = 0

    // Streak tracking
    var currentWinStreak: Int = 0
    var bestWinStreak: Int = 0
    var currentLossStreak: Int = 0

    // Additional metrics
    var totalMovesPlayed: Int = 0
    var fastestWin: Int = 0  // Fewest moves to win (0 = no wins yet)
    var longestGame: Int = 0  // Most moves in a game

    mutating func recordAIWin(difficulty: AIDifficulty, moveCount: Int) {
        totalGames += 1
        aiWins += 1

        switch difficulty {
        case .easy: aiEasyWins += 1
        case .medium: aiMediumWins += 1
        case .hard: aiHardWins += 1
        }

        currentWinStreak += 1
        currentLossStreak = 0

        if currentWinStreak > bestWinStreak {
            bestWinStreak = currentWinStreak
        }

        updateMoveStats(moveCount: moveCount, isWin: true)
    }

    mutating func recordAILoss(moveCount: Int) {
        totalGames += 1
        aiLosses += 1
        currentWinStreak = 0
        currentLossStreak += 1

        updateMoveStats(moveCount: moveCount, isWin: false)
    }

    mutating func recordFriendGame(winner: Player, moveCount: Int) {
        totalGames += 1
        friendGamesPlayed += 1

        if winner == .black {
            blackWins += 1
        } else if winner == .white {
            whiteWins += 1
        }

        updateMoveStats(moveCount: moveCount, isWin: false)
    }

    private mutating func updateMoveStats(moveCount: Int, isWin: Bool) {
        totalMovesPlayed += moveCount

        if isWin {
            if fastestWin == 0 || moveCount < fastestWin {
                fastestWin = moveCount
            }
        }

        if moveCount > longestGame {
            longestGame = moveCount
        }
    }

    var aiWinRate: Double {
        let totalAIGames = aiWins + aiLosses
        guard totalAIGames > 0 else { return 0 }
        return Double(aiWins) / Double(totalAIGames) * 100.0
    }

    var averageMovesPerGame: Double {
        guard totalGames > 0 else { return 0 }
        return Double(totalMovesPlayed) / Double(totalGames)
    }
}

class StatisticsManager {
    static let shared = StatisticsManager()

    private let userDefaultsKey = "gomokuStatistics"
    private(set) var stats: GameStatistics

    private init() {
        // Load saved statistics
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode(GameStatistics.self, from: data) {
            self.stats = decoded
        } else {
            self.stats = GameStatistics()
        }
    }

    private func save() {
        if let encoded = try? JSONEncoder().encode(stats) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }

    /// Record an AI win and award coins
    /// - Returns: Number of coins earned
    @discardableResult
    func recordAIWin(difficulty: AIDifficulty, moveCount: Int) -> Int {
        stats.recordAIWin(difficulty: difficulty, moveCount: moveCount)
        save()

        // Award coins for the win
        let coinsEarned = CoinManager.shared.earnCoins(for: .win, difficulty: difficulty)

        // Report to Game Center
        GameCenterManager.shared.submitAllScores(stats: stats)
        GameCenterManager.shared.checkAndUnlockAchievements(
            stats: stats,
            difficulty: difficulty,
            moveCount: moveCount
        )

        return coinsEarned
    }

    /// Record an AI loss and award coins
    /// - Returns: Number of coins earned
    @discardableResult
    func recordAILoss(difficulty: AIDifficulty, moveCount: Int) -> Int {
        stats.recordAILoss(moveCount: moveCount)
        save()

        // Award coins for completing the game (smaller reward for loss)
        let coinsEarned = CoinManager.shared.earnCoins(for: .loss, difficulty: difficulty)

        // Report games played achievement progress
        GameCenterManager.shared.checkAndUnlockAchievements(stats: stats)

        return coinsEarned
    }

    func recordFriendGame(winner: Player, moveCount: Int) {
        stats.recordFriendGame(winner: winner, moveCount: moveCount)
        save()

        // Report to Game Center
        GameCenterManager.shared.submitAllScores(stats: stats)
        GameCenterManager.shared.checkAndUnlockAchievements(stats: stats, moveCount: moveCount)
    }

    func recordOnlineWin(moveCount: Int) {
        // Online wins count toward total stats
        stats.totalGames += 1
        stats.currentWinStreak += 1
        if stats.currentWinStreak > stats.bestWinStreak {
            stats.bestWinStreak = stats.currentWinStreak
        }
        stats.totalMovesPlayed += moveCount
        if stats.fastestWin == 0 || moveCount < stats.fastestWin {
            stats.fastestWin = moveCount
        }
        if moveCount > stats.longestGame {
            stats.longestGame = moveCount
        }
        save()

        // Report to Game Center
        GameCenterManager.shared.submitAllScores(stats: stats)
        GameCenterManager.shared.checkAndUnlockAchievements(
            stats: stats,
            moveCount: moveCount,
            isOnlineWin: true
        )
    }

    func recordOnlineLoss(moveCount: Int) {
        stats.totalGames += 1
        stats.currentWinStreak = 0
        stats.totalMovesPlayed += moveCount
        if moveCount > stats.longestGame {
            stats.longestGame = moveCount
        }
        save()

        GameCenterManager.shared.checkAndUnlockAchievements(stats: stats)
    }

    func resetStatistics() {
        stats = GameStatistics()
        save()
    }
}
