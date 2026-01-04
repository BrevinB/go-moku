//
//  HowToPlayScene.swift
//  Gomoku
//
//  Tutorial scene explaining Gomoku rules for new players.
//

import SpriteKit

class HowToPlayScene: SKScene {

    // Theme reference
    private var theme: BoardTheme { ThemeManager.shared.currentTheme }
    private var isZenTheme: Bool { theme.id == "zen" }
    private var uiFont: String { isZenTheme ? "Hiragino Mincho ProN" : "AvenirNext-Medium" }
    private var uiFontBold: String { isZenTheme ? "Hiragino Mincho ProN" : "AvenirNext-DemiBold" }

    // Theme-derived colors - using higher contrast colors for readability
    private var primaryTextColor: SKColor {
        // Use a darker color for primary text
        SKColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
    }
    private var secondaryTextColor: SKColor {
        // Darker secondary text for better readability
        SKColor(red: 0.35, green: 0.35, blue: 0.35, alpha: 1.0)
    }
    private var accentColor: SKColor {
        SKColor(red: 0.45, green: 0.52, blue: 0.35, alpha: 1.0) // Bamboo green
    }
    private var cardBackgroundColor: SKColor {
        SKColor.white.withAlphaComponent(0.85)
    }

    // Scrolling
    private var scrollNode: SKNode!
    private var scrollOffset: CGFloat = 0
    private var maxScrollOffset: CGFloat = 0
    private var lastTouchY: CGFloat = 0
    private var isDragging = false

    // Page indicator
    private var currentPage: Int = 0
    private let totalPages = 4

    override func didMove(to view: SKView) {
        setupBackground()
        setupDecorations()
        setupHeader()
        setupScrollableContent()
        setupBackButton()
        setupPageIndicator()
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
            circle1.fillColor = decorativeColors[0].skColor.withAlphaComponent(0.08)
            circle1.strokeColor = .clear
            circle1.position = CGPoint(x: size.width - 50, y: size.height - 120)
            circle1.zPosition = -90
            addChild(circle1)

            let circle2 = SKShapeNode(circleOfRadius: 70)
            circle2.fillColor = decorativeColors[1].skColor.withAlphaComponent(0.06)
            circle2.strokeColor = .clear
            circle2.position = CGPoint(x: 40, y: 150)
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
        let titleLabel = SKLabelNode(fontNamed: uiFontBold)
        titleLabel.text = isZenTheme ? "遊び方" : "How to Play"
        titleLabel.fontSize = 32
        titleLabel.fontColor = primaryTextColor
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height - 100)
        titleLabel.zPosition = 20
        addChild(titleLabel)

        if isZenTheme {
            let subtitle = SKLabelNode(fontNamed: uiFont)
            subtitle.text = "How to Play"
            subtitle.fontSize = 14
            subtitle.fontColor = secondaryTextColor
            subtitle.position = CGPoint(x: size.width / 2, y: size.height - 125)
            subtitle.zPosition = 20
            addChild(subtitle)
        }

