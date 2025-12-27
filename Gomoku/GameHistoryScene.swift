//
//  GameHistoryScene.swift
//  Gomoku
//
//  Displays a scrollable list of saved games for replay.
//

import SpriteKit

class GameHistoryScene: SKScene {

    // Theme reference
    private var theme: BoardTheme { ThemeManager.shared.currentTheme }
    private var isZenTheme: Bool { theme.id == "zen" }
    private var uiFont: String { isZenTheme ? "Hiragino Mincho ProN" : "AvenirNext-Medium" }

    // Theme-derived colors
    private var primaryTextColor: SKColor { theme.boardColor.skColor }
    private var secondaryTextColor: SKColor { theme.gridLineColor.skColor }
    private var accentColor: SKColor { theme.decorativeCircleColors.first?.skColor ?? SKColor.gray }

    // Scrolling
    private var scrollNode: SKNode!
    private var scrollOffset: CGFloat = 0
    private var maxScrollOffset: CGFloat = 0
    private var lastTouchY: CGFloat = 0
    private var isDragging = false

    // Game cards
    private var gameCards: [(id: UUID, node: SKNode)] = []

    override func didMove(to view: SKView) {
        setupBackground()
        setupDecorations()
        setupHeader()
        setupScrollableContent()
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
        let decorativeColors = theme.decorativeCircleColors

        if decorativeColors.count >= 2 {
            let circle1 = SKShapeNode(circleOfRadius: 100)
            circle1.fillColor = decorativeColors[0].skColor
            circle1.strokeColor = .clear
            circle1.position = CGPoint(x: size.width - 50, y: size.height - 80)
            circle1.zPosition = -90
            addChild(circle1)

            let circle2 = SKShapeNode(circleOfRadius: 60)
            circle2.fillColor = decorativeColors[1].skColor
            circle2.strokeColor = .clear
            circle2.position = CGPoint(x: 40, y: 120)
            circle2.zPosition = -90
            addChild(circle2)
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
        let titleLabel = SKLabelNode(fontNamed: uiFont)
        titleLabel.text = isZenTheme ? "対戦履歴" : "Game History"
        titleLabel.fontSize = 32
        titleLabel.fontColor = primaryTextColor
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height - 90)
        titleLabel.zPosition = 10
        addChild(titleLabel)

        if isZenTheme {
            let subtitle = SKLabelNode(fontNamed: uiFont)
            subtitle.text = "Game History"
            subtitle.fontSize = 14
            subtitle.fontColor = secondaryTextColor
            subtitle.position = CGPoint(x: size.width / 2, y: size.height - 115)
            subtitle.zPosition = 10
            addChild(subtitle)
        }

        // Decorative line
        let line = SKShapeNode(rectOf: CGSize(width: 40, height: 2), cornerRadius: 1)
        line.fillColor = accentColor.withAlphaComponent(0.5)
        line.strokeColor = .clear
        line.position = CGPoint(x: size.width / 2, y: size.height - (isZenTheme ? 140 : 120))
        line.zPosition = 10
        addChild(line)
    }

    private func setupScrollableContent() {
        // Create scroll container
        scrollNode = SKNode()
        scrollNode.position = CGPoint(x: 0, y: 0)
        scrollNode.zPosition = 5

        // Create mask for scroll area
        let maskHeight = size.height - 220  // Leave room for header and back button
        let maskNode = SKCropNode()
        let maskShape = SKShapeNode(rect: CGRect(x: 0, y: 130, width: size.width, height: maskHeight))
        maskShape.fillColor = .white
        maskNode.maskNode = maskShape
        maskNode.addChild(scrollNode)
        maskNode.zPosition = 5
        addChild(maskNode)

        // Add game cards
        let games = GameHistoryManager.shared.games
        let cardHeight: CGFloat = 100
        let spacing: CGFloat = 15
        let startY = size.height - 180

        for (index, game) in games.enumerated() {
            let cardY = startY - CGFloat(index) * (cardHeight + spacing)
            let cardNode = createGameCard(game: game, position: CGPoint(x: size.width / 2, y: cardY))
            scrollNode.addChild(cardNode)
            gameCards.append((id: game.id, node: cardNode))
        }

        // Calculate max scroll
        let contentHeight = CGFloat(games.count) * (cardHeight + spacing)
        let visibleHeight = maskHeight
        maxScrollOffset = max(0, contentHeight - visibleHeight + 50)
    }

