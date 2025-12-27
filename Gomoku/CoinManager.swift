//
//  CoinManager.swift
//  Gomoku
//
//  Created by Claude on 12/13/25.
//

import Foundation

// MARK: - Game Result
enum GameResult {
    case win
    case loss
    case draw
}

// MARK: - Coin Manager
class CoinManager {
    static let shared = CoinManager()

    private let balanceKey = "coinBalance"
    private let starterCoins = 50  // New players start with some coins

    private(set) var balance: Int {
        didSet {
            saveBalance()
        }
    }

    private init() {
        // Load balance from UserDefaults, or set starter coins for new players
        if UserDefaults.standard.object(forKey: balanceKey) != nil {
            balance = UserDefaults.standard.integer(forKey: balanceKey)
        } else {
            balance = starterCoins
            saveBalance()
        }
    }

    // MARK: - Persistence

    private func saveBalance() {
        UserDefaults.standard.set(balance, forKey: balanceKey)
    }

    // MARK: - Earning Coins

    /// Calculate and award coins for completing a game
    /// - Parameters:
    ///   - result: The game outcome (win/loss/draw)
    ///   - difficulty: AI difficulty (nil for friend games)
    /// - Returns: The number of coins earned
    @discardableResult
    func earnCoins(for result: GameResult, difficulty: AIDifficulty?) -> Int {
        var earned = 0

        // Base reward for completing any game
        let baseReward = 2
        earned += baseReward

        // Bonus for winning (scales with difficulty)
        if result == .win, let difficulty = difficulty {
            switch difficulty {
            case .easy:
                earned += 3   // 5 total
            case .medium:
                earned += 5   // 7 total
            case .hard:
                earned += 8   // 10 total
            }
        }

        balance += earned
        return earned
    }

    // MARK: - Spending Coins

    /// Spend a specific amount of coins
    /// - Parameter amount: Amount to spend
    /// - Returns: true if successful, false if insufficient balance
    @discardableResult
    func spendCoins(_ amount: Int) -> Bool {
        guard amount >= 0 else { return false }
        guard balance >= amount else { return false }

        balance -= amount
        NotificationCenter.default.post(name: .coinsUpdated, object: nil)
        return true
    }

    // MARK: - Adding Coins (for IAP)

    /// Add coins to balance (used for purchases)
    /// - Parameter amount: Amount to add
    func addCoins(_ amount: Int) {
        guard amount > 0 else { return }
        balance += amount
    }

    // MARK: - Debug/Testing

    #if DEBUG
    func resetBalance() {
        balance = starterCoins
    }

    func setBalance(_ amount: Int) {
        balance = max(0, amount)
    }
    #endif
}
