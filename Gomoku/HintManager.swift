//
//  HintManager.swift
//  Gomoku
//
//  Created by Claude on 12/14/25.
//

import Foundation

// MARK: - Hint Pack
enum HintPack: String, CaseIterable {
    case small = "hint_pack_small"
    case medium = "hint_pack_medium"
    case large = "hint_pack_large"

    var hintCount: Int {
        switch self {
        case .small: return 5
        case .medium: return 15
        case .large: return 30
        }
    }

    var coinCost: Int {
        switch self {
        case .small: return 200
        case .medium: return 500
        case .large: return 900
        }
    }

    var displayName: String {
        switch self {
        case .small: return "5 Hints"
        case .medium: return "15 Hints"
        case .large: return "30 Hints"
        }
    }

    var savingsText: String? {
        switch self {
        case .small: return nil
        case .medium: return "Save 20%"
        case .large: return "Save 33%"
        }
    }
}

// MARK: - Notification
extension Notification.Name {
    static let hintsUpdated = Notification.Name("hintsUpdated")
}

// MARK: - Hint Manager
class HintManager {
    static let shared = HintManager()

    private let balanceKey = "hintBalance"
    private let starterHints = 3  // New players start with some hints

    private(set) var balance: Int {
        didSet {
            saveBalance()
            NotificationCenter.default.post(name: .hintsUpdated, object: nil)
        }
    }

    private init() {
        // Load balance from UserDefaults, or set starter hints for new players
        if UserDefaults.standard.object(forKey: balanceKey) != nil {
            balance = UserDefaults.standard.integer(forKey: balanceKey)
        } else {
            balance = starterHints
            saveBalance()
        }
    }

    // MARK: - Persistence

    private func saveBalance() {
        UserDefaults.standard.set(balance, forKey: balanceKey)
    }

    // MARK: - Using Hints

    /// Use a hint if available
    /// - Returns: true if hint was used, false if no hints available
    @discardableResult
    func useHint() -> Bool {
        guard balance > 0 else { return false }
        balance -= 1
        return true
    }

    /// Check if user has hints available
    var hasHints: Bool {
        return balance > 0
    }

    // MARK: - Purchasing Hint Packs

    /// Purchase a hint pack with coins
    /// - Parameter pack: The hint pack to purchase
    /// - Returns: true if purchase successful, false if insufficient coins
    @discardableResult
    func purchaseHintPack(_ pack: HintPack) -> Bool {
        guard CoinManager.shared.balance >= pack.coinCost else { return false }

        if CoinManager.shared.spendCoins(pack.coinCost) {
            balance += pack.hintCount
            return true
        }
        return false
    }

    // MARK: - Adding Hints (for rewards, etc.)

    /// Add hints to balance (for rewards, bonuses, etc.)
    /// - Parameter amount: Number of hints to add
    func addHints(_ amount: Int) {
        guard amount > 0 else { return }
        balance += amount
    }

    // MARK: - Debug/Testing

    #if DEBUG
    func resetBalance() {
        balance = starterHints
    }

    func setBalance(_ amount: Int) {
        balance = max(0, amount)
    }
    #endif
}
