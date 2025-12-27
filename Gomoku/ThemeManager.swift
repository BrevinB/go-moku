//
//  ThemeManager.swift
//  Gomoku
//
//  Created by Claude on 12/13/25.
//

import Foundation

class ThemeManager {
    static let shared = ThemeManager()

    private let currentThemeKey = "currentThemeId"
    private let unlockedThemesKey = "unlockedThemeIds"

    /// The currently selected theme
    private(set) var currentTheme: BoardTheme

    /// IDs of themes the player has unlocked
    private(set) var unlockedThemeIds: Set<String>

    private init() {
        // Load unlocked themes (classic is always unlocked)
        if let data = UserDefaults.standard.data(forKey: unlockedThemesKey),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            unlockedThemeIds = decoded
        } else {
            unlockedThemeIds = [BoardTheme.classic.id]
        }

        // Ensure classic is always unlocked
        if !unlockedThemeIds.contains(BoardTheme.classic.id) {
            unlockedThemeIds.insert(BoardTheme.classic.id)
        }

        // Load current theme
        let savedThemeId = UserDefaults.standard.string(forKey: currentThemeKey) ?? BoardTheme.classic.id

        // Find the saved theme, fallback to classic if not found or not unlocked
        if let theme = BoardTheme.allThemes.first(where: { $0.id == savedThemeId }),
           unlockedThemeIds.contains(theme.id) {
            currentTheme = theme
        } else {
            currentTheme = .classic
        }
    }

    // MARK: - Persistence

    private func saveUnlockedThemes() {
        if let encoded = try? JSONEncoder().encode(unlockedThemeIds) {
            UserDefaults.standard.set(encoded, forKey: unlockedThemesKey)
        }
    }

    private func saveCurrentTheme() {
        UserDefaults.standard.set(currentTheme.id, forKey: currentThemeKey)
    }

    // MARK: - Theme Management

    /// Check if a theme is unlocked
    func isUnlocked(_ theme: BoardTheme) -> Bool {
        return unlockedThemeIds.contains(theme.id)
    }

    /// Check if a theme is unlocked by ID
    func isUnlocked(themeId: String) -> Bool {
        return unlockedThemeIds.contains(themeId)
    }

    /// Get all themes with their unlock status
    func getAllThemesWithStatus() -> [(theme: BoardTheme, isUnlocked: Bool)] {
        return BoardTheme.allThemes.map { theme in
            (theme: theme, isUnlocked: isUnlocked(theme))
        }
    }

    /// Attempt to purchase a theme with coins
    /// - Parameter theme: The theme to purchase
    /// - Returns: true if purchase was successful, false if insufficient coins or already owned
    @discardableResult
    func purchaseTheme(_ theme: BoardTheme) -> Bool {
        // Already unlocked
        if isUnlocked(theme) {
            return false
        }

        // Free themes don't need coins
        if theme.price == 0 {
            unlockedThemeIds.insert(theme.id)
            saveUnlockedThemes()
            return true
        }

        // Try to spend coins
        if CoinManager.shared.spendCoins(theme.price) {
            unlockedThemeIds.insert(theme.id)
            saveUnlockedThemes()
            return true
        }

        return false
    }

    /// Check if player can afford a theme
    func canAfford(_ theme: BoardTheme) -> Bool {
        if isUnlocked(theme) { return true }
        return CoinManager.shared.balance >= theme.price
    }

    /// Apply a theme (must be unlocked)
    /// - Parameter theme: The theme to apply
    /// - Returns: true if successfully applied
    @discardableResult
    func applyTheme(_ theme: BoardTheme) -> Bool {
        guard isUnlocked(theme) else { return false }

        currentTheme = theme
        saveCurrentTheme()

        // Post notification so scenes can update
        NotificationCenter.default.post(name: .themeDidChange, object: theme)

        return true
    }

    /// Apply a theme by ID
    @discardableResult
    func applyTheme(id: String) -> Bool {
        guard let theme = BoardTheme.allThemes.first(where: { $0.id == id }) else {
            return false
        }
        return applyTheme(theme)
    }

    /// Get a theme by ID
    func getTheme(id: String) -> BoardTheme? {
        return BoardTheme.allThemes.first { $0.id == id }
    }

    // MARK: - Debug/Testing

    #if DEBUG
    func unlockAllThemes() {
        for theme in BoardTheme.allThemes {
            unlockedThemeIds.insert(theme.id)
        }
        saveUnlockedThemes()
    }

    func resetToDefaults() {
        unlockedThemeIds = [BoardTheme.classic.id]
        currentTheme = .classic
        saveUnlockedThemes()
        saveCurrentTheme()
    }
    #endif
}

// MARK: - Notification Names

extension Notification.Name {
    static let themeDidChange = Notification.Name("themeDidChange")
}
