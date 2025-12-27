//
//  Theme.swift
//  Gomoku
//
//  Created by Claude on 12/13/25.
//

import SpriteKit

// MARK: - Theme Color

/// A codable wrapper for storing colors
struct ThemeColor: Codable, Equatable {
    let red: CGFloat
    let green: CGFloat
    let blue: CGFloat
    let alpha: CGFloat

    init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    init(_ color: SKColor) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        self.red = r
        self.green = g
        self.blue = b
        self.alpha = a
    }

    var skColor: SKColor {
        SKColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}

// MARK: - Gradient Colors

/// Three colors for background gradient (top to bottom)
struct GradientColors: Codable, Equatable {
    let topColor: ThemeColor
    let midColor: ThemeColor
    let bottomColor: ThemeColor
}

// MARK: - Stone Style

enum StoneStyle: String, Codable, CaseIterable {
    case classic    // Current look with highlights and shadows
    case flat       // Solid colors, no gradients
    case glossy     // Enhanced shine effect
}

// MARK: - Board Theme

struct BoardTheme: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let price: Int  // 0 = free/default

    // Board colors
    let boardColor: ThemeColor           // Main board frame
    let boardStrokeColor: ThemeColor     // Board frame border
    let innerBoardColor: ThemeColor      // Inner playing surface
    let innerBoardStrokeColor: ThemeColor
    let gridLineColor: ThemeColor        // Grid lines
    let starPointColor: ThemeColor       // Star point dots

    // Background gradient
    let backgroundGradient: GradientColors

    // Decorative circles (optional ambient elements)
    let decorativeCircleColors: [ThemeColor]

    // Stone colors
    let blackStoneColor: ThemeColor
    let blackStoneHighlight: ThemeColor
    let whiteStoneColor: ThemeColor
    let whiteStoneHighlight: ThemeColor
    let stoneStyle: StoneStyle

    // UI colors
    let statusBackgroundColor: ThemeColor
    let statusStrokeColor: ThemeColor
    let statusTextColor: ThemeColor
    let buttonBackgroundColor: ThemeColor
    let buttonStrokeColor: ThemeColor
    let buttonTextColor: ThemeColor
}

// MARK: - Default Themes

extension BoardTheme {

    /// Classic theme - Nature inspired with forest greens and sky blues (default, free)
    static let classic = BoardTheme(
        id: "classic",
        name: "Classic",
        price: 0,
        // Board: Natural cedar wood with organic undertones
        boardColor: ThemeColor(red: 0.42, green: 0.35, blue: 0.26, alpha: 1.0),       // Cedar brown
        boardStrokeColor: ThemeColor(red: 0.32, green: 0.26, blue: 0.18, alpha: 0.9),
        innerBoardColor: ThemeColor(red: 0.78, green: 0.68, blue: 0.52, alpha: 1.0),  // Honey maple
        innerBoardStrokeColor: ThemeColor(red: 0.52, green: 0.44, blue: 0.32, alpha: 0.5),
        gridLineColor: ThemeColor(red: 0.28, green: 0.24, blue: 0.18, alpha: 0.75),   // Dark bark
        starPointColor: ThemeColor(red: 0.22, green: 0.18, blue: 0.12, alpha: 0.9),
        // Background: Sky to meadow gradient
        backgroundGradient: GradientColors(
            topColor: ThemeColor(red: 0.68, green: 0.82, blue: 0.92, alpha: 1.0),     // Soft sky blue
            midColor: ThemeColor(red: 0.75, green: 0.85, blue: 0.78, alpha: 1.0),     // Misty horizon
            bottomColor: ThemeColor(red: 0.72, green: 0.78, blue: 0.65, alpha: 1.0)   // Meadow green
        ),
        // Decorative: Nature elements - clouds and foliage
        decorativeCircleColors: [
            ThemeColor(red: 0.45, green: 0.62, blue: 0.45, alpha: 0.18),  // Forest green
            ThemeColor(red: 0.55, green: 0.72, blue: 0.82, alpha: 0.15),  // Cloud blue
            ThemeColor(red: 0.62, green: 0.70, blue: 0.55, alpha: 0.12)   // Sage moss
        ],
        // Stones: River stones - polished slate and smooth pebble
        blackStoneColor: ThemeColor(red: 0.12, green: 0.14, blue: 0.16, alpha: 1.0),  // Deep slate
        blackStoneHighlight: ThemeColor(red: 0.32, green: 0.36, blue: 0.40, alpha: 1.0),
        whiteStoneColor: ThemeColor(red: 0.95, green: 0.94, blue: 0.91, alpha: 1.0),  // Smooth pebble
        whiteStoneHighlight: ThemeColor(red: 1.0, green: 0.99, blue: 0.97, alpha: 1.0),
        stoneStyle: .classic,
        // UI: Natural tones
        statusBackgroundColor: ThemeColor(red: 0.94, green: 0.96, blue: 0.92, alpha: 0.95),
        statusStrokeColor: ThemeColor(red: 0.45, green: 0.55, blue: 0.45, alpha: 0.5),
        statusTextColor: ThemeColor(red: 0.22, green: 0.28, blue: 0.22, alpha: 1.0),
        buttonBackgroundColor: ThemeColor(red: 0.45, green: 0.58, blue: 0.48, alpha: 0.3),  // Forest button
        buttonStrokeColor: ThemeColor(red: 0.38, green: 0.52, blue: 0.42, alpha: 0.65),
        buttonTextColor: ThemeColor(red: 0.20, green: 0.28, blue: 0.20, alpha: 1.0)
    )

