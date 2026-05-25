//
//  StoneSkinManager.swift
//  Gomoku
//

import Foundation

class StoneSkinManager {
    static let shared = StoneSkinManager()

    private let currentSkinKey = "currentStoneSkinId"
    private let unlockedSkinsKey = "unlockedStoneSkinIds"

    private(set) var currentSkin: StoneSkin
    private(set) var unlockedSkinIds: Set<String>

    private init() {
        if let data = UserDefaults.standard.data(forKey: unlockedSkinsKey),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            unlockedSkinIds = decoded
        } else {
            unlockedSkinIds = [StoneSkin.themeDefault.id]
        }
        unlockedSkinIds.insert(StoneSkin.themeDefault.id)

        let savedId = UserDefaults.standard.string(forKey: currentSkinKey) ?? StoneSkin.themeDefault.id
        if let skin = StoneSkin.allSkins.first(where: { $0.id == savedId }),
           unlockedSkinIds.contains(skin.id) {
            currentSkin = skin
        } else {
            currentSkin = .themeDefault
        }
    }

    // MARK: - Persistence

    private func saveUnlocked() {
        if let encoded = try? JSONEncoder().encode(unlockedSkinIds) {
            UserDefaults.standard.set(encoded, forKey: unlockedSkinsKey)
        }
    }

    private func saveCurrent() {
        UserDefaults.standard.set(currentSkin.id, forKey: currentSkinKey)
    }

    // MARK: - Ownership

    func isUnlocked(_ skin: StoneSkin) -> Bool {
        unlockedSkinIds.contains(skin.id)
    }

    func canAfford(_ skin: StoneSkin) -> Bool {
        isUnlocked(skin) || CoinManager.shared.balance >= skin.price
    }

    @discardableResult
    func purchase(_ skin: StoneSkin) -> Bool {
        if isUnlocked(skin) { return false }
        if skin.price == 0 {
            unlockedSkinIds.insert(skin.id)
            saveUnlocked()
            return true
        }
        guard CoinManager.shared.spendCoins(skin.price) else { return false }
        unlockedSkinIds.insert(skin.id)
        saveUnlocked()
        return true
    }

    @discardableResult
    func apply(_ skin: StoneSkin) -> Bool {
        guard isUnlocked(skin) else { return false }
        currentSkin = skin
        saveCurrent()
        NotificationCenter.default.post(name: .stoneSkinDidChange, object: skin)
        return true
    }

    // MARK: - Theme-aware accessors used by stone renderers

    func blackStoneColor(theme: BoardTheme) -> ThemeColor {
        currentSkin.blackStone ?? theme.blackStoneColor
    }

    func blackHighlightColor(theme: BoardTheme) -> ThemeColor {
        currentSkin.blackHighlight ?? theme.blackStoneHighlight
    }

    func whiteStoneColor(theme: BoardTheme) -> ThemeColor {
        currentSkin.whiteStone ?? theme.whiteStoneColor
    }

    func whiteHighlightColor(theme: BoardTheme) -> ThemeColor {
        currentSkin.whiteHighlight ?? theme.whiteStoneHighlight
    }
}

extension Notification.Name {
    static let stoneSkinDidChange = Notification.Name("stoneSkinDidChange")
}
