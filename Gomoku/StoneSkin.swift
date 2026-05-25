//
//  StoneSkin.swift
//  Gomoku
//
//  Cosmetic stone-color overrides bought with coins. When no skin is selected the
//  active theme's stone colors are used; selecting a skin overrides just the stones,
//  leaving the rest of the theme intact.
//

import Foundation
import SpriteKit

struct StoneSkin: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let price: Int

    /// When nil, the active theme's color is used instead.
    let blackStone: ThemeColor?
    let blackHighlight: ThemeColor?
    let whiteStone: ThemeColor?
    let whiteHighlight: ThemeColor?
}

extension StoneSkin {

    /// The "no skin" option — every override is nil, so theme colors win.
    static let themeDefault = StoneSkin(
        id: "default",
        name: "Theme Default",
        price: 0,
        blackStone: nil,
        blackHighlight: nil,
        whiteStone: nil,
        whiteHighlight: nil
    )

    static let jade = StoneSkin(
        id: "jade",
        name: "Jade",
        price: 600,
        blackStone: ThemeColor(red: 0.05, green: 0.28, blue: 0.18, alpha: 1.0),
        blackHighlight: ThemeColor(red: 0.30, green: 0.65, blue: 0.45, alpha: 1.0),
        whiteStone: ThemeColor(red: 0.85, green: 0.94, blue: 0.85, alpha: 1.0),
        whiteHighlight: ThemeColor(red: 0.96, green: 1.0, blue: 0.95, alpha: 1.0)
    )

    static let ice = StoneSkin(
        id: "ice",
        name: "Ice",
        price: 800,
        blackStone: ThemeColor(red: 0.10, green: 0.20, blue: 0.36, alpha: 1.0),
        blackHighlight: ThemeColor(red: 0.45, green: 0.65, blue: 0.92, alpha: 1.0),
        whiteStone: ThemeColor(red: 0.90, green: 0.96, blue: 1.0, alpha: 1.0),
        whiteHighlight: ThemeColor(red: 0.78, green: 0.92, blue: 1.0, alpha: 1.0)
    )

    static let ember = StoneSkin(
        id: "ember",
        name: "Ember",
        price: 1000,
        blackStone: ThemeColor(red: 0.18, green: 0.05, blue: 0.05, alpha: 1.0),
        blackHighlight: ThemeColor(red: 0.95, green: 0.40, blue: 0.10, alpha: 1.0),
        whiteStone: ThemeColor(red: 0.98, green: 0.88, blue: 0.72, alpha: 1.0),
        whiteHighlight: ThemeColor(red: 1.0, green: 0.95, blue: 0.78, alpha: 1.0)
    )

    static let amethyst = StoneSkin(
        id: "amethyst",
        name: "Amethyst",
        price: 1200,
        blackStone: ThemeColor(red: 0.20, green: 0.08, blue: 0.32, alpha: 1.0),
        blackHighlight: ThemeColor(red: 0.65, green: 0.40, blue: 0.85, alpha: 1.0),
        whiteStone: ThemeColor(red: 0.94, green: 0.90, blue: 0.98, alpha: 1.0),
        whiteHighlight: ThemeColor(red: 1.0, green: 0.96, blue: 1.0, alpha: 1.0)
    )

    static let allSkins: [StoneSkin] = [
        .themeDefault,
        .jade,
        .ice,
        .ember,
        .amethyst
    ]
}
