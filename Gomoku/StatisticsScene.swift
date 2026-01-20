//
//  StatisticsScene.swift
//  Gomoku
//
//  Created by Brevin Blalock on 10/13/25.
//

import SpriteKit

class StatisticsScene: SKScene {

    // Theme reference
    private var theme: BoardTheme { ThemeManager.shared.currentTheme }
    private var isZenTheme: Bool { theme.id == "zen" }
    private var uiFont: String { isZenTheme ? "Hiragino Mincho ProN" : "AvenirNext-Medium" }

    // Theme-derived colors
    private var primaryTextColor: SKColor { theme.boardColor.skColor }
    private var secondaryTextColor: SKColor { theme.gridLineColor.skColor }
    private var accentColor: SKColor { theme.decorativeCircleColors.first?.skColor ?? SKColor.gray }
    private var secondaryAccent: SKColor { theme.decorativeCircleColors.count > 1 ? theme.decorativeCircleColors[1].skColor : accentColor }
    private var tertiaryAccent: SKColor { theme.decorativeCircleColors.count > 2 ? theme.decorativeCircleColors[2].skColor : accentColor }

    // Static accent colors for cards
    private let cardAccentGreen = SKColor(red: 0.45, green: 0.52, blue: 0.35, alpha: 1.0)
    private let cardAccentBrown = SKColor(red: 0.55, green: 0.40, blue: 0.28, alpha: 1.0)
    private let cardAccentRed = SKColor(red: 0.75, green: 0.22, blue: 0.17, alpha: 1.0)

    override func didMove(to view: SKView) {
        initializeFontScaling()
        setupBackground()
        setupDecorations()
        setupHeader()
        setupStatistics()
        setupBackButton()
    }

    private func setupBackground() {
        let topColor = theme.backgroundGradient.topColor.skColor
        let bottomColor = theme.backgroundGradient.bottomColor.skColor

        for i in 0..<6 {
            let progress = CGFloat(i) / 5.0
            let color = interpolateColor(from: topColor, to: bottomColor, progress: progress)
            let height = size.height / 6
            let rect = SKShapeNode(rect: CGRect(x: 0, y: CGFloat(5 - i) * height, width: size.width, height: height + 1))
            rect.fillColor = color
            rect.strokeColor = .clear
            rect.zPosition = -100
            addChild(rect)
        }
    }

    private func setupDecorations() {
        if isZenTheme {
            setupZenDecorations()
        } else {
            setupSimpleDecorations()
        }
    }

    private func setupZenDecorations() {
        // Subtle grid pattern (washi paper texture)
        let gridAlpha: CGFloat = 0.03
        for i in stride(from: CGFloat(40), to: size.width, by: 40) {
            let line = SKShapeNode(rectOf: CGSize(width: 1, height: size.height))
            line.fillColor = primaryTextColor.withAlphaComponent(gridAlpha)
            line.strokeColor = .clear
            line.position = CGPoint(x: i, y: size.height / 2)
            line.zPosition = -95
            addChild(line)
        }
        for i in stride(from: CGFloat(40), to: size.height, by: 40) {
            let line = SKShapeNode(rectOf: CGSize(width: size.width, height: 1))
            line.fillColor = primaryTextColor.withAlphaComponent(gridAlpha)
            line.strokeColor = .clear
            line.position = CGPoint(x: size.width / 2, y: i)
            line.zPosition = -95
            addChild(line)
        }

        // Ink wash decoration
        let circle = SKShapeNode(circleOfRadius: 120)
        circle.fillColor = primaryTextColor.withAlphaComponent(0.03)
        circle.strokeColor = .clear
        circle.position = CGPoint(x: size.width - 60, y: size.height - 100)
        circle.zPosition = -90
        addChild(circle)
    }

    private func setupSimpleDecorations() {
        // Simple decorative circles using theme colors
        let decorativeColors = theme.decorativeCircleColors

        if decorativeColors.count >= 3 {
            let circle1 = SKShapeNode(circleOfRadius: 120)
            circle1.fillColor = decorativeColors[0].skColor
            circle1.strokeColor = .clear
            circle1.position = CGPoint(x: size.width - 60, y: size.height - 100)
            circle1.zPosition = -90
            addChild(circle1)

            let circle2 = SKShapeNode(circleOfRadius: 80)
            circle2.fillColor = decorativeColors[1].skColor
            circle2.strokeColor = .clear
            circle2.position = CGPoint(x: 50, y: 150)
            circle2.zPosition = -90
            addChild(circle2)

            let circle3 = SKShapeNode(circleOfRadius: 60)
            circle3.fillColor = decorativeColors[2].skColor
            circle3.strokeColor = .clear
            circle3.position = CGPoint(x: size.width - 100, y: 350)
            circle3.zPosition = -90
            addChild(circle3)
        }
    }