        // Decorative line
        let line = SKShapeNode(rectOf: CGSize(width: 50, height: 2), cornerRadius: 1)
        line.fillColor = accentColor.withAlphaComponent(0.5)
        line.strokeColor = .clear
        line.position = CGPoint(x: size.width / 2, y: size.height - (isZenTheme ? 145 : 130))
        line.zPosition = 20
        addChild(line)
    }

    private func setupScrollableContent() {
        scrollNode = SKNode()
        scrollNode.position = CGPoint(x: 0, y: 0)
        scrollNode.zPosition = 5

        // Create mask for scroll area
        let headerHeight: CGFloat = isZenTheme ? 160 : 145
        let footerHeight: CGFloat = 130
        let maskHeight = size.height - headerHeight - footerHeight

        let maskNode = SKCropNode()
        let maskShape = SKShapeNode(rect: CGRect(x: 0, y: footerHeight, width: size.width, height: maskHeight))
        maskShape.fillColor = .white
        maskNode.maskNode = maskShape
        maskNode.addChild(scrollNode)
        maskNode.zPosition = 5
        addChild(maskNode)

        var currentY = size.height - headerHeight - 30

        // Section 1: The Goal
        currentY = addSection(
            title: isZenTheme ? "目標 · The Goal" : "The Goal",
            content: "Get five of your stones in a row to win!\nThe row can be horizontal, vertical, or diagonal.",
            yPosition: currentY
        )

        // Visual: 5 in a row example
        currentY = addWinningExampleBoard(yPosition: currentY - 20)

        currentY -= 40

        // Section 2: Taking Turns
        currentY = addSection(
            title: isZenTheme ? "順番 · Taking Turns" : "Taking Turns",
            content: "Black always plays first.\nPlayers take turns placing one stone at a time.\nOnce placed, stones cannot be moved.",
            yPosition: currentY
        )

        currentY -= 20

        // Visual: Turn indicator
        currentY = addTurnExample(yPosition: currentY)

        currentY -= 40

        // Section 3: Opening Strategy
        currentY = addSection(
            title: isZenTheme ? "序盤戦略 · Opening Strategy" : "Opening Strategy",
            content: "The first few moves set the foundation for victory.",
            yPosition: currentY
        )

        currentY -= 10
        currentY = addOpeningExample(yPosition: currentY)

        currentY -= 30

        currentY = addTip(
            number: 1,
            text: "Start in the center - maximum winning directions",
            yPosition: currentY
        )
        currentY = addTip(
            number: 2,
            text: "As White, play adjacent to Black's first stone",
            yPosition: currentY
        )
        currentY = addTip(
            number: 3,
            text: "Build diagonally - harder for opponents to read",
            yPosition: currentY
        )

        currentY -= 40

        // Section 4: Key Patterns
        currentY = addSection(
            title: isZenTheme ? "重要な形 · Key Patterns" : "Key Patterns to Know",
            content: "",
            yPosition: currentY
        )

        currentY -= 10
        currentY = addKeyPattern(
            name: isZenTheme ? "活三 · Open Three" : "Open Three",
            description: "Three in a row with BOTH ends open.",
            pattern: [(-1, 0), (0, 0), (1, 0)],
            openEnds: [(-2, 0), (2, 0)],
            yPosition: currentY
        )

        currentY -= 20
        currentY = addKeyPattern(
            name: isZenTheme ? "活四 · Open Four" : "Open Four",
            description: "Four in a row with an open end = guaranteed win!",
            pattern: [(-1.5, 0), (-0.5, 0), (0.5, 0), (1.5, 0)],
            openEnds: [(-2.5, 0), (2.5, 0)],
            yPosition: currentY
        )

        currentY -= 20
        currentY = addKeyPattern(
            name: isZenTheme ? "死四 · Closed Four" : "Closed Four",
            description: "Four in a row but blocked on one end.",
            pattern: [(-1.5, 0), (-0.5, 0), (0.5, 0), (1.5, 0)],
            openEnds: [(2.5, 0)],
            blockedEnds: [(-2.5, 0)],
            yPosition: currentY
        )

        currentY -= 40

        // Section 5: Defensive Tactics
        currentY = addSection(
            title: isZenTheme ? "防御戦術 · Defense" : "Defensive Tactics",
            content: "",
            yPosition: currentY
        )

        currentY -= 10
        currentY = addTip(
            number: 1,
            text: "Always block an Open Four - or you lose next turn!",
            yPosition: currentY
        )
        currentY = addTip(
            number: 2,
            text: "Block Open Threes before they become Open Fours",
            yPosition: currentY
        )
        currentY = addTip(
            number: 3,
            text: "Watch for diagonal threats - easy to miss!",
            yPosition: currentY
        )

        currentY -= 30
        currentY = addBlockingExample(yPosition: currentY)

        currentY -= 40

        // Section 6: Advanced - Double Threats
        currentY = addSection(
            title: isZenTheme ? "必勝法 · Winning Tactics" : "Advanced: Double Threats",
            content: "",
            yPosition: currentY
        )

        currentY -= 10
        currentY = addDoubleThreatExample(yPosition: currentY)

        currentY -= 20
        currentY = addTip(
            number: 1,
            text: "Create TWO Open Threes at once (a \"fork\")",
            yPosition: currentY
        )
        currentY = addTip(
            number: 2,
            text: "Opponent can only block one - you win with the other!",
            yPosition: currentY
        )
        currentY = addTip(
            number: 3,
            text: "Look for L-shapes and T-shapes to set up forks",
            yPosition: currentY
        )

        currentY -= 40

        // Section 7: Winning Patterns
        currentY = addSection(
            title: isZenTheme ? "勝ちパターン · Winning Patterns" : "Winning Patterns",
            content: "Three ways to get five in a row:",
            yPosition: currentY
        )

        currentY -= 10
        currentY = addPatternRow(
            patterns: ["Horizontal", "Vertical", "Diagonal"],
            yPosition: currentY
        )

        currentY -= 40

        // Quick Reference
        currentY = addSection(
            title: isZenTheme ? "早見表 · Quick Reference" : "Quick Reference",
            content: "",
            yPosition: currentY
        )

        currentY -= 10
        currentY = addQuickRef(
            term: isZenTheme ? "活三 (Open 3)" : "Open Three",
            meaning: "3 stones, both ends open → Very dangerous",
            yPosition: currentY
        )
        currentY = addQuickRef(
            term: isZenTheme ? "活四 (Open 4)" : "Open Four",
            meaning: "4 stones, one end open → Wins next move",
            yPosition: currentY
        )
        currentY = addQuickRef(
            term: isZenTheme ? "四三 (4-3)" : "Fork (4-3)",
            meaning: "Open 4 + Open 3 → Unstoppable",
            yPosition: currentY
        )
        currentY = addQuickRef(
            term: isZenTheme ? "三三 (3-3)" : "Double Three",
            meaning: "Two Open 3s → Usually wins",
            yPosition: currentY
        )

        currentY -= 50

        // Ready to play message
        let readyLabel = SKLabelNode(fontNamed: uiFontBold)
        readyLabel.text = isZenTheme ? "準備完了！" : "You're ready to play!"
        readyLabel.fontSize = 20
        readyLabel.fontColor = accentColor
        readyLabel.position = CGPoint(x: size.width / 2, y: currentY)
        scrollNode.addChild(readyLabel)

        currentY -= 30

        let subReadyLabel = SKLabelNode(fontNamed: uiFont)
        subReadyLabel.text = isZenTheme ? "Good luck! · 頑張って！" : "Good luck and have fun!"
        subReadyLabel.fontSize = 14
        subReadyLabel.fontColor = secondaryTextColor
        subReadyLabel.position = CGPoint(x: size.width / 2, y: currentY)
        scrollNode.addChild(subReadyLabel)

        currentY -= 50

        // Calculate max scroll
        let visibleBottomY = footerHeight
        let lowestContentY = currentY
        maxScrollOffset = max(0, visibleBottomY - lowestContentY + 60)
    }

    private func addSection(title: String, content: String, yPosition: CGFloat) -> CGFloat {
        var currentY = yPosition

        // Section title with accent underline
        let titleLabel = SKLabelNode(fontNamed: uiFontBold)
        titleLabel.text = title
        titleLabel.fontSize = 22
        titleLabel.fontColor = primaryTextColor
        titleLabel.position = CGPoint(x: size.width / 2, y: currentY)
        titleLabel.zPosition = 10
        scrollNode.addChild(titleLabel)

        // Underline accent
        let underline = SKShapeNode(rectOf: CGSize(width: 40, height: 3), cornerRadius: 1.5)
        underline.fillColor = accentColor
        underline.strokeColor = .clear
        underline.position = CGPoint(x: size.width / 2, y: currentY - 18)
        underline.zPosition = 10
        scrollNode.addChild(underline)

        currentY -= 45

        if !content.isEmpty {
            let lines = content.components(separatedBy: "\n")
            for line in lines {
                let contentLabel = SKLabelNode(fontNamed: uiFont)
                contentLabel.text = line
                contentLabel.fontSize = 15
                contentLabel.fontColor = secondaryTextColor
                contentLabel.position = CGPoint(x: size.width / 2, y: currentY)
                contentLabel.zPosition = 10
                scrollNode.addChild(contentLabel)
                currentY -= 24
            }
        }

        return currentY
    }

    private func addTip(number: Int, text: String, yPosition: CGFloat) -> CGFloat {
        // Card background for tip
        let cardWidth: CGFloat = 320
        let cardHeight: CGFloat = 44

        let card = SKShapeNode(rectOf: CGSize(width: cardWidth, height: cardHeight), cornerRadius: 10)
        card.fillColor = cardBackgroundColor
        card.strokeColor = accentColor.withAlphaComponent(0.2)
        card.lineWidth = 1
        card.position = CGPoint(x: size.width / 2, y: yPosition)
        card.zPosition = 5
        scrollNode.addChild(card)

        // Number circle
        let circle = SKShapeNode(circleOfRadius: 14)
        circle.fillColor = accentColor
        circle.strokeColor = .clear
        circle.position = CGPoint(x: -cardWidth/2 + 24, y: 0)
        circle.zPosition = 1
        card.addChild(circle)

        let numLabel = SKLabelNode(fontNamed: uiFontBold)
        numLabel.text = "\(number)"
        numLabel.fontSize = 14
        numLabel.fontColor = .white
        numLabel.verticalAlignmentMode = .center
        numLabel.position = CGPoint(x: -cardWidth/2 + 24, y: 0)
        numLabel.zPosition = 2
        card.addChild(numLabel)

        // Tip text
        let tipLabel = SKLabelNode(fontNamed: uiFont)
        tipLabel.text = text
        tipLabel.fontSize = 14
        tipLabel.fontColor = primaryTextColor
        tipLabel.horizontalAlignmentMode = .left
        tipLabel.verticalAlignmentMode = .center
        tipLabel.position = CGPoint(x: -cardWidth/2 + 50, y: 0)
        tipLabel.zPosition = 1
        card.addChild(tipLabel)

        return yPosition - 52
    }

    private func addWinningExampleBoard(yPosition: CGFloat) -> CGFloat {
        let boardSize: CGFloat = 150
        let cellSize: CGFloat = boardSize / 6
        let centerY = yPosition - boardSize / 2 - 10
        let startX = size.width / 2 - boardSize / 2
        let startY = centerY - boardSize / 2

        // Card container for the board
        let cardPadding: CGFloat = 20
        let card = SKShapeNode(rectOf: CGSize(width: boardSize + cardPadding * 2, height: boardSize + cardPadding * 2 + 35), cornerRadius: 12)
        card.fillColor = cardBackgroundColor
        card.strokeColor = accentColor.withAlphaComponent(0.15)
        card.lineWidth = 1
        card.position = CGPoint(x: size.width / 2, y: centerY - 10)
        card.zPosition = 3
        scrollNode.addChild(card)

        // Draw mini board background
        let boardBg = SKShapeNode(rectOf: CGSize(width: boardSize + 10, height: boardSize + 10), cornerRadius: 6)
        boardBg.fillColor = theme.boardColor.skColor
        boardBg.strokeColor = SKColor.black.withAlphaComponent(0.15)
        boardBg.lineWidth = 1
        boardBg.position = CGPoint(x: size.width / 2, y: centerY)
        boardBg.zPosition = 4
        scrollNode.addChild(boardBg)

        // Draw grid lines
        for i in 0...5 {
            let x = startX + CGFloat(i) * cellSize
            let vLine = SKShapeNode(rectOf: CGSize(width: 1, height: boardSize))
            vLine.fillColor = SKColor.black.withAlphaComponent(0.25)
            vLine.strokeColor = .clear
            vLine.position = CGPoint(x: x, y: centerY)
            vLine.zPosition = 5
            scrollNode.addChild(vLine)

            let y = startY + CGFloat(i) * cellSize
            let hLine = SKShapeNode(rectOf: CGSize(width: boardSize, height: 1))
            hLine.fillColor = SKColor.black.withAlphaComponent(0.25)
            hLine.strokeColor = .clear
            hLine.position = CGPoint(x: size.width / 2, y: y)
            hLine.zPosition = 5
            scrollNode.addChild(hLine)
        }

        // Draw winning 5 in a row (diagonal)
        let stoneRadius: CGFloat = cellSize * 0.38
        for i in 0..<5 {
            let x = startX + (CGFloat(i) + 0.5) * cellSize
            let y = startY + (CGFloat(i) + 0.5) * cellSize

            let stone = SKShapeNode(circleOfRadius: stoneRadius)
            stone.fillColor = .black
            stone.strokeColor = SKColor.white.withAlphaComponent(0.3)
            stone.lineWidth = 1.5
            stone.position = CGPoint(x: x, y: y)
            stone.zPosition = 6
            scrollNode.addChild(stone)
        }

        // Draw winning line
        let lineStart = CGPoint(x: startX + 0.5 * cellSize, y: startY + 0.5 * cellSize)
        let lineEnd = CGPoint(x: startX + 4.5 * cellSize, y: startY + 4.5 * cellSize)

        let linePath = CGMutablePath()
        linePath.move(to: CGPoint(x: lineStart.x - size.width / 2, y: lineStart.y - centerY))
        linePath.addLine(to: CGPoint(x: lineEnd.x - size.width / 2, y: lineEnd.y - centerY))

        let winLine = SKShapeNode(path: linePath)
        winLine.strokeColor = SKColor(red: 0.85, green: 0.25, blue: 0.2, alpha: 0.9)
        winLine.lineWidth = 4
        winLine.lineCap = .round
        winLine.position = CGPoint(x: size.width / 2, y: centerY)
        winLine.zPosition = 7
        scrollNode.addChild(winLine)

        // Label below board (inside card)
        let label = SKLabelNode(fontNamed: uiFontBold)
        label.text = isZenTheme ? "五目で勝ち！" : "Five in a row wins!"
        label.fontSize = 14
        label.fontColor = accentColor
        label.position = CGPoint(x: size.width / 2, y: centerY - boardSize / 2 - 22)
        label.zPosition = 8
        scrollNode.addChild(label)

        return centerY - boardSize / 2 - 55
    }

    private func addTurnExample(yPosition: CGFloat) -> CGFloat {
        // Card background
        let cardWidth: CGFloat = 280
        let cardHeight: CGFloat = 90

        let card = SKShapeNode(rectOf: CGSize(width: cardWidth, height: cardHeight), cornerRadius: 12)
        card.fillColor = cardBackgroundColor
        card.strokeColor = accentColor.withAlphaComponent(0.15)
        card.lineWidth = 1
        card.position = CGPoint(x: size.width / 2, y: yPosition - 15)
        card.zPosition = 3
        scrollNode.addChild(card)

        // Black stone
        let blackStone = SKShapeNode(circleOfRadius: 22)
        blackStone.fillColor = .black
        blackStone.strokeColor = SKColor.white.withAlphaComponent(0.3)
        blackStone.lineWidth = 2
        blackStone.position = CGPoint(x: -70, y: 10)
        blackStone.zPosition = 1
        card.addChild(blackStone)

        let blackLabel = SKLabelNode(fontNamed: uiFontBold)
        blackLabel.text = isZenTheme ? "先手" : "First"
        blackLabel.fontSize = 13
        blackLabel.fontColor = primaryTextColor
        blackLabel.position = CGPoint(x: -70, y: -25)
        blackLabel.zPosition = 1
        card.addChild(blackLabel)

        // Arrow
        let arrow = SKLabelNode(fontNamed: uiFontBold)
        arrow.text = "→"
        arrow.fontSize = 28
        arrow.fontColor = accentColor
        arrow.verticalAlignmentMode = .center
        arrow.position = CGPoint(x: 0, y: 5)
        arrow.zPosition = 1
        card.addChild(arrow)

        // White stone
        let whiteStone = SKShapeNode(circleOfRadius: 22)
        whiteStone.fillColor = .white
        whiteStone.strokeColor = SKColor.black.withAlphaComponent(0.2)
        whiteStone.lineWidth = 2
        whiteStone.position = CGPoint(x: 70, y: 10)
        whiteStone.zPosition = 1
        card.addChild(whiteStone)

        let whiteLabel = SKLabelNode(fontNamed: uiFontBold)
        whiteLabel.text = isZenTheme ? "後手" : "Second"
        whiteLabel.fontSize = 13
        whiteLabel.fontColor = primaryTextColor
        whiteLabel.position = CGPoint(x: 70, y: -25)
        whiteLabel.zPosition = 1
        card.addChild(whiteLabel)

        return yPosition - 85
    }

    private func addPatternRow(patterns: [String], yPosition: CGFloat) -> CGFloat {
        // Card background for patterns
        let cardWidth: CGFloat = 340
        let cardHeight: CGFloat = 110

        let card = SKShapeNode(rectOf: CGSize(width: cardWidth, height: cardHeight), cornerRadius: 12)
        card.fillColor = cardBackgroundColor
        card.strokeColor = accentColor.withAlphaComponent(0.15)
        card.lineWidth = 1
        card.position = CGPoint(x: size.width / 2, y: yPosition - 35)
        card.zPosition = 3
        scrollNode.addChild(card)

        let spacing: CGFloat = 100
        let startX = -CGFloat(patterns.count - 1) * spacing / 2
        let miniSize: CGFloat = 55
        let cellSize: CGFloat = miniSize / 5

        for (index, pattern) in patterns.enumerated() {
            let x = startX + CGFloat(index) * spacing

            // Mini board
            let boardBg = SKShapeNode(rectOf: CGSize(width: miniSize + 8, height: miniSize + 8), cornerRadius: 4)
            boardBg.fillColor = theme.boardColor.skColor
            boardBg.strokeColor = SKColor.black.withAlphaComponent(0.15)
            boardBg.lineWidth = 1
            boardBg.position = CGPoint(x: x, y: 8)
            boardBg.zPosition = 1
            card.addChild(boardBg)

            // Draw pattern
            let stoneRadius: CGFloat = cellSize * 0.42
            for i in 0..<5 {
                var stoneX: CGFloat = 0
                var stoneY: CGFloat = 8

                switch pattern {
                case "Horizontal":
                    stoneX = x - miniSize / 2 + CGFloat(i) * cellSize + cellSize / 2
                    stoneY = 8
                case "Vertical":
                    stoneX = x
                    stoneY = 8 - miniSize / 2 + CGFloat(i) * cellSize + cellSize / 2
                case "Diagonal":
                    stoneX = x - miniSize / 2 + CGFloat(i) * cellSize + cellSize / 2
                    stoneY = 8 - miniSize / 2 + CGFloat(i) * cellSize + cellSize / 2
                default:
                    break
                }

                let stone = SKShapeNode(circleOfRadius: stoneRadius)
                stone.fillColor = .black
                stone.strokeColor = SKColor.white.withAlphaComponent(0.3)
                stone.lineWidth = 1
                stone.position = CGPoint(x: stoneX, y: stoneY)
                stone.zPosition = 2
                card.addChild(stone)
            }

            // Label
            let label = SKLabelNode(fontNamed: uiFontBold)
            label.text = pattern
            label.fontSize = 12
            label.fontColor = primaryTextColor
            label.position = CGPoint(x: x, y: -miniSize / 2 - 12)
            label.zPosition = 1
            card.addChild(label)
        }

        return yPosition - cardHeight - 20
    }

    // MARK: - Opening Example

    private func addOpeningExample(yPosition: CGFloat) -> CGFloat {
        let boardSize: CGFloat = 130
        let cellSize: CGFloat = boardSize / 7
        let centerY = yPosition - boardSize / 2 - 15

        // Card container
        let cardPadding: CGFloat = 18
        let card = SKShapeNode(rectOf: CGSize(width: boardSize + cardPadding * 2, height: boardSize + cardPadding * 2 + 30), cornerRadius: 12)
        card.fillColor = cardBackgroundColor
        card.strokeColor = accentColor.withAlphaComponent(0.15)
        card.lineWidth = 1
        card.position = CGPoint(x: size.width / 2, y: centerY - 8)
        card.zPosition = 3
        scrollNode.addChild(card)

        // Draw mini board background
        let boardBg = SKShapeNode(rectOf: CGSize(width: boardSize + 8, height: boardSize + 8), cornerRadius: 6)
        boardBg.fillColor = theme.boardColor.skColor
        boardBg.strokeColor = SKColor.black.withAlphaComponent(0.15)
        boardBg.lineWidth = 1
        boardBg.position = CGPoint(x: size.width / 2, y: centerY)
        boardBg.zPosition = 4
        scrollNode.addChild(boardBg)

        // Draw grid
        let gridStart = size.width / 2 - boardSize / 2
        let gridBottom = centerY - boardSize / 2
        for i in 0...6 {
            let x = gridStart + CGFloat(i) * cellSize
            let vLine = SKShapeNode(rectOf: CGSize(width: 0.5, height: boardSize))
            vLine.fillColor = SKColor.black.withAlphaComponent(0.2)
            vLine.strokeColor = .clear
            vLine.position = CGPoint(x: x, y: centerY)
            vLine.zPosition = 5
            scrollNode.addChild(vLine)

            let y = gridBottom + CGFloat(i) * cellSize
            let hLine = SKShapeNode(rectOf: CGSize(width: boardSize, height: 0.5))
            hLine.fillColor = SKColor.black.withAlphaComponent(0.2)
            hLine.strokeColor = .clear
            hLine.position = CGPoint(x: size.width / 2, y: y)
            hLine.zPosition = 5
            scrollNode.addChild(hLine)
        }

        // Center point
        let centerDot = SKShapeNode(circleOfRadius: 2.5)
        centerDot.fillColor = SKColor.black.withAlphaComponent(0.4)
        centerDot.strokeColor = .clear
        centerDot.position = CGPoint(x: size.width / 2, y: centerY)
        centerDot.zPosition = 5
        scrollNode.addChild(centerDot)

        let stoneRadius: CGFloat = cellSize * 0.4

        // Move 1: Black center (with number)
        addNumberedStone(at: CGPoint(x: size.width / 2, y: centerY), player: .black, number: 1, radius: stoneRadius)

        // Move 2: White adjacent
        addNumberedStone(at: CGPoint(x: size.width / 2 + cellSize, y: centerY + cellSize), player: .white, number: 2, radius: stoneRadius)

        // Move 3: Black diagonal
        addNumberedStone(at: CGPoint(x: size.width / 2 - cellSize, y: centerY - cellSize), player: .black, number: 3, radius: stoneRadius)

        // Move 4: White blocks
        addNumberedStone(at: CGPoint(x: size.width / 2 - cellSize * 2, y: centerY - cellSize * 2), player: .white, number: 4, radius: stoneRadius)

        // Move 5: Black extends other direction
        addNumberedStone(at: CGPoint(x: size.width / 2 + cellSize, y: centerY - cellSize), player: .black, number: 5, radius: stoneRadius)

        // Label
        let label = SKLabelNode(fontNamed: uiFontBold)
        label.text = isZenTheme ? "基本の序盤" : "Sample Opening Sequence"
        label.fontSize = 12
        label.fontColor = primaryTextColor
        label.position = CGPoint(x: size.width / 2, y: centerY - boardSize / 2 - 20)
        label.zPosition = 6
        scrollNode.addChild(label)

        return centerY - boardSize / 2 - 50
    }

    private func addNumberedStone(at position: CGPoint, player: Player, number: Int, radius: CGFloat) {
        let stone = SKShapeNode(circleOfRadius: radius)
        stone.fillColor = player == .black ? .black : .white
        stone.strokeColor = player == .black ? SKColor.white.withAlphaComponent(0.3) : SKColor.black.withAlphaComponent(0.2)
        stone.lineWidth = 1.5
        stone.position = position
        stone.zPosition = 6
        scrollNode.addChild(stone)

        let numLabel = SKLabelNode(fontNamed: uiFontBold)
        numLabel.text = "\(number)"
        numLabel.fontSize = radius * 1.2
        numLabel.fontColor = player == .black ? .white : .black
        numLabel.verticalAlignmentMode = .center
        numLabel.horizontalAlignmentMode = .center
        numLabel.position = position
        numLabel.zPosition = 7
        scrollNode.addChild(numLabel)
    }

    // MARK: - Key Pattern Example

    private func addKeyPattern(name: String, description: String, pattern: [(CGFloat, CGFloat)], openEnds: [(CGFloat, CGFloat)], blockedEnds: [(CGFloat, CGFloat)] = [], yPosition: CGFloat) -> CGFloat {
        // Card background
        let cardWidth: CGFloat = 340
        let cardHeight: CGFloat = 75

        let card = SKShapeNode(rectOf: CGSize(width: cardWidth, height: cardHeight), cornerRadius: 12)
        card.fillColor = cardBackgroundColor
        card.strokeColor = accentColor.withAlphaComponent(0.15)
        card.lineWidth = 1
        card.position = CGPoint(x: size.width / 2, y: yPosition)
        card.zPosition = 3
        scrollNode.addChild(card)

        // Pattern name
        let nameLabel = SKLabelNode(fontNamed: uiFontBold)
        nameLabel.text = name
        nameLabel.fontSize = 15
        nameLabel.fontColor = primaryTextColor
        nameLabel.horizontalAlignmentMode = .left
        nameLabel.position = CGPoint(x: -cardWidth/2 + 15, y: 15)
        nameLabel.zPosition = 1
        card.addChild(nameLabel)

        // Description
        let descLabel = SKLabelNode(fontNamed: uiFont)
        descLabel.text = description
        descLabel.fontSize = 12
        descLabel.fontColor = secondaryTextColor
        descLabel.horizontalAlignmentMode = .left
        descLabel.position = CGPoint(x: -cardWidth/2 + 15, y: -8)
        descLabel.zPosition = 1
        card.addChild(descLabel)

        // Visual pattern on right side
        let patternContainer = SKNode()
        patternContainer.position = CGPoint(x: cardWidth/2 - 70, y: 5)
        patternContainer.zPosition = 1
        card.addChild(patternContainer)

        let cellSize: CGFloat = 20
        let stoneRadius: CGFloat = 8

        // Draw a mini line segment for context
        let lineWidth: CGFloat = CGFloat(max(pattern.count, 4) + 2) * cellSize
        let line = SKShapeNode(rectOf: CGSize(width: lineWidth, height: 1))
        line.fillColor = SKColor.black.withAlphaComponent(0.15)
        line.strokeColor = .clear
        patternContainer.addChild(line)

        // Draw stones
        for (offsetX, offsetY) in pattern {
            let stone = SKShapeNode(circleOfRadius: stoneRadius)
            stone.fillColor = .black
            stone.strokeColor = SKColor.white.withAlphaComponent(0.3)
            stone.lineWidth = 1
            stone.position = CGPoint(x: offsetX * cellSize, y: offsetY * cellSize)
            stone.zPosition = 2
            patternContainer.addChild(stone)
        }

        // Draw open ends (green circles)
        for (offsetX, offsetY) in openEnds {
            let openMarker = SKShapeNode(circleOfRadius: stoneRadius * 0.7)
            openMarker.fillColor = SKColor(red: 0.2, green: 0.65, blue: 0.2, alpha: 0.25)
            openMarker.strokeColor = SKColor(red: 0.2, green: 0.6, blue: 0.2, alpha: 0.9)
            openMarker.lineWidth = 2.5
            openMarker.position = CGPoint(x: offsetX * cellSize, y: offsetY * cellSize)
            openMarker.zPosition = 2
            patternContainer.addChild(openMarker)
        }

        // Draw blocked ends (white stone)
        for (offsetX, offsetY) in blockedEnds {
            let blockedStone = SKShapeNode(circleOfRadius: stoneRadius)
            blockedStone.fillColor = .white
            blockedStone.strokeColor = SKColor.black.withAlphaComponent(0.25)
            blockedStone.lineWidth = 1
            blockedStone.position = CGPoint(x: offsetX * cellSize, y: offsetY * cellSize)
            blockedStone.zPosition = 2
            patternContainer.addChild(blockedStone)
        }

        return yPosition - cardHeight - 10
    }

    // MARK: - Blocking Example

    private func addBlockingExample(yPosition: CGFloat) -> CGFloat {
        let boardSize: CGFloat = 110
        let cellSize: CGFloat = boardSize / 6
        let centerY = yPosition - boardSize / 2 - 15

        // Card container
        let cardPadding: CGFloat = 18
        let card = SKShapeNode(rectOf: CGSize(width: boardSize + cardPadding * 2, height: boardSize + cardPadding * 2 + 30), cornerRadius: 12)
        card.fillColor = cardBackgroundColor
        card.strokeColor = SKColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 0.2)
        card.lineWidth = 1
        card.position = CGPoint(x: size.width / 2, y: centerY - 8)
        card.zPosition = 3
        scrollNode.addChild(card)

        // Board background
        let boardBg = SKShapeNode(rectOf: CGSize(width: boardSize + 8, height: boardSize + 8), cornerRadius: 5)
        boardBg.fillColor = theme.boardColor.skColor
        boardBg.strokeColor = SKColor.black.withAlphaComponent(0.15)
        boardBg.lineWidth = 1
        boardBg.position = CGPoint(x: size.width / 2, y: centerY)
        boardBg.zPosition = 4
        scrollNode.addChild(boardBg)

        // Grid
        let gridStart = size.width / 2 - boardSize / 2
        let gridBottom = centerY - boardSize / 2
        for i in 0...5 {
            let x = gridStart + CGFloat(i) * cellSize
            let vLine = SKShapeNode(rectOf: CGSize(width: 0.5, height: boardSize))
            vLine.fillColor = SKColor.black.withAlphaComponent(0.2)
            vLine.strokeColor = .clear
            vLine.position = CGPoint(x: x, y: centerY)
            vLine.zPosition = 5
            scrollNode.addChild(vLine)

            let y = gridBottom + CGFloat(i) * cellSize
            let hLine = SKShapeNode(rectOf: CGSize(width: boardSize, height: 0.5))
            hLine.fillColor = SKColor.black.withAlphaComponent(0.2)
            hLine.strokeColor = .clear
            hLine.position = CGPoint(x: size.width / 2, y: y)
            hLine.zPosition = 5
            scrollNode.addChild(hLine)
        }

        let stoneRadius: CGFloat = cellSize * 0.4

        // Black has 3 in a row (threat)
        let threatY = centerY + cellSize
        for i in 0..<3 {
            let stone = SKShapeNode(circleOfRadius: stoneRadius)
            stone.fillColor = .black
            stone.strokeColor = SKColor.white.withAlphaComponent(0.3)
            stone.lineWidth = 1.5
            stone.position = CGPoint(x: size.width / 2 - cellSize + CGFloat(i) * cellSize, y: threatY)
            stone.zPosition = 6
            scrollNode.addChild(stone)
        }

        // Show blocking positions with pulsing indicators
        let blockPos1 = CGPoint(x: size.width / 2 - cellSize * 2, y: threatY)
        let blockPos2 = CGPoint(x: size.width / 2 + cellSize * 2, y: threatY)

        for pos in [blockPos1, blockPos2] {
            let blockMarker = SKShapeNode(circleOfRadius: stoneRadius * 0.75)
            blockMarker.fillColor = SKColor(red: 0.85, green: 0.2, blue: 0.15, alpha: 0.25)
            blockMarker.strokeColor = SKColor(red: 0.85, green: 0.2, blue: 0.15, alpha: 0.95)
            blockMarker.lineWidth = 2.5
            blockMarker.position = pos
            blockMarker.zPosition = 6
            scrollNode.addChild(blockMarker)

            // Pulse animation
            let pulse = SKAction.sequence([
                SKAction.scale(to: 1.15, duration: 0.6),
                SKAction.scale(to: 1.0, duration: 0.6)
            ])
            blockMarker.run(SKAction.repeatForever(pulse))
        }

        // Label
        let label = SKLabelNode(fontNamed: uiFontBold)
        label.text = isZenTheme ? "赤い所をブロック！" : "Block the red spots!"
        label.fontSize = 13
        label.fontColor = SKColor(red: 0.8, green: 0.2, blue: 0.15, alpha: 1.0)
        label.position = CGPoint(x: size.width / 2, y: centerY - boardSize / 2 - 20)
        label.zPosition = 7
        scrollNode.addChild(label)

        return centerY - boardSize / 2 - 50
    }

    // MARK: - Double Threat Example

    private func addDoubleThreatExample(yPosition: CGFloat) -> CGFloat {
        let boardSize: CGFloat = 140
        let cellSize: CGFloat = boardSize / 7
        let centerY = yPosition - boardSize / 2 - 15

        // Card container
        let cardPadding: CGFloat = 18
        let card = SKShapeNode(rectOf: CGSize(width: boardSize + cardPadding * 2, height: boardSize + cardPadding * 2 + 30), cornerRadius: 12)
        card.fillColor = cardBackgroundColor
        card.strokeColor = SKColor(red: 0.9, green: 0.7, blue: 0.1, alpha: 0.3)
        card.lineWidth = 1
        card.position = CGPoint(x: size.width / 2, y: centerY - 8)
        card.zPosition = 3
        scrollNode.addChild(card)

        // Board background
        let boardBg = SKShapeNode(rectOf: CGSize(width: boardSize + 8, height: boardSize + 8), cornerRadius: 5)
        boardBg.fillColor = theme.boardColor.skColor
        boardBg.strokeColor = SKColor.black.withAlphaComponent(0.15)
        boardBg.lineWidth = 1
        boardBg.position = CGPoint(x: size.width / 2, y: centerY)
        boardBg.zPosition = 4
        scrollNode.addChild(boardBg)

        // Grid
        let gridStart = size.width / 2 - boardSize / 2
        let gridBottom = centerY - boardSize / 2
        for i in 0...6 {
            let x = gridStart + CGFloat(i) * cellSize
            let vLine = SKShapeNode(rectOf: CGSize(width: 0.5, height: boardSize))
            vLine.fillColor = SKColor.black.withAlphaComponent(0.2)
            vLine.strokeColor = .clear
            vLine.position = CGPoint(x: x, y: centerY)
            vLine.zPosition = 5
            scrollNode.addChild(vLine)

            let y = gridBottom + CGFloat(i) * cellSize
            let hLine = SKShapeNode(rectOf: CGSize(width: boardSize, height: 0.5))
            hLine.fillColor = SKColor.black.withAlphaComponent(0.2)
            hLine.strokeColor = .clear
            hLine.position = CGPoint(x: size.width / 2, y: y)
            hLine.zPosition = 5
            scrollNode.addChild(hLine)
        }

        let stoneRadius: CGFloat = cellSize * 0.38
        let forkCenterX = size.width / 2
        let forkCenterY = centerY

        // The key stone that creates the fork (highlighted)
        let keyStone = SKShapeNode(circleOfRadius: stoneRadius)
        keyStone.fillColor = .black
        keyStone.strokeColor = SKColor(red: 0.95, green: 0.75, blue: 0.1, alpha: 1.0)
        keyStone.lineWidth = 3
        keyStone.position = CGPoint(x: forkCenterX, y: forkCenterY)
        keyStone.zPosition = 7
        scrollNode.addChild(keyStone)

        // Star marker on key stone
        let star = SKLabelNode(text: "★")
        star.fontSize = stoneRadius * 1.0
        star.fontColor = SKColor(red: 0.95, green: 0.75, blue: 0.1, alpha: 1.0)
        star.verticalAlignmentMode = .center
        star.position = CGPoint(x: forkCenterX, y: forkCenterY)
        star.zPosition = 8
        scrollNode.addChild(star)

        // Horizontal line stones
        for i in [-2, -1, 1] {
            let stone = SKShapeNode(circleOfRadius: stoneRadius)
            stone.fillColor = .black
            stone.strokeColor = SKColor.white.withAlphaComponent(0.3)
            stone.lineWidth = 1.5
            stone.position = CGPoint(x: forkCenterX + CGFloat(i) * cellSize, y: forkCenterY)
            stone.zPosition = 6
            scrollNode.addChild(stone)
        }

        // Vertical line stones
        for i in [-2, -1, 1] {
            let stone = SKShapeNode(circleOfRadius: stoneRadius)
            stone.fillColor = .black
            stone.strokeColor = SKColor.white.withAlphaComponent(0.3)
            stone.lineWidth = 1.5
            stone.position = CGPoint(x: forkCenterX, y: forkCenterY + CGFloat(i) * cellSize)
            stone.zPosition = 6
            scrollNode.addChild(stone)
        }

        // Winning positions (green)
        let winPositions = [
            CGPoint(x: forkCenterX + 2 * cellSize, y: forkCenterY),
            CGPoint(x: forkCenterX - 3 * cellSize, y: forkCenterY),
            CGPoint(x: forkCenterX, y: forkCenterY + 2 * cellSize),
            CGPoint(x: forkCenterX, y: forkCenterY - 3 * cellSize)
        ]

        for pos in winPositions {
            let winMarker = SKShapeNode(circleOfRadius: stoneRadius * 0.65)
            winMarker.fillColor = SKColor(red: 0.2, green: 0.65, blue: 0.2, alpha: 0.3)
            winMarker.strokeColor = SKColor(red: 0.2, green: 0.6, blue: 0.2, alpha: 0.95)
            winMarker.lineWidth = 2.5
            winMarker.position = pos
            winMarker.zPosition = 6
            scrollNode.addChild(winMarker)
        }

        // Label
        let label = SKLabelNode(fontNamed: uiFontBold)
        label.text = isZenTheme ? "★が四三を作る！" : "★ creates double threat!"
        label.fontSize = 12
        label.fontColor = SKColor(red: 0.85, green: 0.65, blue: 0.0, alpha: 1.0)
        label.position = CGPoint(x: size.width / 2, y: centerY - boardSize / 2 - 20)
        label.zPosition = 8
        scrollNode.addChild(label)

        return centerY - boardSize / 2 - 50
    }

    // MARK: - Quick Reference

    private func addQuickRef(term: String, meaning: String, yPosition: CGFloat) -> CGFloat {
        let cardWidth: CGFloat = 340
        let cardHeight: CGFloat = 36

        let card = SKShapeNode(rectOf: CGSize(width: cardWidth, height: cardHeight), cornerRadius: 8)
        card.fillColor = cardBackgroundColor
        card.strokeColor = accentColor.withAlphaComponent(0.1)
        card.lineWidth = 1
        card.position = CGPoint(x: size.width / 2, y: yPosition)
        card.zPosition = 3
        scrollNode.addChild(card)

        let termLabel = SKLabelNode(fontNamed: uiFontBold)
        termLabel.text = term
        termLabel.fontSize = 13
        termLabel.fontColor = accentColor
        termLabel.horizontalAlignmentMode = .left
        termLabel.verticalAlignmentMode = .center
        termLabel.position = CGPoint(x: -cardWidth/2 + 15, y: 0)
        termLabel.zPosition = 1
        card.addChild(termLabel)

        let meaningLabel = SKLabelNode(fontNamed: uiFont)
        meaningLabel.text = meaning
        meaningLabel.fontSize = 12
        meaningLabel.fontColor = primaryTextColor
        meaningLabel.horizontalAlignmentMode = .left
        meaningLabel.verticalAlignmentMode = .center
        meaningLabel.position = CGPoint(x: -30, y: 0)
        meaningLabel.zPosition = 1
        card.addChild(meaningLabel)

        return yPosition - cardHeight - 8
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
        label.text = isZenTheme ? "← Back · 戻る" : "← Back to Menu"
        label.fontSize = 16
        label.fontColor = primaryTextColor
        label.verticalAlignmentMode = .center
        label.name = "backButton"
        container.addChild(label)
    }

    private func setupPageIndicator() {
        // Scroll hint
        let hintLabel = SKLabelNode(fontNamed: uiFont)
        hintLabel.text = isZenTheme ? "↕ スクロール" : "↕ Scroll for more"
        hintLabel.fontSize = 11
        hintLabel.fontColor = secondaryTextColor.withAlphaComponent(0.6)
        hintLabel.position = CGPoint(x: size.width / 2, y: 115)
        hintLabel.zPosition = 20
        hintLabel.name = "scrollHint"
        addChild(hintLabel)

        // Fade out hint after scrolling starts
        let fadeAction = SKAction.sequence([
            SKAction.wait(forDuration: 3.0),
            SKAction.fadeOut(withDuration: 1.0)
        ])
        hintLabel.run(fadeAction)
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
                if let parent = node.parent, parent.zPosition == 20 {
                    parent.run(SKAction.scale(to: 0.96, duration: 0.1))
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
            // Hide scroll hint when user starts scrolling
            childNode(withName: "scrollHint")?.removeFromParent()
        }

        if isDragging {
            scrollOffset += deltaY
            scrollOffset = max(0, min(scrollOffset, maxScrollOffset))
            scrollNode.position.y = scrollOffset
            lastTouchY = location.y
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        // Reset back button scale
        for child in children where child.name == "backButton" && child.zPosition == 20 {
            child.run(SKAction.scale(to: 1.0, duration: 0.1))
        }

        if !isDragging {
            handleTap(at: location)
        }
    }

    private func handleTap(at location: CGPoint) {
        let nodes = self.nodes(at: location)

        for node in nodes {
            if node.name == "backButton" {
                SoundManager.shared.buttonTapped()
                goBackToMenu()
                return
            }
        }
    }

    private func goBackToMenu() {
        let transition = SKTransition.fade(withDuration: 0.4)
        let menuScene = MenuScene(size: size)
        menuScene.scaleMode = .aspectFill
        view?.presentScene(menuScene, transition: transition)
    }
}