    private func createGameCard(game: CompletedGame, position: CGPoint) -> SKNode {
        let cardWidth: CGFloat = 320
        let cardHeight: CGFloat = 100

        let container = SKNode()
        container.position = position
        container.name = "gameCard_\(game.id.uuidString)"

        // Card background
        let card = SKShapeNode(rectOf: CGSize(width: cardWidth, height: cardHeight), cornerRadius: 10)
        card.fillColor = SKColor.white.withAlphaComponent(0.8)
        card.strokeColor = accentColor.withAlphaComponent(0.2)
        card.lineWidth = 1
        card.name = container.name
        container.addChild(card)

        // Result indicator (left side color bar)
        let resultColor: SKColor
        switch game.winner {
        case .black:
            resultColor = SKColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        case .white:
            resultColor = SKColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
        case .none:
            resultColor = SKColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)
        }

        let resultBar = SKShapeNode(rectOf: CGSize(width: 4, height: cardHeight - 20), cornerRadius: 2)
        resultBar.fillColor = resultColor
        resultBar.strokeColor = resultColor == SKColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0) ? .gray : .clear
        resultBar.lineWidth = resultColor == SKColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0) ? 0.5 : 0
        resultBar.position = CGPoint(x: -cardWidth/2 + 12, y: 0)
        resultBar.name = container.name
        container.addChild(resultBar)

        // Mode label
        let modeLabel = SKLabelNode(fontNamed: uiFont)
        modeLabel.text = game.modeDescription
        modeLabel.fontSize = 16
        modeLabel.fontColor = primaryTextColor
        modeLabel.horizontalAlignmentMode = .left
        modeLabel.position = CGPoint(x: -cardWidth/2 + 28, y: 25)
        modeLabel.name = container.name
        container.addChild(modeLabel)

        // Result label (includes color info for AI games)
        let resultLabel = SKLabelNode(fontNamed: uiFont)
        if let colorInfo = game.colorDescription {
            resultLabel.text = "\(game.resultDescription) · \(colorInfo)"
        } else {
            resultLabel.text = game.resultDescription
        }
        resultLabel.fontSize = 13
        resultLabel.fontColor = secondaryTextColor
        resultLabel.horizontalAlignmentMode = .left
        resultLabel.position = CGPoint(x: -cardWidth/2 + 28, y: 4)
        resultLabel.name = container.name
        container.addChild(resultLabel)

        // Move count
        let movesLabel = SKLabelNode(fontNamed: uiFont)
        movesLabel.text = isZenTheme ? "\(game.moveCount) moves · \(game.moveCount)手" : "\(game.moveCount) moves"
        movesLabel.fontSize = 12
        movesLabel.fontColor = secondaryTextColor
        movesLabel.horizontalAlignmentMode = .left
        movesLabel.position = CGPoint(x: -cardWidth/2 + 28, y: -15)
        movesLabel.name = container.name
        container.addChild(movesLabel)

        // Date label
        let dateLabel = SKLabelNode(fontNamed: uiFont)
        dateLabel.text = game.dateDescription
        dateLabel.fontSize = 11
        dateLabel.fontColor = secondaryTextColor.withAlphaComponent(0.7)
        dateLabel.horizontalAlignmentMode = .left
        dateLabel.position = CGPoint(x: -cardWidth/2 + 28, y: -32)
        dateLabel.name = container.name
        container.addChild(dateLabel)

        // Play button
        let playButton = SKShapeNode(circleOfRadius: 22)
        playButton.fillColor = accentColor.withAlphaComponent(0.15)
        playButton.strokeColor = accentColor.withAlphaComponent(0.4)
        playButton.lineWidth = 1.5
        playButton.position = CGPoint(x: cardWidth/2 - 35, y: 0)
        playButton.name = container.name
        container.addChild(playButton)

        let playIcon = SKLabelNode(fontNamed: "AvenirNext-Bold")
        playIcon.text = "▶"
        playIcon.fontSize = 18
        playIcon.fontColor = accentColor
        playIcon.verticalAlignmentMode = .center
        playIcon.horizontalAlignmentMode = .center
        playIcon.position = CGPoint(x: cardWidth/2 - 33, y: 0)
        playIcon.name = container.name
        container.addChild(playIcon)

        return container
    }

    private func setupBackButton() {
        let container = SKNode()
        container.position = CGPoint(x: size.width / 2, y: 70)
        container.name = "backButton"
        container.zPosition = 20
        addChild(container)

        let bg = SKShapeNode(rectOf: CGSize(width: 200, height: 50), cornerRadius: 8)
        bg.fillColor = accentColor.withAlphaComponent(0.15)
        bg.strokeColor = accentColor.withAlphaComponent(0.3)
        bg.lineWidth = 1.5
        bg.name = "backButton"
        container.addChild(bg)

        let label = SKLabelNode(fontNamed: uiFont)
        label.text = isZenTheme ? "← Back · 戻る" : "← Back"
        label.fontSize = 16
        label.fontColor = primaryTextColor
        label.verticalAlignmentMode = .center
        label.name = "backButton"
        container.addChild(label)
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        lastTouchY = location.y
        isDragging = false

        let nodes = self.nodes(at: location)
        for node in nodes {
            if node.name == "backButton" {
                if let parent = node.parent, parent.name == "backButton" {
                    parent.run(SKAction.scale(to: 0.96, duration: 0.1))
                }
            }
            if let nodeName = node.name, nodeName.hasPrefix("gameCard_") {
                if let parent = node.parent, let parentName = parent.name, parentName.hasPrefix("gameCard_") {
                    parent.run(SKAction.scale(to: 0.97, duration: 0.1))
                }
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let deltaY = location.y - lastTouchY

        if abs(deltaY) > 5 {
            isDragging = true
        }

        if isDragging {
            scrollOffset -= deltaY
            scrollOffset = max(0, min(scrollOffset, maxScrollOffset))
            scrollNode.position.y = scrollOffset
            lastTouchY = location.y

            // Reset any pressed states when dragging
            for (_, node) in gameCards {
                node.run(SKAction.scale(to: 1.0, duration: 0.1))
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodes = self.nodes(at: location)

        if !isDragging {
            for node in nodes {
                if node.name == "backButton" {
                    SoundManager.shared.buttonTapped()
                    let transition = SKTransition.fade(withDuration: 0.4)
                    let statsScene = StatisticsScene(size: size)
                    statsScene.scaleMode = .aspectFill
                    view?.presentScene(statsScene, transition: transition)
                    return
                }

                if let nodeName = node.name, nodeName.hasPrefix("gameCard_") {
                    let uuidString = String(nodeName.dropFirst("gameCard_".count))
                    if let uuid = UUID(uuidString: uuidString),
                       let game = GameHistoryManager.shared.getGame(id: uuid) {
                        SoundManager.shared.buttonTapped()
                        let transition = SKTransition.fade(withDuration: 0.4)
                        let replayScene = ReplayScene(size: size, game: game)
                        replayScene.scaleMode = .aspectFill
                        view?.presentScene(replayScene, transition: transition)
                        return
                    }
                }
            }
        }

        // Reset scales
        for child in children where child.name == "backButton" {
            child.run(SKAction.scale(to: 1.0, duration: 0.1))
        }
        for (_, node) in gameCards {
            node.run(SKAction.scale(to: 1.0, duration: 0.1))
        }
    }
}