    private func interpolateColor(from: SKColor, to: SKColor, progress: CGFloat) -> SKColor {
        var fromR: CGFloat = 0, fromG: CGFloat = 0, fromB: CGFloat = 0, fromA: CGFloat = 0
        var toR: CGFloat = 0, toG: CGFloat = 0, toB: CGFloat = 0, toA: CGFloat = 0
        from.getRed(&fromR, green: &fromG, blue: &fromB, alpha: &fromA)
        to.getRed(&toR, green: &toG, blue: &toB, alpha: &toA)
        return SKColor(
            red: fromR + (toR - fromR) * progress,
            green: fromG + (toG - fromG) * progress,
            blue: fromB + (toB - fromB) * progress,
            alpha: 1.0
        )
    }

    private func setupHeader() {
        // Title
        let titleLabel = SKLabelNode(fontNamed: uiFont)
        titleLabel.text = isZenTheme ? "統計" : "Statistics"
        titleLabel.fontSize = fontSize(.largeTitle)
        titleLabel.fontColor = primaryTextColor
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height - 100)
        titleLabel.zPosition = 10
        addChild(titleLabel)

        // Subtitle (only for Zen theme)
        if isZenTheme {
            let subtitle = SKLabelNode(fontNamed: uiFont)
            subtitle.text = "Statistics"
            subtitle.fontSize = fontSize(.headline)
            subtitle.fontColor = secondaryTextColor
            subtitle.position = CGPoint(x: size.width / 2, y: size.height - 130)
            subtitle.zPosition = 10
            addChild(subtitle)
        }