    /// Zen theme - Traditional Japanese washi paper and kaya wood
    static let zen = BoardTheme(
        id: "zen",
        name: "禅 · Zen",
        price: 150,
        // Board: Traditional kaya wood color
        boardColor: ThemeColor(red: 0.58, green: 0.48, blue: 0.32, alpha: 0.98),
        boardStrokeColor: ThemeColor(red: 0.45, green: 0.35, blue: 0.22, alpha: 0.9),
        innerBoardColor: ThemeColor(red: 0.82, green: 0.72, blue: 0.52, alpha: 1.0),
        innerBoardStrokeColor: ThemeColor(red: 0.65, green: 0.55, blue: 0.38, alpha: 0.5),
        gridLineColor: ThemeColor(red: 0.25, green: 0.20, blue: 0.12, alpha: 0.7),
        starPointColor: ThemeColor(red: 0.20, green: 0.16, blue: 0.10, alpha: 0.9),
        // Background: Washi paper gradient
        backgroundGradient: GradientColors(
            topColor: ThemeColor(red: 0.96, green: 0.94, blue: 0.89, alpha: 1.0),
            midColor: ThemeColor(red: 0.94, green: 0.91, blue: 0.85, alpha: 1.0),
            bottomColor: ThemeColor(red: 0.92, green: 0.88, blue: 0.82, alpha: 1.0)
        ),
        // Decorative: Ink wash circles
        decorativeCircleColors: [
            ThemeColor(red: 0.15, green: 0.13, blue: 0.12, alpha: 0.04),
            ThemeColor(red: 0.55, green: 0.40, blue: 0.28, alpha: 0.06),
            ThemeColor(red: 0.45, green: 0.52, blue: 0.35, alpha: 0.05)
        ],
        // Stones: Traditional slate and shell
        blackStoneColor: ThemeColor(red: 0.10, green: 0.10, blue: 0.12, alpha: 1.0),
        blackStoneHighlight: ThemeColor(red: 0.30, green: 0.30, blue: 0.35, alpha: 1.0),
        whiteStoneColor: ThemeColor(red: 0.96, green: 0.95, blue: 0.92, alpha: 1.0),
        whiteStoneHighlight: ThemeColor(red: 1.0, green: 1.0, blue: 0.98, alpha: 1.0),
        stoneStyle: .classic,
        // UI: Washi paper style
        statusBackgroundColor: ThemeColor(red: 0.96, green: 0.94, blue: 0.89, alpha: 0.95),
        statusStrokeColor: ThemeColor(red: 0.55, green: 0.40, blue: 0.28, alpha: 0.4),
        statusTextColor: ThemeColor(red: 0.35, green: 0.25, blue: 0.18, alpha: 1.0),
        buttonBackgroundColor: ThemeColor(red: 0.55, green: 0.40, blue: 0.28, alpha: 0.15),
        buttonStrokeColor: ThemeColor(red: 0.55, green: 0.40, blue: 0.28, alpha: 0.4),
        buttonTextColor: ThemeColor(red: 0.35, green: 0.25, blue: 0.18, alpha: 1.0)
    )

