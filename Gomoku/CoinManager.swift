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
    private let starterCoins = 250  // New players start with some coins

    // Daily-login bonus
    private let lastClaimDateKey = "dailyBonusLastClaim"
    private let loginStreakKey = "dailyBonusStreak"
    private let dailyBase = 50
    private let dailyPerStreak = 25
    private let dailyCap = 500

    private(set) var balance: Int {
        didSet {
            saveBalance()
        }
    }

    private(set) var loginStreak: Int {
        didSet {
            UserDefaults.standard.set(loginStreak, forKey: loginStreakKey)
        }
    }

    private init() {
        // Initialize all stored properties before any method calls.
        loginStreak = UserDefaults.standard.integer(forKey: loginStreakKey)
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
        let baseReward = 10
        earned += baseReward

        // Bonus for winning (scales with difficulty)
        if result == .win, let difficulty = difficulty {
            switch difficulty {
            case .easy:
                earned += 15   // 25 total
            case .medium:
                earned += 25   // 35 total
            case .hard:
                earned += 40   // 50 total
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
        NotificationCenter.default.post(name: .coinsUpdated, object: nil)
    }

    // MARK: - Daily Login Bonus

    struct DailyBonusResult {
        let coinsAwarded: Int
        let streak: Int
        let isStreakContinuation: Bool
    }

    var isDailyBonusAvailable: Bool {
        guard let last = lastClaimDate else { return true }
        return !Calendar.current.isDateInToday(last)
    }

    var lastClaimDate: Date? {
        UserDefaults.standard.object(forKey: lastClaimDateKey) as? Date
    }

    /// Award today's coin bonus. Returns nil if already claimed today.
    /// Streak increments on consecutive calendar days; resets to 1 after a gap.
    @discardableResult
    func claimDailyBonusIfAvailable() -> DailyBonusResult? {
        let now = Date()
        let calendar = Calendar.current

        if let last = lastClaimDate, calendar.isDateInToday(last) {
            return nil
        }

        let isContinuation: Bool
        if let last = lastClaimDate, let yesterday = calendar.date(byAdding: .day, value: -1, to: now) {
            isContinuation = calendar.isDate(last, inSameDayAs: yesterday)
        } else {
            isContinuation = false
        }

        loginStreak = isContinuation ? loginStreak + 1 : 1

        let reward = min(dailyBase + (loginStreak - 1) * dailyPerStreak, dailyCap)
        balance += reward
        UserDefaults.standard.set(now, forKey: lastClaimDateKey)
        NotificationCenter.default.post(name: .coinsUpdated, object: nil)

        return DailyBonusResult(coinsAwarded: reward, streak: loginStreak, isStreakContinuation: isContinuation)
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