        // Decorative line
        let line = SKShapeNode(rectOf: CGSize(width: 50, height: 2), cornerRadius: 1)
        line.fillColor = accentColor.withAlphaComponent(0.5)
        line.strokeColor = .clear
        line.position = CGPoint(x: size.width / 2, y: size.height - (isZenTheme ? 155 : 135))
        line.zPosition = 10
        addChild(line)
    }

    private func setupStatistics() {
        let stats = StatisticsManager.shared.stats
        let startY = size.height - 200
        let spacing: CGFloat = 155

        // VS AI Card
        createStatsCard(
            title: isZenTheme ? "対AI戦" : "VS AI",
            subtitle: isZenTheme ? "VS AI" : nil,
            stats: isZenTheme ? [
                ("Total Games · 総対戦", "\(stats.aiWins + stats.aiLosses)"),
                ("Wins · 勝利", "\(stats.aiWins)"),
                ("Losses · 敗北", "\(stats.aiLosses)"),
                ("Win Rate · 勝率", String(format: "%.1f%%", stats.aiWinRate))
            ] : [
                ("Total Games", "\(stats.aiWins + stats.aiLosses)"),
                ("Wins", "\(stats.aiWins)"),
                ("Losses", "\(stats.aiLosses)"),
                ("Win Rate", String(format: "%.1f%%", stats.aiWinRate))
            ],
            position: CGPoint(x: size.width / 2, y: startY),
            accentColor: cardAccentGreen
        )

        // VS Friend Card
        createStatsCard(
            title: isZenTheme ? "二人対戦" : "VS Friend",
            subtitle: isZenTheme ? "VS Friend" : nil,
            stats: isZenTheme ? [
                ("Total Games · 総対戦", "\(stats.friendGamesPlayed)"),
                ("Black Wins · 黒勝利", "\(stats.blackWins)"),
                ("White Wins · 白勝利", "\(stats.whiteWins)")
            ] : [
                ("Total Games", "\(stats.friendGamesPlayed)"),
                ("Black Wins", "\(stats.blackWins)"),
                ("White Wins", "\(stats.whiteWins)")
            ],
            position: CGPoint(x: size.width / 2, y: startY - spacing),
            accentColor: cardAccentBrown
        )

        // Overall Card
        createStatsCard(
            title: isZenTheme ? "総合" : "Overall",
            subtitle: isZenTheme ? "Overall" : nil,
            stats: isZenTheme ? [
                ("All Games · 全対戦", "\(stats.totalGames)"),
                ("Best Streak · 最高連勝", "\(stats.bestWinStreak)"),
                ("Fastest Win · 最速勝利", stats.fastestWin > 0 ? "\(stats.fastestWin)" : "—")
            ] : [
                ("All Games", "\(stats.totalGames)"),
                ("Best Streak", "\(stats.bestWinStreak)"),
                ("Fastest Win", stats.fastestWin > 0 ? "\(stats.fastestWin) moves" : "—")
            ],
            position: CGPoint(x: size.width / 2, y: startY - spacing * 2),
            accentColor: cardAccentRed
        )

        // Game History Card
        setupGameHistoryCard(position: CGPoint(x: size.width / 2, y: startY - spacing * 3))
    }

    private func setupGameHistoryCard(position: CGPoint) {
        let cardWidth: CGFloat = 320
        let cardHeight: CGFloat = 60

        // Card container (for touch handling)
        let container = SKNode()
        container.position = position
        container.name = "historyCard"
        container.zPosition = 5
        addChild(container)

        // Card background
        let card = SKShapeNode(rectOf: CGSize(width: cardWidth, height: cardHeight), cornerRadius: 8)
        card.fillColor = SKColor.white.withAlphaComponent(0.7)
        card.strokeColor = accentColor.withAlphaComponent(0.3)
        card.lineWidth = 1
        card.name = "historyCard"
        container.addChild(card)

        // Accent line on left
        let accent = SKShapeNode(rectOf: CGSize(width: 3, height: cardHeight - 16), cornerRadius: 1.5)
        accent.fillColor = tertiaryAccent
        accent.strokeColor = .clear
        accent.position = CGPoint(x: -cardWidth/2 + 10, y: 0)
        accent.name = "historyCard"
        container.addChild(accent)

        // Title
        let titleLabel = SKLabelNode(fontNamed: uiFont)
        titleLabel.text = isZenTheme ? "対戦履歴" : "Game History"
        titleLabel.fontSize = fontSize(.headline)
        titleLabel.fontColor = primaryTextColor
        titleLabel.horizontalAlignmentMode = .left
        titleLabel.verticalAlignmentMode = .center
        titleLabel.position = CGPoint(x: -cardWidth/2 + 24, y: 6)
        titleLabel.name = "historyCard"
        container.addChild(titleLabel)

        // Subtitle with game count
        let gameCount = GameHistoryManager.shared.gameCount
        let subtitleLabel = SKLabelNode(fontNamed: uiFont)
        subtitleLabel.text = isZenTheme ? "\(gameCount) games saved · \(gameCount)試合保存" : "\(gameCount) games saved"
        subtitleLabel.fontSize = fontSize(.footnote)
        subtitleLabel.fontColor = secondaryTextColor
        subtitleLabel.horizontalAlignmentMode = .left
        subtitleLabel.verticalAlignmentMode = .center
        subtitleLabel.position = CGPoint(x: -cardWidth/2 + 24, y: -12)
        subtitleLabel.name = "historyCard"
        container.addChild(subtitleLabel)

        // View button (if games exist)
        if gameCount > 0 {
            let viewLabel = SKLabelNode(fontNamed: uiFont)
            viewLabel.text = isZenTheme ? "View ▶" : "View ▶"
            viewLabel.fontSize = fontSize(.callout)
            viewLabel.fontColor = accentColor
            viewLabel.horizontalAlignmentMode = .right
            viewLabel.verticalAlignmentMode = .center
            viewLabel.position = CGPoint(x: cardWidth/2 - 16, y: 0)
            viewLabel.name = "historyCard"
            container.addChild(viewLabel)
        }
    }

    private func createStatsCard(title: String, subtitle: String?, stats: [(String, String)], position: CGPoint, accentColor cardAccent: SKColor) {
        let cardHeight: CGFloat = (subtitle != nil ? 50 : 40) + CGFloat(stats.count) * 28
        let cardWidth: CGFloat = 320

        // Card background
        let card = SKShapeNode(rectOf: CGSize(width: cardWidth, height: cardHeight), cornerRadius: 8)
        card.fillColor = SKColor.white.withAlphaComponent(0.7)
        card.strokeColor = accentColor.withAlphaComponent(0.3)
        card.lineWidth = 1
        card.position = position
        card.zPosition = 5
        addChild(card)

        // Accent line on left
        let accent = SKShapeNode(rectOf: CGSize(width: 3, height: cardHeight - 16), cornerRadius: 1.5)
        accent.fillColor = cardAccent
        accent.strokeColor = .clear
        accent.position = CGPoint(x: position.x - cardWidth/2 + 10, y: position.y)
        accent.zPosition = 6
        addChild(accent)

        // Title
        let titleLabel = SKLabelNode(fontNamed: uiFont)
        titleLabel.text = title
        titleLabel.fontSize = fontSize(.headline)
        titleLabel.fontColor = primaryTextColor
        titleLabel.horizontalAlignmentMode = .left
        titleLabel.position = CGPoint(x: position.x - cardWidth/2 + 24, y: position.y + cardHeight/2 - 28)
        titleLabel.zPosition = 6
        addChild(titleLabel)

        // Subtitle (if provided)
        var statsStartOffset: CGFloat = 65
        if let subtitle = subtitle {
            let subtitleLabel = SKLabelNode(fontNamed: uiFont)
            subtitleLabel.text = subtitle
            subtitleLabel.fontSize = fontSize(.caption)
            subtitleLabel.fontColor = secondaryTextColor
            subtitleLabel.horizontalAlignmentMode = .left
            subtitleLabel.position = CGPoint(x: position.x - cardWidth/2 + 24, y: position.y + cardHeight/2 - 44)
            subtitleLabel.zPosition = 6
            addChild(subtitleLabel)
            statsStartOffset = 75
        }

        // Stats rows
        for (index, (label, value)) in stats.enumerated() {
            let yOffset = position.y + cardHeight/2 - statsStartOffset - CGFloat(index) * 28

            let statLabel = SKLabelNode(fontNamed: uiFont)
            statLabel.text = label
            statLabel.fontSize = fontSize(.footnote)
            statLabel.fontColor = secondaryTextColor
            statLabel.horizontalAlignmentMode = .left
            statLabel.position = CGPoint(x: position.x - cardWidth/2 + 24, y: yOffset)
            statLabel.zPosition = 6
            addChild(statLabel)

            let valueLabel = SKLabelNode(fontNamed: uiFont)
            valueLabel.text = value
            valueLabel.fontSize = fontSize(.callout)
            valueLabel.fontColor = primaryTextColor
            valueLabel.horizontalAlignmentMode = .right
            valueLabel.position = CGPoint(x: position.x + cardWidth/2 - 16, y: yOffset)
            valueLabel.zPosition = 6
            addChild(valueLabel)
        }
    }

    private func setupBackButton() {
        let container = SKNode()
        container.position = CGPoint(x: size.width / 2, y: 70)
        container.name = "backButton"
        container.zPosition = 10
        addChild(container)

        let bg = SKShapeNode(rectOf: CGSize(width: 200, height: 50), cornerRadius: 8)
        bg.fillColor = accentColor.withAlphaComponent(0.15)
        bg.strokeColor = accentColor.withAlphaComponent(0.3)
        bg.lineWidth = 1.5
        bg.name = "backButton"
        container.addChild(bg)

        let label = SKLabelNode(fontNamed: uiFont)
        label.text = isZenTheme ? "← Back · 戻る" : "← Back"
        label.fontSize = fontSize(.headline)
        label.fontColor = primaryTextColor
        label.verticalAlignmentMode = .center
        label.name = "backButton"
        container.addChild(label)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let nodes = self.nodes(at: touch.location(in: self))

        for node in nodes {
            if node.name == "backButton" {
                if let parent = node.parent, parent.zPosition == 10 {
                    parent.run(SKAction.scale(to: 0.96, duration: 0.1))
                }
            }
            if node.name == "historyCard" {
                if let parent = node.parent, parent.name == "historyCard" {
                    parent.run(SKAction.scale(to: 0.96, duration: 0.1))
                }
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let nodes = self.nodes(at: touch.location(in: self))

        for node in nodes {
            if node.name == "backButton" {
                SoundManager.shared.buttonTapped()
                let transition = SKTransition.fade(withDuration: 0.4)
                let menuScene = MenuScene(size: size)
                menuScene.scaleMode = .aspectFill
                view?.presentScene(menuScene, transition: transition)
                return
            }
            if node.name == "historyCard" && GameHistoryManager.shared.hasGames {
                SoundManager.shared.buttonTapped()
                let transition = SKTransition.fade(withDuration: 0.4)
                let historyScene = GameHistoryScene(size: size)
                historyScene.scaleMode = .aspectFill
                view?.presentScene(historyScene, transition: transition)
                return
            }
        }

        // Reset scales
        for child in children where child.zPosition == 10 || child.name == "historyCard" {
            child.run(SKAction.scale(to: 1.0, duration: 0.1))
        }
    }
}