    /// Dark mode theme
    static let darkMode = BoardTheme(
        id: "dark_mode",
        name: "Dark Mode",
        price: 50,
        boardColor: ThemeColor(red: 0.18, green: 0.18, blue: 0.20, alpha: 0.98),
        boardStrokeColor: ThemeColor(red: 0.30, green: 0.30, blue: 0.32, alpha: 0.8),
        innerBoardColor: ThemeColor(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0),
        innerBoardStrokeColor: ThemeColor(red: 0.35, green: 0.35, blue: 0.38, alpha: 0.6),
        gridLineColor: ThemeColor(red: 0.45, green: 0.45, blue: 0.48, alpha: 0.5),
        starPointColor: ThemeColor(red: 0.55, green: 0.55, blue: 0.58, alpha: 0.7),
        backgroundGradient: GradientColors(
            topColor: ThemeColor(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0),
            midColor: ThemeColor(red: 0.10, green: 0.10, blue: 0.12, alpha: 1.0),
            bottomColor: ThemeColor(red: 0.08, green: 0.08, blue: 0.10, alpha: 1.0)
        ),
        decorativeCircleColors: [
            ThemeColor(red: 0.20, green: 0.20, blue: 0.25, alpha: 0.3),
            ThemeColor(red: 0.18, green: 0.22, blue: 0.28, alpha: 0.25),
            ThemeColor(red: 0.22, green: 0.20, blue: 0.25, alpha: 0.28)
        ],
        blackStoneColor: ThemeColor(red: 0.05, green: 0.05, blue: 0.08, alpha: 1.0),
        blackStoneHighlight: ThemeColor(red: 0.25, green: 0.25, blue: 0.30, alpha: 1.0),
        whiteStoneColor: ThemeColor(red: 0.88, green: 0.88, blue: 0.90, alpha: 1.0),
        whiteStoneHighlight: ThemeColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),
        stoneStyle: .classic,
        statusBackgroundColor: ThemeColor(red: 0.20, green: 0.20, blue: 0.22, alpha: 0.95),
        statusStrokeColor: ThemeColor(red: 0.35, green: 0.35, blue: 0.38, alpha: 0.8),
        statusTextColor: ThemeColor(red: 0.90, green: 0.90, blue: 0.92, alpha: 1.0),
        buttonBackgroundColor: ThemeColor(red: 0.20, green: 0.20, blue: 0.22, alpha: 0.95),
        buttonStrokeColor: ThemeColor(red: 0.35, green: 0.35, blue: 0.38, alpha: 0.8),
        buttonTextColor: ThemeColor(red: 0.90, green: 0.90, blue: 0.92, alpha: 1.0)
    )

    /// Ocean blue theme
    static let ocean = BoardTheme(
        id: "ocean",
        name: "Ocean",
        price: 100,
        boardColor: ThemeColor(red: 0.20, green: 0.35, blue: 0.45, alpha: 0.98),
        boardStrokeColor: ThemeColor(red: 0.15, green: 0.28, blue: 0.38, alpha: 0.8),
        innerBoardColor: ThemeColor(red: 0.30, green: 0.48, blue: 0.58, alpha: 1.0),
        innerBoardStrokeColor: ThemeColor(red: 0.22, green: 0.40, blue: 0.50, alpha: 0.6),
        gridLineColor: ThemeColor(red: 0.15, green: 0.30, blue: 0.40, alpha: 0.5),
        starPointColor: ThemeColor(red: 0.12, green: 0.25, blue: 0.35, alpha: 0.7),
        backgroundGradient: GradientColors(
            topColor: ThemeColor(red: 0.55, green: 0.78, blue: 0.88, alpha: 1.0),
            midColor: ThemeColor(red: 0.35, green: 0.60, blue: 0.75, alpha: 1.0),
            bottomColor: ThemeColor(red: 0.20, green: 0.42, blue: 0.58, alpha: 1.0)
        ),
        decorativeCircleColors: [
            ThemeColor(red: 0.40, green: 0.65, blue: 0.80, alpha: 0.2),
            ThemeColor(red: 0.30, green: 0.55, blue: 0.72, alpha: 0.15),
            ThemeColor(red: 0.45, green: 0.70, blue: 0.85, alpha: 0.18)
        ],
        blackStoneColor: ThemeColor(red: 0.08, green: 0.15, blue: 0.22, alpha: 1.0),
        blackStoneHighlight: ThemeColor(red: 0.25, green: 0.35, blue: 0.45, alpha: 1.0),
        whiteStoneColor: ThemeColor(red: 0.92, green: 0.96, blue: 0.98, alpha: 1.0),
        whiteStoneHighlight: ThemeColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),
        stoneStyle: .glossy,
        statusBackgroundColor: ThemeColor(red: 0.88, green: 0.94, blue: 0.98, alpha: 0.95),
        statusStrokeColor: ThemeColor(red: 0.40, green: 0.60, blue: 0.72, alpha: 0.8),
        statusTextColor: ThemeColor(red: 0.15, green: 0.30, blue: 0.40, alpha: 1.0),
        buttonBackgroundColor: ThemeColor(red: 0.88, green: 0.94, blue: 0.98, alpha: 0.95),
        buttonStrokeColor: ThemeColor(red: 0.40, green: 0.60, blue: 0.72, alpha: 0.8),
        buttonTextColor: ThemeColor(red: 0.15, green: 0.30, blue: 0.40, alpha: 1.0)
    )

    /// Marble elegance theme
    static let marble = BoardTheme(
        id: "marble",
        name: "Marble",
        price: 150,
        boardColor: ThemeColor(red: 0.75, green: 0.75, blue: 0.78, alpha: 0.98),
        boardStrokeColor: ThemeColor(red: 0.60, green: 0.60, blue: 0.62, alpha: 0.8),
        innerBoardColor: ThemeColor(red: 0.92, green: 0.92, blue: 0.94, alpha: 1.0),
        innerBoardStrokeColor: ThemeColor(red: 0.80, green: 0.80, blue: 0.82, alpha: 0.6),
        gridLineColor: ThemeColor(red: 0.55, green: 0.55, blue: 0.58, alpha: 0.4),
        starPointColor: ThemeColor(red: 0.45, green: 0.45, blue: 0.48, alpha: 0.6),
        backgroundGradient: GradientColors(
            topColor: ThemeColor(red: 0.95, green: 0.95, blue: 0.96, alpha: 1.0),
            midColor: ThemeColor(red: 0.88, green: 0.88, blue: 0.90, alpha: 1.0),
            bottomColor: ThemeColor(red: 0.82, green: 0.82, blue: 0.85, alpha: 1.0)
        ),
        decorativeCircleColors: [
            ThemeColor(red: 0.80, green: 0.80, blue: 0.85, alpha: 0.15),
            ThemeColor(red: 0.75, green: 0.78, blue: 0.82, alpha: 0.12),
            ThemeColor(red: 0.85, green: 0.85, blue: 0.88, alpha: 0.18)
        ],
        blackStoneColor: ThemeColor(red: 0.15, green: 0.15, blue: 0.18, alpha: 1.0),
        blackStoneHighlight: ThemeColor(red: 0.40, green: 0.40, blue: 0.45, alpha: 1.0),
        whiteStoneColor: ThemeColor(red: 0.98, green: 0.98, blue: 1.0, alpha: 1.0),
        whiteStoneHighlight: ThemeColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),
        stoneStyle: .glossy,
        statusBackgroundColor: ThemeColor(red: 0.96, green: 0.96, blue: 0.97, alpha: 0.95),
        statusStrokeColor: ThemeColor(red: 0.70, green: 0.70, blue: 0.72, alpha: 0.8),
        statusTextColor: ThemeColor(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0),
        buttonBackgroundColor: ThemeColor(red: 0.96, green: 0.96, blue: 0.97, alpha: 0.95),
        buttonStrokeColor: ThemeColor(red: 0.70, green: 0.70, blue: 0.72, alpha: 0.8),
        buttonTextColor: ThemeColor(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0)
    )

    /// Sakura cherry blossom theme
    static let sakura = BoardTheme(
        id: "sakura",
        name: "Sakura",
        price: 150,
        boardColor: ThemeColor(red: 0.55, green: 0.38, blue: 0.42, alpha: 0.98),
        boardStrokeColor: ThemeColor(red: 0.45, green: 0.30, blue: 0.35, alpha: 0.8),
        innerBoardColor: ThemeColor(red: 0.75, green: 0.58, blue: 0.62, alpha: 1.0),
        innerBoardStrokeColor: ThemeColor(red: 0.60, green: 0.45, blue: 0.50, alpha: 0.6),
        gridLineColor: ThemeColor(red: 0.45, green: 0.30, blue: 0.35, alpha: 0.5),
        starPointColor: ThemeColor(red: 0.40, green: 0.25, blue: 0.30, alpha: 0.7),
        backgroundGradient: GradientColors(
            topColor: ThemeColor(red: 0.98, green: 0.88, blue: 0.92, alpha: 1.0),
            midColor: ThemeColor(red: 0.95, green: 0.80, blue: 0.85, alpha: 1.0),
            bottomColor: ThemeColor(red: 0.90, green: 0.72, blue: 0.78, alpha: 1.0)
        ),
        decorativeCircleColors: [
            ThemeColor(red: 0.95, green: 0.75, blue: 0.82, alpha: 0.25),
            ThemeColor(red: 0.92, green: 0.70, blue: 0.78, alpha: 0.20),
            ThemeColor(red: 0.98, green: 0.80, blue: 0.85, alpha: 0.22)
        ],
        blackStoneColor: ThemeColor(red: 0.18, green: 0.12, blue: 0.15, alpha: 1.0),
        blackStoneHighlight: ThemeColor(red: 0.40, green: 0.30, blue: 0.35, alpha: 1.0),
        whiteStoneColor: ThemeColor(red: 0.98, green: 0.94, blue: 0.96, alpha: 1.0),
        whiteStoneHighlight: ThemeColor(red: 1.0, green: 0.98, blue: 1.0, alpha: 1.0),
        stoneStyle: .classic,
        statusBackgroundColor: ThemeColor(red: 0.98, green: 0.92, blue: 0.95, alpha: 0.95),
        statusStrokeColor: ThemeColor(red: 0.75, green: 0.58, blue: 0.65, alpha: 0.8),
        statusTextColor: ThemeColor(red: 0.40, green: 0.25, blue: 0.30, alpha: 1.0),
        buttonBackgroundColor: ThemeColor(red: 0.98, green: 0.92, blue: 0.95, alpha: 0.95),
        buttonStrokeColor: ThemeColor(red: 0.75, green: 0.58, blue: 0.65, alpha: 0.8),
        buttonTextColor: ThemeColor(red: 0.40, green: 0.25, blue: 0.30, alpha: 1.0)
    )

    /// Midnight purple/black theme with glowing stones
    static let midnight = BoardTheme(
        id: "midnight",
        name: "Midnight",
        price: 200,
        boardColor: ThemeColor(red: 0.12, green: 0.10, blue: 0.18, alpha: 0.98),
        boardStrokeColor: ThemeColor(red: 0.25, green: 0.20, blue: 0.35, alpha: 0.8),
        innerBoardColor: ThemeColor(red: 0.18, green: 0.15, blue: 0.28, alpha: 1.0),
        innerBoardStrokeColor: ThemeColor(red: 0.30, green: 0.25, blue: 0.42, alpha: 0.6),
        gridLineColor: ThemeColor(red: 0.40, green: 0.35, blue: 0.55, alpha: 0.5),
        starPointColor: ThemeColor(red: 0.50, green: 0.45, blue: 0.65, alpha: 0.7),
        backgroundGradient: GradientColors(
            topColor: ThemeColor(red: 0.08, green: 0.05, blue: 0.15, alpha: 1.0),
            midColor: ThemeColor(red: 0.12, green: 0.08, blue: 0.22, alpha: 1.0),
            bottomColor: ThemeColor(red: 0.06, green: 0.04, blue: 0.12, alpha: 1.0)
        ),
        decorativeCircleColors: [
            ThemeColor(red: 0.35, green: 0.25, blue: 0.55, alpha: 0.25),
            ThemeColor(red: 0.28, green: 0.20, blue: 0.48, alpha: 0.20),
            ThemeColor(red: 0.40, green: 0.30, blue: 0.60, alpha: 0.22)
        ],
        blackStoneColor: ThemeColor(red: 0.05, green: 0.03, blue: 0.10, alpha: 1.0),
        blackStoneHighlight: ThemeColor(red: 0.30, green: 0.25, blue: 0.45, alpha: 1.0),
        whiteStoneColor: ThemeColor(red: 0.85, green: 0.82, blue: 0.95, alpha: 1.0),
        whiteStoneHighlight: ThemeColor(red: 0.95, green: 0.92, blue: 1.0, alpha: 1.0),
        stoneStyle: .glossy,
        statusBackgroundColor: ThemeColor(red: 0.15, green: 0.12, blue: 0.25, alpha: 0.95),
        statusStrokeColor: ThemeColor(red: 0.35, green: 0.30, blue: 0.50, alpha: 0.8),
        statusTextColor: ThemeColor(red: 0.85, green: 0.82, blue: 0.95, alpha: 1.0),
        buttonBackgroundColor: ThemeColor(red: 0.15, green: 0.12, blue: 0.25, alpha: 0.95),
        buttonStrokeColor: ThemeColor(red: 0.35, green: 0.30, blue: 0.50, alpha: 0.8),
        buttonTextColor: ThemeColor(red: 0.85, green: 0.82, blue: 0.95, alpha: 1.0)
    )

    /// Christmas holiday theme with festive red and green
    static let christmas = BoardTheme(
        id: "christmas",
        name: "Christmas",
        price: 100,
        boardColor: ThemeColor(red: 0.18, green: 0.35, blue: 0.22, alpha: 0.98),        // Deep pine green
        boardStrokeColor: ThemeColor(red: 0.12, green: 0.25, blue: 0.15, alpha: 0.9),
        innerBoardColor: ThemeColor(red: 0.25, green: 0.45, blue: 0.30, alpha: 1.0),    // Forest green board
        innerBoardStrokeColor: ThemeColor(red: 0.65, green: 0.18, blue: 0.18, alpha: 0.7), // Red accent stroke
        gridLineColor: ThemeColor(red: 0.85, green: 0.75, blue: 0.55, alpha: 0.5),      // Gold grid lines
        starPointColor: ThemeColor(red: 0.90, green: 0.75, blue: 0.35, alpha: 0.9),     // Golden star points
        backgroundGradient: GradientColors(
            topColor: ThemeColor(red: 0.12, green: 0.22, blue: 0.28, alpha: 1.0),       // Night sky blue
            midColor: ThemeColor(red: 0.08, green: 0.15, blue: 0.20, alpha: 1.0),       // Darker night
            bottomColor: ThemeColor(red: 0.05, green: 0.10, blue: 0.12, alpha: 1.0)     // Deep night
        ),
        decorativeCircleColors: [
            ThemeColor(red: 0.75, green: 0.20, blue: 0.20, alpha: 0.20),                // Red ornament
            ThemeColor(red: 0.20, green: 0.50, blue: 0.28, alpha: 0.18),                // Green ornament
            ThemeColor(red: 0.90, green: 0.78, blue: 0.40, alpha: 0.15)                 // Gold ornament
        ],
        blackStoneColor: ThemeColor(red: 0.70, green: 0.15, blue: 0.15, alpha: 1.0),    // Christmas red stones
        blackStoneHighlight: ThemeColor(red: 0.90, green: 0.35, blue: 0.35, alpha: 1.0),
        whiteStoneColor: ThemeColor(red: 0.95, green: 0.97, blue: 0.98, alpha: 1.0),    // Snow white stones
        whiteStoneHighlight: ThemeColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),
        stoneStyle: .glossy,
        statusBackgroundColor: ThemeColor(red: 0.15, green: 0.28, blue: 0.18, alpha: 0.95),
        statusStrokeColor: ThemeColor(red: 0.70, green: 0.22, blue: 0.22, alpha: 0.8),  // Red border
        statusTextColor: ThemeColor(red: 0.95, green: 0.92, blue: 0.85, alpha: 1.0),    // Warm white text
        buttonBackgroundColor: ThemeColor(red: 0.70, green: 0.18, blue: 0.18, alpha: 0.95), // Red buttons
        buttonStrokeColor: ThemeColor(red: 0.85, green: 0.75, blue: 0.50, alpha: 0.8),  // Gold border
        buttonTextColor: ThemeColor(red: 0.98, green: 0.95, blue: 0.90, alpha: 1.0)
    )

    /// All available themes
    static let allThemes: [BoardTheme] = [
        .classic,
        .zen,
        .darkMode,
        .ocean,
        .marble,
        .sakura,
        .midnight,
        .christmas
    ]
}
