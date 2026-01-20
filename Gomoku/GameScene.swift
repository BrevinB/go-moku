//
//  GameScene.swift
//  Gomoku
//
//  Created by Brevin Blalock on 10/13/25.
//

import SpriteKit
import GameplayKit

enum GameMode: String, Codable {
    case twoPlayer
    case vsAI
}

class GameScene: SKScene {

    private var board: GomokuBoard!
    private var cellSize: CGFloat = 0
    private var boardOffset: CGPoint = .zero
    private var statusLabel: SKLabelNode!
    private var statusBackground: SKShapeNode!
    private var resetButton: SKLabelNode!
    private var resetButtonBackground: SKShapeNode!
    private var undoButton: SKLabelNode!
    private var undoButtonBackground: SKShapeNode!
    private var backButton: SKLabelNode!
    private var stonesNode: SKNode!
    private var boardBackground: SKShapeNode!
    private var innerBoard: SKShapeNode!
    private var gridNode: SKNode!
    private var backgroundNode: SKNode!
    private var ghostStone: SKShapeNode?
    private var aiThinkingIndicator: SKNode?
    private var shareButton: SKLabelNode?
    private var shareButtonBackground: SKShapeNode?

    // Move confirmation UI
    private var pendingMove: (row: Int, col: Int)?
    private var previewStone: SKShapeNode?
    private var confirmButton: SKShapeNode?
    private var confirmButtonLabel: SKLabelNode?
    private var cancelButton: SKShapeNode?
    private var cancelButtonLabel: SKLabelNode?

    // Hint system
    private var hintButton: SKShapeNode?
    private var hintButtonLabel: SKLabelNode?
    private var hintStone: SKShapeNode?

    // AI properties
    var gameMode: GameMode = .vsAI
    var aiDifficulty: AIDifficulty = .medium
    var isPracticeMode: Bool = false
    private var ai: GomokuAI!
    private var humanPlayer: Player = .black
    private var isAIThinking = false
    private var gameGeneration: Int = 0  // Tracks game instance to prevent stale AI moves

    // Practice mode indicator
    private var practiceModeLabel: SKLabelNode?

    // Game restoration
    var restoredGame: SavedGame?

    // Theme reference for convenience
    private var theme: BoardTheme { ThemeManager.shared.currentTheme }

    // Zen color palette for UI elements
    private let washiCream = SKColor(red: 0.96, green: 0.94, blue: 0.89, alpha: 1.0)
    private let warmWood = SKColor(red: 0.55, green: 0.40, blue: 0.28, alpha: 1.0)
    private let darkWood = SKColor(red: 0.35, green: 0.25, blue: 0.18, alpha: 1.0)
    private let inkBlack = SKColor(red: 0.15, green: 0.13, blue: 0.12, alpha: 1.0)
    private let inkGray = SKColor(red: 0.40, green: 0.38, blue: 0.35, alpha: 1.0)
    private let accentRed = SKColor(red: 0.75, green: 0.22, blue: 0.17, alpha: 1.0)
    private let bamboo = SKColor(red: 0.45, green: 0.52, blue: 0.35, alpha: 1.0)
    private let gold = SKColor(red: 0.85, green: 0.70, blue: 0.35, alpha: 1.0)

    // Helper to add a simple drop shadow behind a shape
    private func makeShadow(for shape: SKShapeNode, offset: CGPoint = CGPoint(x: 4, y: -4), alpha: CGFloat = 0.25) -> SKShapeNode? {
        guard let path = shape.path else { return nil }
        let shadow = SKShapeNode(path: path)
        shadow.fillColor = .black
        shadow.strokeColor = .clear
        shadow.alpha = alpha
        shadow.zPosition = (shape.zPosition) - 0.5
        shadow.position = CGPoint(x: shape.position.x + offset.x, y: shape.position.y + offset.y)
        return shadow
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func didMove(to view: SKView) {
        // Initialize font scaling for this scene
        initializeFontScaling()

        // Create gradient background
        backgroundNode = createGradientBackground()
        addChild(backgroundNode)

        board = GomokuBoard(size: 15)
        stonesNode = SKNode()
        addChild(stonesNode)

        // Initialize AI
        ai = GomokuAI(difficulty: aiDifficulty)

        // Check if restoring a saved game
        if let savedGame = restoredGame {
            // Restore from saved game
            humanPlayer = savedGame.humanPlayer
            restoreFromSavedGame(savedGame)
        } else {
            // New game - determine who goes first based on difficulty
            // In Gomoku, going first (black) is a significant advantage
            if gameMode == .vsAI {
                switch aiDifficulty {
                case .easy:
                    // Easy: player always goes first (advantage to player)
                    humanPlayer = .black
                case .medium:
                    // Medium: random who goes first
                    humanPlayer = Bool.random() ? .black : .white
                case .hard:
                    // Hard: AI always goes first (advantage to AI)
                    humanPlayer = .white
                }
            }
        }

        setupBoard()
        setupUI()

        // If restoring, redraw the stones
        if restoredGame != nil {
            redrawAllStones()
        }

        // If AI goes first (human is white) and no moves yet, trigger AI move
        if gameMode == .vsAI && board.currentPlayer != humanPlayer && board.getMoveHistory().isEmpty {
            isAIThinking = true
            showAIThinkingIndicator()
            let wait = SKAction.wait(forDuration: 1.0)
            let aiMove = SKAction.run { [weak self] in
                self?.makeAIMove()
            }
            run(SKAction.sequence([wait, aiMove]))
        }
        // If it's AI's turn after restore, trigger AI move
        else if restoredGame != nil && gameMode == .vsAI && board.currentPlayer != humanPlayer {
            isAIThinking = true
            showAIThinkingIndicator()
            let wait = SKAction.wait(forDuration: 0.5)
            let aiMove = SKAction.run { [weak self] in
                self?.makeAIMove()
            }
            run(SKAction.sequence([wait, aiMove]))
        }
    }

    private func createGradientBackground() -> SKNode {
        let node = SKNode()

        // Create gradient from theme
        let gradient = theme.backgroundGradient
        let topColor = gradient.topColor.skColor
        let midColor = gradient.midColor.skColor
        let bottomColor = gradient.bottomColor.skColor

        let numSteps = 8
        for i in 0..<numSteps {
            let progress = CGFloat(i) / CGFloat(numSteps - 1)

            // Interpolate between colors
            let color: SKColor
            if progress < 0.5 {
                let localProgress = progress * 2
                color = interpolateColors(from: topColor, to: midColor, progress: localProgress)
            } else {
                let localProgress = (progress - 0.5) * 2
                color = interpolateColors(from: midColor, to: bottomColor, progress: localProgress)
            }

            let height = size.height / CGFloat(numSteps)
            let rect = SKShapeNode(rect: CGRect(x: 0, y: CGFloat(i) * height, width: size.width, height: height + 1))
            rect.fillColor = color
            rect.strokeColor = .clear
            rect.zPosition = -100
            node.addChild(rect)
        }

        // Only add Zen-specific decorations for the Zen theme
        let isZenTheme = theme.id == "zen"

        if isZenTheme {
            // Add subtle grid pattern (washi paper texture)
            let gridAlpha: CGFloat = 0.025
            for i in stride(from: CGFloat(50), to: size.width, by: 50) {
                let line = SKShapeNode(rectOf: CGSize(width: 1, height: size.height))
                line.fillColor = inkBlack.withAlphaComponent(gridAlpha)
                line.strokeColor = .clear
                line.position = CGPoint(x: i, y: size.height / 2)
                line.zPosition = -98
                node.addChild(line)
            }
            for i in stride(from: CGFloat(50), to: size.height, by: 50) {
                let line = SKShapeNode(rectOf: CGSize(width: size.width, height: 1))
                line.fillColor = inkBlack.withAlphaComponent(gridAlpha)
                line.strokeColor = .clear
                line.position = CGPoint(x: size.width / 2, y: i)
                line.zPosition = -98
                node.addChild(line)
            }

            // Add ink wash decorative elements
            addZenDecorations(to: node)
        } else {
            // Add simple decorative circles for other themes
            addSimpleDecorations(to: node)
        }

        return node
    }

    private func addSimpleDecorations(to node: SKNode) {
        // Add simple decorative circles based on theme colors
        let positions: [(x: CGFloat, y: CGFloat, radius: CGFloat)] = [
            (x: 0.12, y: 0.85, radius: 80),
            (x: 0.88, y: 0.25, radius: 90),
            (x: 0.15, y: 0.18, radius: 70)
        ]

        for (index, pos) in positions.enumerated() {
            guard index < theme.decorativeCircleColors.count else { continue }
            let decorColor = theme.decorativeCircleColors[index]

            let circle = SKShapeNode(circleOfRadius: pos.radius)
            circle.fillColor = decorColor.skColor
            circle.strokeColor = .clear
            circle.position = CGPoint(x: size.width * pos.x, y: size.height * pos.y)
            circle.zPosition = -97
            node.addChild(circle)

            // Add a slightly larger, more transparent version
            let outerCircle = SKShapeNode(circleOfRadius: pos.radius * 1.4)
            outerCircle.fillColor = decorColor.skColor.withAlphaComponent(decorColor.alpha * 0.5)
            outerCircle.strokeColor = .clear
            outerCircle.position = CGPoint(x: size.width * pos.x, y: size.height * pos.y)
            outerCircle.zPosition = -98
            node.addChild(outerCircle)
        }
    }

    private func addZenDecorations(to node: SKNode) {
        // Large enso-like circle (top right) - ink wash style
        let ensoRadius: CGFloat = 100
        let enso = SKShapeNode(circleOfRadius: ensoRadius)
        enso.fillColor = inkBlack.withAlphaComponent(0.03)
        enso.strokeColor = .clear
        enso.position = CGPoint(x: size.width - 60, y: size.height - 80)
        enso.zPosition = -97
        node.addChild(enso)

        // Secondary smaller circle
        let enso2 = SKShapeNode(circleOfRadius: 70)
        enso2.fillColor = warmWood.withAlphaComponent(0.04)
        enso2.strokeColor = .clear
        enso2.position = CGPoint(x: 50, y: 160)
        enso2.zPosition = -97
        node.addChild(enso2)

        // Ink wash mountains silhouette at bottom
        addInkMountains(to: node)

        // Bamboo stalks decoration (left side)
        addBambooDecoration(to: node)
    }

    private func addInkMountains(to node: SKNode) {
        // Create layered mountain silhouettes with ink wash effect
        let mountainConfigs: [(yBase: CGFloat, height: CGFloat, alpha: CGFloat, xOffset: CGFloat)] = [
            (yBase: 0, height: 80, alpha: 0.04, xOffset: 0),
            (yBase: 0, height: 60, alpha: 0.03, xOffset: 40),
            (yBase: 0, height: 45, alpha: 0.025, xOffset: -30)
        ]

        for (index, config) in mountainConfigs.enumerated() {
            let path = CGMutablePath()
            let startX: CGFloat = config.xOffset
            let width = size.width + 60

            path.move(to: CGPoint(x: startX - 30, y: config.yBase))

            // Create gentle mountain peaks
            let peakCount = 4 + index
            let segmentWidth = width / CGFloat(peakCount)

            for i in 0...peakCount {
                let x = startX + CGFloat(i) * segmentWidth
                let peakHeight = config.height * CGFloat.random(in: 0.6...1.0)
                let y = config.yBase + (i % 2 == 1 ? peakHeight : peakHeight * 0.3)

                if i == 0 {
                    path.addLine(to: CGPoint(x: x, y: y))
                } else {
                    let controlX = x - segmentWidth * 0.5
                    let controlY = y + config.height * 0.3
                    path.addQuadCurve(to: CGPoint(x: x, y: y), control: CGPoint(x: controlX, y: controlY))
                }
            }

            path.addLine(to: CGPoint(x: size.width + 30, y: config.yBase))
            path.closeSubpath()

            let mountain = SKShapeNode(path: path)
            mountain.fillColor = inkBlack.withAlphaComponent(config.alpha)
            mountain.strokeColor = .clear
            mountain.zPosition = -96 + CGFloat(index)
            node.addChild(mountain)
        }
    }

    private func addBambooDecoration(to node: SKNode) {
        // Subtle bamboo stalks on left edge
        let bambooColor = bamboo.withAlphaComponent(0.08)
        let xPositions: [CGFloat] = [15, 28, 8]
        let heights: [CGFloat] = [size.height * 0.7, size.height * 0.5, size.height * 0.6]

        for (index, x) in xPositions.enumerated() {
            // Main stalk
            let stalkWidth: CGFloat = 4 - CGFloat(index) * 0.5
            let stalkHeight = heights[index]

            let stalk = SKShapeNode(rectOf: CGSize(width: stalkWidth, height: stalkHeight))
            stalk.fillColor = bambooColor
            stalk.strokeColor = .clear
            stalk.position = CGPoint(x: x, y: stalkHeight / 2)
            stalk.zPosition = -95
            node.addChild(stalk)

            // Bamboo nodes (segments)
            let nodeCount = Int(stalkHeight / 80)
            for j in 1..<nodeCount {
                let nodeY = CGFloat(j) * 80 + CGFloat.random(in: -10...10)
                let bambooNode = SKShapeNode(rectOf: CGSize(width: stalkWidth + 2, height: 3))
                bambooNode.fillColor = bamboo.withAlphaComponent(0.12)
                bambooNode.strokeColor = .clear
                bambooNode.position = CGPoint(x: x, y: nodeY)
                bambooNode.zPosition = -94
                node.addChild(bambooNode)
            }
        }
    }

    private func addWoodGrainEffect(to parentNode: SKShapeNode, width: CGFloat, height: CGFloat, isInner: Bool = false) {
        // Create subtle horizontal wood grain lines
        let grainColor = isInner ? darkWood.withAlphaComponent(0.04) : darkWood.withAlphaComponent(0.08)
        let grainCount = isInner ? 12 : 8
        let spacing = height / CGFloat(grainCount + 1)

        for i in 1...grainCount {
            let yOffset = -height / 2 + spacing * CGFloat(i) + CGFloat.random(in: -3...3)
            let grainWidth = width * CGFloat.random(in: 0.7...0.95)
            let xOffset = CGFloat.random(in: -10...10)

            let grain = SKShapeNode(rectOf: CGSize(width: grainWidth, height: 1))
            grain.fillColor = grainColor
            grain.strokeColor = .clear
            grain.position = CGPoint(x: xOffset, y: yOffset)
            grain.zPosition = 0.5
            grain.alpha = CGFloat.random(in: 0.3...0.7)
            parentNode.addChild(grain)
        }

        // Add a few curved grain lines for natural look
        if !isInner {
            for _ in 0..<3 {
                let startY = CGFloat.random(in: -height/3...height/3)
                let path = CGMutablePath()
                path.move(to: CGPoint(x: -width/2 + 10, y: startY))

                let controlY = startY + CGFloat.random(in: -20...20)
                path.addQuadCurve(
                    to: CGPoint(x: width/2 - 10, y: startY + CGFloat.random(in: -10...10)),
                    control: CGPoint(x: 0, y: controlY)
                )

                let curvedGrain = SKShapeNode(path: path)
                curvedGrain.strokeColor = grainColor
                curvedGrain.lineWidth = 0.8
                curvedGrain.zPosition = 0.5
                curvedGrain.alpha = CGFloat.random(in: 0.2...0.5)
                parentNode.addChild(curvedGrain)
            }
        }
    }

    private func interpolateColors(from: SKColor, to: SKColor, progress: CGFloat) -> SKColor {
        var fromR: CGFloat = 0, fromG: CGFloat = 0, fromB: CGFloat = 0, fromA: CGFloat = 0
        var toR: CGFloat = 0, toG: CGFloat = 0, toB: CGFloat = 0, toA: CGFloat = 0

        from.getRed(&fromR, green: &fromG, blue: &fromB, alpha: &fromA)
        to.getRed(&toR, green: &toG, blue: &toB, alpha: &toA)

        let r = fromR + (toR - fromR) * progress
        let g = fromG + (toG - fromG) * progress
        let b = fromB + (toB - fromB) * progress
        let a = fromA + (toA - fromA) * progress

        return SKColor(red: r, green: g, blue: b, alpha: a)
    }

    private func setupBoard() {
        // Calculate space for UI elements
        let topUIHeight: CGFloat = 100  // Space for status label
        let bottomUIHeight: CGFloat = 90  // Space for button
        let margin: CGFloat = 24

        let availableWidth = size.width - (margin * 2)
        let availableHeight = size.height - topUIHeight - bottomUIHeight - (margin * 2)

        let maxBoardSize = min(availableWidth, availableHeight)
        // Round cellSize to ensure precise alignment
        cellSize = (maxBoardSize / CGFloat(board.size - 1)).rounded()

        // The actual grid size (from first line to last line)
        let actualGridSize = cellSize * CGFloat(board.size - 1)

        // Center the board in the available space and round to whole pixels
        boardOffset = CGPoint(
            x: ((size.width - actualGridSize) / 2).rounded(),
            y: (bottomUIHeight + margin + (availableHeight - actualGridSize) / 2).rounded()
        )

        let isZenTheme = theme.id == "zen"

        // Create board frame
        let boardPadding: CGFloat = 20
        let cornerRadius: CGFloat = isZenTheme ? 6 : 12  // More traditional for Zen, softer for others
        boardBackground = SKShapeNode(
            rectOf: CGSize(width: actualGridSize + boardPadding * 2, height: actualGridSize + boardPadding * 2),
            cornerRadius: cornerRadius
        )
        boardBackground.fillColor = theme.boardColor.skColor
        boardBackground.strokeColor = theme.boardStrokeColor.skColor
        boardBackground.lineWidth = 2
        boardBackground.position = CGPoint(x: size.width / 2, y: boardOffset.y + actualGridSize / 2)
        boardBackground.zPosition = -1
        addChild(boardBackground)

        // Add wood grain texture effect only for Zen theme
        if isZenTheme {
            addWoodGrainEffect(to: boardBackground, width: actualGridSize + boardPadding * 2, height: actualGridSize + boardPadding * 2)
        }

        // Natural shadow layers
        let shadowOffsets = [(0.0, -8.0, 0.20), (0.0, -4.0, 0.12)]
        for (x, y, alpha) in shadowOffsets {
            if let boardShadow = makeShadow(for: boardBackground, offset: CGPoint(x: x, y: y), alpha: alpha) {
                addChild(boardShadow)
                boardShadow.zPosition = boardBackground.zPosition - 1
            }
        }

        // Inner board surface
        let innerCornerRadius: CGFloat = isZenTheme ? 2 : 8
        innerBoard = SKShapeNode(
            rectOf: CGSize(width: actualGridSize + 8, height: actualGridSize + 8),
            cornerRadius: innerCornerRadius
        )
        innerBoard.fillColor = theme.innerBoardColor.skColor
        innerBoard.strokeColor = theme.innerBoardStrokeColor.skColor
        innerBoard.lineWidth = 1
        innerBoard.position = CGPoint(x: size.width / 2, y: boardOffset.y + actualGridSize / 2)
        innerBoard.zPosition = 0
        addChild(innerBoard)

        // Add subtle wood grain only for Zen theme
        if isZenTheme {
            addWoodGrainEffect(to: innerBoard, width: actualGridSize + 8, height: actualGridSize + 8, isInner: true)
        }

        // Draw grid lines - sumi ink style
        gridNode = SKNode()
        let totalGridSize = cellSize * CGFloat(board.size - 1)
        let highContrast = AccessibilityManager.shared.isHighContrastEnabled

        for i in 0..<board.size {
            let position = CGFloat(i) * cellSize

            // Edge lines slightly thicker (traditional Go board style)
            // High contrast mode makes all lines bolder
            let isEdge = (i == 0 || i == board.size - 1)
            var lineWidth: CGFloat = isEdge ? 1.5 : 1.0
            if highContrast {
                lineWidth = isEdge ? 2.5 : 1.8
            }

            // Grid line color (darker for high contrast)
            let gridColor = highContrast
                ? theme.gridLineColor.skColor.withAlphaComponent(1.0)
                : theme.gridLineColor.skColor

            // Vertical lines
            let verticalLine = SKShapeNode()
            let verticalPath = CGMutablePath()
            verticalPath.move(to: CGPoint(x: position, y: 0))
            verticalPath.addLine(to: CGPoint(x: position, y: totalGridSize))
            verticalLine.path = verticalPath
            verticalLine.strokeColor = gridColor
            verticalLine.lineWidth = lineWidth
            gridNode.addChild(verticalLine)

            // Horizontal lines
            let horizontalLine = SKShapeNode()
            let horizontalPath = CGMutablePath()
            horizontalPath.move(to: CGPoint(x: 0, y: position))
            horizontalPath.addLine(to: CGPoint(x: totalGridSize, y: position))
            horizontalLine.path = horizontalPath
            horizontalLine.strokeColor = gridColor
            horizontalLine.lineWidth = lineWidth
            gridNode.addChild(horizontalLine)
        }

        gridNode.position = boardOffset
        gridNode.zPosition = 1
        addChild(gridNode)

        // Add traditional star points (hoshi) - 9 points for 15x15 board
        let starPoints = [(3, 3), (3, 7), (3, 11), (7, 3), (7, 7), (7, 11), (11, 3), (11, 7), (11, 11)]
        for (row, col) in starPoints {
            let star = SKShapeNode(circleOfRadius: 3.5)
            star.fillColor = theme.starPointColor.skColor
            star.strokeColor = .clear
            star.position = CGPoint(
                x: boardOffset.x + CGFloat(col) * cellSize,
                y: boardOffset.y + CGFloat(row) * cellSize
            )
            star.zPosition = 1
            star.name = "starPoint"
            addChild(star)
        }

        // Add board coordinates if enabled
        if AccessibilityManager.shared.showBoardCoordinates {
            setupBoardCoordinates()
        }
    }

    private func setupBoardCoordinates() {
        let letters = "ABCDEFGHJKLMNOP" // Skip 'I' as per Go convention
        let fontSize: CGFloat = fontManager.size(for: .footnote)
        // Use a darker, more visible color based on board color
        let coordinateColor = theme.boardColor.skColor.adjustedForCoordinates()
        let fontName = theme.id == "zen" ? "Hiragino Mincho ProN" : "AvenirNext-DemiBold"

        // Column labels (A-O) at bottom
        for col in 0..<board.size {
            let letter = String(letters[letters.index(letters.startIndex, offsetBy: col)])

            let label = SKLabelNode(fontNamed: fontName)
            label.text = letter
            label.fontSize = fontSize
            label.fontColor = coordinateColor
            label.horizontalAlignmentMode = .center
            label.verticalAlignmentMode = .top
            label.position = CGPoint(
                x: boardOffset.x + CGFloat(col) * cellSize,
                y: boardOffset.y - 10
            )
            label.zPosition = 2
            label.name = "coordinate"
            addChild(label)
        }

        // Row labels (1-15) on left side
        for row in 0..<board.size {
            let number = row + 1

            let label = SKLabelNode(fontNamed: fontName)
            label.text = "\(number)"
            label.fontSize = fontSize
            label.fontColor = coordinateColor
            label.horizontalAlignmentMode = .right
            label.verticalAlignmentMode = .center
            label.position = CGPoint(
                x: boardOffset.x - 10,
                y: boardOffset.y + CGFloat(row) * cellSize
            )
            label.zPosition = 2
            label.name = "coordinate"
            addChild(label)
        }
    }

    private func setupUI() {
        // Status card using theme colors
        statusBackground = SKShapeNode(rectOf: CGSize(width: 250, height: 68), cornerRadius: 34)
        statusBackground.fillColor = theme.statusBackgroundColor.skColor
        statusBackground.strokeColor = theme.statusStrokeColor.skColor
        statusBackground.lineWidth = 2
        statusBackground.position = CGPoint(x: size.width / 2, y: size.height - 80)
        statusBackground.zPosition = 10
        addChild(statusBackground)

        // Natural shadow layers
        let statusShadowOffsets = [(0.0, -8.0, 0.28), (0.0, -4.0, 0.16)]
        for (x, y, alpha) in statusShadowOffsets {
            if let statusShadow = makeShadow(for: statusBackground, offset: CGPoint(x: x, y: y), alpha: alpha) {
                addChild(statusShadow)
                statusShadow.zPosition = statusBackground.zPosition - 1
            }
        }

        // Soft inner highlight (slightly lighter than status background)
        let innerGlow = SKShapeNode(rectOf: CGSize(width: 244, height: 62), cornerRadius: 31)
        innerGlow.fillColor = .clear
        let highlightColor = SKColor(
            red: min(1.0, theme.statusBackgroundColor.red + 0.06),
            green: min(1.0, theme.statusBackgroundColor.green + 0.06),
            blue: min(1.0, theme.statusBackgroundColor.blue + 0.06),
            alpha: 0.4
        )
        innerGlow.strokeColor = highlightColor
        innerGlow.lineWidth = 1.2
        innerGlow.position = statusBackground.position
        innerGlow.zPosition = statusBackground.zPosition + 0.5
        addChild(innerGlow)

        let isZenTheme = theme.id == "zen"
        let uiFont = isZenTheme ? "Hiragino Mincho ProN" : "AvenirNext-Medium"

        statusLabel = SKLabelNode(fontNamed: uiFont)
        statusLabel.fontSize = fontSize(.title2)
        statusLabel.position = CGPoint(x: size.width / 2, y: size.height - 80)
        statusLabel.fontColor = theme.statusTextColor.skColor
        statusLabel.verticalAlignmentMode = .center
        statusLabel.zPosition = 11
        updateStatusLabel()
        addChild(statusLabel)

        // Practice mode indicator
        if isPracticeMode {
            setupPracticeModeIndicator()
        }

        // Back button
        backButton = SKLabelNode(fontNamed: uiFont)
        backButton.text = isZenTheme ? "← 戻る" : "← Menu"
        backButton.fontSize = fontSize(.headline)
        backButton.fontColor = theme.buttonTextColor.skColor
        backButton.position = CGPoint(x: 24, y: size.height - 145)
        backButton.name = "backButton"
        backButton.horizontalAlignmentMode = .left
        backButton.verticalAlignmentMode = .center
        backButton.zPosition = 12
        addChild(backButton)

        // Undo button
        undoButtonBackground = SKShapeNode(rectOf: CGSize(width: 90, height: 44), cornerRadius: 10)
        undoButtonBackground.fillColor = theme.buttonBackgroundColor.skColor
        undoButtonBackground.strokeColor = theme.buttonStrokeColor.skColor
        undoButtonBackground.lineWidth = 1.5
        undoButtonBackground.position = CGPoint(x: size.width / 2 - 120, y: 45)
        undoButtonBackground.name = "undoButton"
        undoButtonBackground.zPosition = 10
        addChild(undoButtonBackground)

        undoButton = SKLabelNode(fontNamed: uiFont)
        undoButton.text = isZenTheme ? "戻す · Undo" : "Undo"
        undoButton.fontSize = fontSize(.body)
        undoButton.fontColor = theme.buttonTextColor.skColor
        undoButton.position = CGPoint(x: size.width / 2 - 120, y: 45)
        undoButton.name = "undoButton"
        undoButton.verticalAlignmentMode = .center
        undoButton.zPosition = 11
        addChild(undoButton)

        // Hint button (costs coins) - only show in AI mode
        if gameMode == .vsAI {
            setupHintButton()
        }

        // New Game button
        resetButtonBackground = SKShapeNode(rectOf: CGSize(width: 110, height: 44), cornerRadius: 10)
        resetButtonBackground.fillColor = bamboo
        resetButtonBackground.strokeColor = SKColor(red: 0.35, green: 0.42, blue: 0.25, alpha: 1.0)
        resetButtonBackground.lineWidth = 1.5
        resetButtonBackground.position = CGPoint(x: size.width / 2 + 120, y: 45)
        resetButtonBackground.name = "resetButton"
        resetButtonBackground.zPosition = 10
        addChild(resetButtonBackground)

        resetButton = SKLabelNode(fontNamed: uiFont)
        resetButton.text = isZenTheme ? "新規 · New" : "New Game"
        resetButton.fontSize = fontSize(.body)
        resetButton.fontColor = .white
        resetButton.position = CGPoint(x: size.width / 2 + 120, y: 45)
        resetButton.name = "resetButton"
        resetButton.verticalAlignmentMode = .center
        resetButton.zPosition = 11
        addChild(resetButton)

        updateUndoButtonState()
    }

    private func setupHintButton() {
        let hintBalance = HintManager.shared.balance
        let isZenTheme = theme.id == "zen"
        let uiFont = isZenTheme ? "Hiragino Mincho ProN" : "AvenirNext-Medium"

        // Hint button - gold style
        hintButton = SKShapeNode(rectOf: CGSize(width: 100, height: 44), cornerRadius: 10)
        hintButton?.fillColor = gold
        hintButton?.strokeColor = SKColor(red: 0.7, green: 0.55, blue: 0.2, alpha: 1.0)
        hintButton?.lineWidth = 1.5
        hintButton?.position = CGPoint(x: size.width / 2, y: 45)
        hintButton?.name = "hintButton"
        hintButton?.zPosition = 10

        if let btn = hintButton {
            addChild(btn)
        }

        // Hint button label - shows remaining hints
        hintButtonLabel = SKLabelNode(fontNamed: uiFont)
        hintButtonLabel?.text = isZenTheme ? "助言 × \(hintBalance)" : "Hint × \(hintBalance)"
        hintButtonLabel?.fontSize = fontSize(.body)
        hintButtonLabel?.fontColor = SKColor(red: 0.30, green: 0.22, blue: 0.10, alpha: 1.0)
        hintButtonLabel?.position = CGPoint(x: size.width / 2, y: 45)
        hintButtonLabel?.name = "hintButton"
        hintButtonLabel?.verticalAlignmentMode = .center
        hintButtonLabel?.zPosition = 11

        if let label = hintButtonLabel {
            addChild(label)
        }

        updateHintButtonState()

        // Listen for hint updates
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateHintDisplay),
            name: .hintsUpdated,
            object: nil
        )
    }

    @objc private func updateHintDisplay() {
        let isZenTheme = theme.id == "zen"
        let hintBalance = HintManager.shared.balance
        hintButtonLabel?.text = isZenTheme ? "助言 × \(hintBalance)" : "Hint × \(hintBalance)"
        updateHintButtonState()

        // Bounce animation
        let scaleUp = SKAction.scale(to: 1.1, duration: 0.1)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
        hintButtonLabel?.run(SKAction.sequence([scaleUp, scaleDown]))
    }

    private func updateHintButtonState() {
        let hasHints = HintManager.shared.hasHints
        hintButton?.alpha = hasHints ? 1.0 : 0.5
        hintButtonLabel?.alpha = hasHints ? 1.0 : 0.5
    }

    private func updateUndoButtonState() {
        let canUndo = board.canUndo()
        undoButton.alpha = canUndo ? 1.0 : 0.4
        undoButtonBackground.alpha = canUndo ? 1.0 : 0.4
    }

    private func setupPracticeModeIndicator() {
        let isZenTheme = theme.id == "zen"
        let uiFont = isZenTheme ? "Hiragino Mincho ProN" : "AvenirNext-Medium"

        // Practice mode badge
        let badgeContainer = SKNode()
        badgeContainer.position = CGPoint(x: size.width / 2, y: size.height - 125)
        badgeContainer.zPosition = 10
        addChild(badgeContainer)

        let badge = SKShapeNode(rectOf: CGSize(width: 130, height: 24), cornerRadius: 12)
        badge.fillColor = bamboo.withAlphaComponent(0.2)
        badge.strokeColor = bamboo.withAlphaComponent(0.5)
        badge.lineWidth = 1
        badgeContainer.addChild(badge)

        practiceModeLabel = SKLabelNode(fontNamed: uiFont)
        practiceModeLabel?.text = isZenTheme ? "練習モード" : "Practice Mode"
        practiceModeLabel?.fontSize = fontSize(.footnote)
        practiceModeLabel?.fontColor = bamboo
        practiceModeLabel?.verticalAlignmentMode = .center
        practiceModeLabel?.horizontalAlignmentMode = .center
        badgeContainer.addChild(practiceModeLabel!)

        // Subtle pulse animation
        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.7, duration: 1.5),
            SKAction.fadeAlpha(to: 1.0, duration: 1.5)
        ])
        badgeContainer.run(SKAction.repeatForever(pulse))
    }

    private func updateStatusLabel() {
        let isZenTheme = theme.id == "zen"
        let colorName = board.currentPlayer == .black ? (isZenTheme ? "黒" : "Black") : (isZenTheme ? "白" : "White")

        switch board.gameState {
        case .playing:
            let statusText: String

            if gameMode == .vsAI {
                // AI mode - show "Your Turn" or "AI's Turn"
                if board.currentPlayer == humanPlayer {
                    if isZenTheme {
                        statusText = "あなたの番 (\(colorName))"
                    } else {
                        statusText = "Your Turn (\(colorName))"
                    }
                } else {
                    if isZenTheme {
                        statusText = "AIの番..."
                    } else {
                        statusText = "AI's Turn..."
                    }
                }
            } else {
                // Two player mode - show color with indicator
                if isZenTheme {
                    statusText = "\(colorName)の番 · \(colorName)'s Turn"
                } else {
                    statusText = "\(colorName)'s Turn"
                }
            }
            statusLabel.text = statusText

        case .won(let player):
            let winnerColor = player == .black ? (isZenTheme ? "黒" : "Black") : (isZenTheme ? "白" : "White")

            if gameMode == .vsAI {
                if player == humanPlayer {
                    statusLabel.text = isZenTheme ? "あなたの勝利! 🎉" : "You Win! 🎉"
                } else {
                    statusLabel.text = isZenTheme ? "AIの勝利" : "AI Wins"
                }
            } else {
                if isZenTheme {
                    statusLabel.text = "\(winnerColor)の勝利!"
                } else {
                    statusLabel.text = "\(winnerColor) Wins!"
                }
            }

        case .draw:
            statusLabel.text = isZenTheme ? "引き分け · Draw" : "Draw!"
        }
    }

    private func placeStone(at row: Int, col: Int) {
        let player = board.currentPlayer

        if board.placeStone(at: row, col: col) {
            // Play sound and haptic feedback
            SoundManager.shared.stonePlaced()
            let stoneRadius = cellSize * 0.43
            let stone = SKShapeNode(circleOfRadius: stoneRadius)
            let highContrast = AccessibilityManager.shared.isHighContrastEnabled

            // Stone colors from theme
            let stoneColor = player == .black ? theme.blackStoneColor : theme.whiteStoneColor
            let highlightColor = player == .black ? theme.blackStoneHighlight : theme.whiteStoneHighlight

            stone.fillColor = stoneColor.skColor

            // High contrast mode: stronger borders
            if highContrast {
                stone.strokeColor = player == .black ? SKColor.white : SKColor.black
                stone.lineWidth = 3.0
            } else {
                stone.strokeColor = highlightColor.skColor.withAlphaComponent(0.8)
                stone.lineWidth = player == .black ? 2 : 2.5
            }

            stone.position = CGPoint(
                x: boardOffset.x + CGFloat(col) * cellSize,
                y: boardOffset.y + CGFloat(row) * cellSize
            )
            stone.zPosition = 5

            // Enhanced shadow for depth
            if let stoneShadow = makeShadow(for: stone, offset: CGPoint(x: 0, y: -4), alpha: 0.35) {
                stonesNode.addChild(stoneShadow)
                stoneShadow.zPosition = stone.zPosition - 0.5
            }

            // Apply stone style from theme
            switch theme.stoneStyle {
            case .classic, .glossy:
                // Multiple highlights for realistic 3D effect
                let mainHighlight = SKShapeNode(circleOfRadius: stoneRadius * 0.45)
                let mainHighlightAlpha: CGFloat = theme.stoneStyle == .glossy ? 0.35 : 0.25
                if player == .black {
                    mainHighlight.fillColor = highlightColor.skColor.withAlphaComponent(mainHighlightAlpha)
                } else {
                    mainHighlight.fillColor = SKColor(white: 1.0, alpha: theme.stoneStyle == .glossy ? 0.5 : 0.4)
                }
                mainHighlight.strokeColor = .clear
                mainHighlight.position = CGPoint(x: -stoneRadius * 0.25, y: stoneRadius * 0.25)
                stone.addChild(mainHighlight)

                // Secondary highlight for extra depth
                let secondaryHighlight = SKShapeNode(circleOfRadius: stoneRadius * 0.25)
                let secondaryAlpha: CGFloat = theme.stoneStyle == .glossy ? 0.3 : 0.2
                if player == .black {
                    secondaryHighlight.fillColor = highlightColor.skColor.withAlphaComponent(secondaryAlpha)
                } else {
                    secondaryHighlight.fillColor = SKColor(white: 1.0, alpha: theme.stoneStyle == .glossy ? 0.7 : 0.6)
                }
                secondaryHighlight.strokeColor = .clear
                secondaryHighlight.position = CGPoint(x: -stoneRadius * 0.3, y: stoneRadius * 0.3)
                stone.addChild(secondaryHighlight)

                // Rim light effect (more pronounced for glossy)
                let rimLight = SKShapeNode(circleOfRadius: stoneRadius * 0.95)
                rimLight.fillColor = .clear
                let rimAlpha: CGFloat = theme.stoneStyle == .glossy ? 0.25 : 0.15
                if player == .black {
                    rimLight.strokeColor = highlightColor.skColor.withAlphaComponent(rimAlpha)
                } else {
                    rimLight.strokeColor = SKColor(red: 0.70, green: 0.80, blue: 1.0, alpha: rimAlpha * 2)
                }
                rimLight.lineWidth = theme.stoneStyle == .glossy ? 3 : 2
                stone.addChild(rimLight)

            case .flat:
                // Flat style - no highlights, just solid color
                stone.strokeColor = .clear
            }

            // Entrance animation (reduced if accessibility setting is on)
            if AccessibilityManager.shared.shouldSkipAnimations {
                // Minimal animation for reduce motion
                stone.alpha = 0
                let fadeIn = SKAction.fadeIn(withDuration: 0.1)
                stone.run(fadeIn)
            } else {
                // Full animation with squash & stretch
                let originalY = stone.position.y
                stone.position.y += 60
                stone.alpha = 0
                stone.setScale(0.3)

                let moveAction = SKAction.moveTo(y: originalY, duration: 0.35)
                moveAction.timingMode = .easeOut

                let fadeAction = SKAction.fadeAlpha(to: 1.0, duration: 0.25)

                // Squash & stretch for juicy impact
                let scaleUp = SKAction.scale(to: 1.15, duration: 0.2)
                scaleUp.timingMode = .easeOut
                let squash = SKAction.scaleY(to: 0.85, duration: 0.08)
                squash.timingMode = .easeIn
                let stretch = SKAction.group([
                    SKAction.scaleY(to: 1.1, duration: 0.08),
                    SKAction.scaleX(to: 0.95, duration: 0.08)
                ])
                stretch.timingMode = .easeOut
                let settle = SKAction.scale(to: 1.0, duration: 0.12)
                settle.timingMode = .easeInEaseOut
                let scaleSequence = SKAction.sequence([scaleUp, squash, stretch, settle])

                let group = SKAction.group([moveAction, fadeAction, scaleSequence])
                stone.run(group)

                // Add subtle rotation for visual interest
                let rotation = SKAction.rotate(byAngle: CGFloat.random(in: -0.1...0.1), duration: 0.35)
                stone.run(rotation)
            }

            stonesNode.addChild(stone)

            // Add colorblind marker if enabled
            AccessibilityManager.shared.addColorblindMarker(to: stone, player: player, radius: stoneRadius)

            // Add particle effect (skip if reduce motion is enabled)
            if !AccessibilityManager.shared.shouldSkipAnimations {
                addPlacementParticles(at: stone.position, color: player == .black ? .black : .white)
            }

            updateStatusLabel()
            animateStatusUpdate()
            updateUndoButtonState()

            // Auto-save game state after each move (only saves if game still in progress, skip practice mode)
            if !isPracticeMode {
                GameStateManager.shared.saveGame(
                    board: board,
                    gameMode: gameMode,
                    aiDifficulty: aiDifficulty,
                    humanPlayer: humanPlayer
                )
            }

            // Check if someone won and celebrate
            if case .won(let winner) = board.gameState {
                SoundManager.shared.gameWon()
                let moveCount = board.getMoveHistory().count
                recordGameStatistics(winner: winner)
                celebrateWin(moveCount: moveCount)
            } else if gameMode == .vsAI && board.currentPlayer != humanPlayer && !isAIThinking {
                // Trigger AI move after a short delay
                isAIThinking = true
                showAIThinkingIndicator()
                let wait = SKAction.wait(forDuration: 0.5)
                let aiMove = SKAction.run { [weak self] in
                    self?.makeAIMove()
                }
                run(SKAction.sequence([wait, aiMove]))
            }
        }
    }

    private func makeAIMove() {
        guard gameMode == .vsAI && board.currentPlayer != humanPlayer else {
            isAIThinking = false
            hideAIThinkingIndicator()
            return
        }

        // Capture current state to prevent race conditions
        let currentGeneration = gameGeneration
        let boardCopy = GomokuBoard(copying: board)
        let currentPlayer = board.currentPlayer

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            if let move = self.ai.findBestMove(board: boardCopy, player: currentPlayer) {
                DispatchQueue.main.async {
                    // Only place move if game hasn't been reset
                    guard self.gameGeneration == currentGeneration else {
                        return
                    }
                    self.hideAIThinkingIndicator()
                    self.placeStone(at: move.row, col: move.col)
                    self.isAIThinking = false
                }
            } else {
                DispatchQueue.main.async {
                    guard self.gameGeneration == currentGeneration else {
                        return
                    }
                    self.hideAIThinkingIndicator()
                    self.isAIThinking = false
                }
            }
        }
    }

    private func showAIThinkingIndicator() {
        hideAIThinkingIndicator() // Remove any existing indicator

        let isZenTheme = theme.id == "zen"
        let uiFont = isZenTheme ? "Hiragino Mincho ProN" : "AvenirNext-Medium"

        let indicatorNode = SKNode()
        indicatorNode.name = "aiThinkingIndicator"
        indicatorNode.position = CGPoint(x: size.width / 2, y: size.height - 120)
        indicatorNode.zPosition = 12

        // Create three animated dots
        let dotRadius: CGFloat = 4
        let spacing: CGFloat = 12

        let dotColor = theme.statusTextColor.skColor
        let dotColors: [SKColor] = [
            dotColor,
            dotColor.withAlphaComponent(0.7),
            dotColor.withAlphaComponent(0.5)
        ]

        for i in 0..<3 {
            let dot = SKShapeNode(circleOfRadius: dotRadius)
            dot.fillColor = dotColors[i]
            dot.strokeColor = .clear
            dot.position = CGPoint(x: CGFloat(i - 1) * spacing, y: 0)

            // Bouncing animation with delay
            let moveUp = SKAction.moveBy(x: 0, y: 10, duration: 0.4)
            moveUp.timingMode = .easeInEaseOut
            let moveDown = SKAction.moveBy(x: 0, y: -10, duration: 0.4)
            moveDown.timingMode = .easeInEaseOut
            let bounce = SKAction.sequence([moveUp, moveDown])
            let wait = SKAction.wait(forDuration: Double(i) * 0.15)
            let delayedBounce = SKAction.sequence([wait, bounce])
            let repeatBounce = SKAction.repeatForever(delayedBounce)

            dot.run(repeatBounce)
            indicatorNode.addChild(dot)
        }

        // Add "AI thinking..." label
        let label = SKLabelNode(fontNamed: uiFont)
        label.text = isZenTheme ? "思考中..." : "Thinking..."
        label.fontSize = fontSize(.subheadline)
        label.fontColor = theme.statusTextColor.skColor.withAlphaComponent(0.7)
        label.position = CGPoint(x: 0, y: -20)
        label.verticalAlignmentMode = .center

        // Fade in and out
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.5)
        let fadeOut = SKAction.fadeAlpha(to: 0.5, duration: 0.5)
        let fade = SKAction.sequence([fadeIn, fadeOut])
        label.run(SKAction.repeatForever(fade))

        indicatorNode.addChild(label)
        addChild(indicatorNode)
        aiThinkingIndicator = indicatorNode
    }

    private func hideAIThinkingIndicator() {
        aiThinkingIndicator?.removeFromParent()
        aiThinkingIndicator = nil
    }

    private func addPlacementParticles(at position: CGPoint, color: UIColor) {
        for _ in 0..<8 {
            let particle = SKShapeNode(circleOfRadius: 3)
            particle.fillColor = color
            particle.strokeColor = .clear
            particle.position = position
            particle.zPosition = 4

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 20...40)
            let endX = position.x + cos(angle) * distance
            let endY = position.y + sin(angle) * distance

            let move = SKAction.move(to: CGPoint(x: endX, y: endY), duration: 0.4)
            let fade = SKAction.fadeOut(withDuration: 0.4)
            let scale = SKAction.scale(to: 0.3, duration: 0.4)
            let group = SKAction.group([move, fade, scale])
            let remove = SKAction.removeFromParent()

            particle.run(SKAction.sequence([group, remove]))
            addChild(particle)
        }
    }

    private func animateStatusUpdate() {
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.05, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ])
        statusBackground.run(pulse)
    }

    private func recordGameStatistics(winner: Player) {
        // Clear saved game since game is over
        GameStateManager.shared.clearSavedGame()

        // Skip statistics and history for practice mode
        if isPracticeMode {
            return
        }

        // Save completed game to history for replay
        GameHistoryManager.shared.saveCompletedGame(
            board: board,
            gameMode: gameMode,
            aiDifficulty: aiDifficulty,
            humanPlayer: humanPlayer,
            winner: winner
        )

        let moveCount = board.getMoveHistory().count

        if gameMode == .vsAI {
            // In AI mode, human is always black
            if winner == humanPlayer {
                // Human won
                let coinsEarned = StatisticsManager.shared.recordAIWin(difficulty: aiDifficulty, moveCount: moveCount)
                showCoinsEarnedToast(coins: coinsEarned)
            } else {
                // AI won
                let coinsEarned = StatisticsManager.shared.recordAILoss(difficulty: aiDifficulty, moveCount: moveCount)
                showCoinsEarnedToast(coins: coinsEarned)
            }
        } else {
            // Two player mode
            StatisticsManager.shared.recordFriendGame(winner: winner, moveCount: moveCount)
        }
    }

    private func celebrateWin(moveCount: Int) {
        // Check for special achievements
        let isQuickWin = moveCount <= 15 // Win in 15 moves or less
        let isPerfectWin = moveCount <= 10 // Win in 10 moves or less
        let reduceMotion = AccessibilityManager.shared.shouldSkipAnimations

        // Screen shake effect! (skip if reduce motion is enabled)
        if !reduceMotion {
            let shakeAmount: CGFloat = isPerfectWin ? 12 : (isQuickWin ? 10 : 8)
            let shakeDuration = 0.05
            let shakeActions = [
                SKAction.moveBy(x: shakeAmount, y: shakeAmount, duration: shakeDuration),
                SKAction.moveBy(x: -shakeAmount * 2, y: -shakeAmount, duration: shakeDuration),
                SKAction.moveBy(x: shakeAmount * 2, y: -shakeAmount, duration: shakeDuration),
                SKAction.moveBy(x: -shakeAmount * 2, y: shakeAmount * 2, duration: shakeDuration),
                SKAction.moveBy(x: shakeAmount * 2, y: -shakeAmount, duration: shakeDuration),
                SKAction.moveBy(x: -shakeAmount, y: -shakeAmount, duration: shakeDuration)
            ]
            let shakeSequence = SKAction.sequence(shakeActions)
            stonesNode.run(shakeSequence)
            boardBackground.run(shakeSequence)
        }

        // Highlight winning line with glowing effect
        highlightWinningLine()

        // Show special badge for achievements
        let isZenTheme = theme.id == "zen"
        if isPerfectWin {
            let text = isZenTheme ? "完璧な勝利!" : "Perfect Win!"
            showAchievementBadge(text: text, color: gold)
        } else if isQuickWin {
            let text = isZenTheme ? "速勝!" : "Quick Win!"
            showAchievementBadge(text: text, color: bamboo)
        }

        // Animate status label (simplified for reduce motion)
        if !reduceMotion {
            let scaleUp = SKAction.scale(to: 1.15, duration: 0.3)
            scaleUp.timingMode = .easeOut
            let scaleDown = SKAction.scale(to: 1.0, duration: 0.2)
            scaleDown.timingMode = .easeInEaseOut
            let bounce = SKAction.sequence([scaleUp, scaleDown])
            statusLabel.run(bounce)
        }

        // Confetti particles around the board (skip if reduce motion is enabled)
        if !reduceMotion {
            let centerX = size.width / 2
            let centerY = boardOffset.y + (cellSize * CGFloat(board.size) / 2)

            for _ in 0..<50 {
                let confetti = SKShapeNode(circleOfRadius: CGFloat.random(in: 4...7))
                let colors: [SKColor] = [
                    SKColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0),
                    SKColor(red: 0.3, green: 0.8, blue: 1.0, alpha: 1.0),
                    SKColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0),
                    SKColor(red: 0.5, green: 1.0, blue: 0.5, alpha: 1.0),
                    SKColor(red: 1.0, green: 0.5, blue: 1.0, alpha: 1.0)
                ]
                confetti.fillColor = colors.randomElement()!
                confetti.strokeColor = .clear
                confetti.position = CGPoint(x: centerX, y: centerY)
                confetti.zPosition = 20

                let angle = CGFloat.random(in: 0...(2 * .pi))
                let distance = CGFloat.random(in: 100...250)
                let endX = centerX + cos(angle) * distance
                let endY = centerY + sin(angle) * distance

                let move = SKAction.move(to: CGPoint(x: endX, y: endY), duration: 1.2)
                move.timingMode = .easeOut
                let fade = SKAction.fadeOut(withDuration: 1.0)
                let rotate = SKAction.rotate(byAngle: CGFloat.random(in: -3...3), duration: 1.2)
                let group = SKAction.group([move, fade, rotate])
                let remove = SKAction.removeFromParent()

                confetti.run(SKAction.sequence([group, remove]))
                addChild(confetti)
            }
        }

        // Pulse the board (skip if reduce motion is enabled)
        let boardPulse: SKAction
        if reduceMotion {
            boardPulse = SKAction.wait(forDuration: 0.1)
        } else {
            boardPulse = SKAction.sequence([
                SKAction.scale(to: 1.02, duration: 0.2),
                SKAction.scale(to: 1.0, duration: 0.2)
            ])
        }
        boardBackground.run(boardPulse)

        // Show share button
        showShareButton()
    }

    private func highlightWinningLine() {
        guard !board.winningPositions.isEmpty else { return }

        for (row, col) in board.winningPositions {
            let position = CGPoint(
                x: boardOffset.x + CGFloat(col) * cellSize,
                y: boardOffset.y + CGFloat(row) * cellSize
            )

            // Create pulsing glow effect
            let stoneRadius = cellSize * 0.43
            let glow = SKShapeNode(circleOfRadius: stoneRadius * 1.3)
            glow.fillColor = .clear
            glow.strokeColor = SKColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 0.8)
            glow.lineWidth = 4
            glow.position = position
            glow.zPosition = 6
            glow.name = "winGlow"

            // Ensure glow stays centered during scaling
            glow.setScale(1.0)

            // Pulsing animation
            let pulseUp = SKAction.scale(to: 1.2, duration: 0.6)
            pulseUp.timingMode = .easeInEaseOut
            let pulseDown = SKAction.scale(to: 1.0, duration: 0.6)
            pulseDown.timingMode = .easeInEaseOut
            let pulse = SKAction.sequence([pulseUp, pulseDown])
            let repeatPulse = SKAction.repeatForever(pulse)

            // Fade in and out
            let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.3)
            let fadeOut = SKAction.fadeAlpha(to: 0.3, duration: 0.6)
            let fade = SKAction.sequence([fadeIn, fadeOut])
            let repeatFade = SKAction.repeatForever(fade)

            glow.run(SKAction.group([repeatPulse, repeatFade]))
            stonesNode.addChild(glow)
        }
    }

    private func showAchievementBadge(text: String, color: SKColor) {
        let isZenTheme = theme.id == "zen"
        let uiFont = isZenTheme ? "Hiragino Mincho ProN" : "AvenirNext-DemiBold"

        // Create badge background
        let badge = SKShapeNode(rectOf: CGSize(width: 200, height: 55), cornerRadius: 12)
        badge.fillColor = color
        badge.strokeColor = SKColor.white.withAlphaComponent(0.4)
        badge.lineWidth = 2
        badge.position = CGPoint(x: size.width / 2, y: size.height / 2 + 150)
        badge.zPosition = 25
        badge.alpha = 0
        badge.setScale(0.5)

        // Badge label
        let label = SKLabelNode(fontNamed: uiFont)
        label.text = text
        label.fontSize = fontSize(.title2)
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        badge.addChild(label)

        // Star particles around badge
        for _ in 0..<20 {
            let star = SKShapeNode(circleOfRadius: 3)
            star.fillColor = .white
            star.strokeColor = .clear
            star.position = badge.position
            star.zPosition = 24

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 80...120)
            let endX = badge.position.x + cos(angle) * distance
            let endY = badge.position.y + sin(angle) * distance

            let move = SKAction.move(to: CGPoint(x: endX, y: endY), duration: 1.0)
            move.timingMode = .easeOut
            let fade = SKAction.fadeOut(withDuration: 0.8)
            let scale = SKAction.scale(to: 0.1, duration: 1.0)
            let group = SKAction.group([move, fade, scale])
            let remove = SKAction.removeFromParent()

            star.run(SKAction.sequence([group, remove]))
            addChild(star)
        }

        // Badge entrance animation
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.3)
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.3)
        scaleUp.timingMode = .easeOut
        let bounce = SKAction.scale(to: 1.0, duration: 0.15)
        bounce.timingMode = .easeInEaseOut
        let entrance = SKAction.sequence([
            SKAction.group([fadeIn, scaleUp]),
            bounce
        ])

        // Hold and then fade out
        let wait = SKAction.wait(forDuration: 2.5)
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let moveUp = SKAction.moveBy(x: 0, y: 50, duration: 0.5)
        let exit = SKAction.group([fadeOut, moveUp])
        let remove = SKAction.removeFromParent()

        badge.run(SKAction.sequence([entrance, wait, exit, remove]))
        addChild(badge)
    }

    private func showCoinsEarnedToast(coins: Int) {
        guard coins > 0 else { return }

        let isZenTheme = theme.id == "zen"
        let uiFont = isZenTheme ? "Hiragino Mincho ProN" : "AvenirNext-DemiBold"

        // Create coin toast container
        let toast = SKNode()
        toast.position = CGPoint(x: size.width / 2, y: size.height - 180)
        toast.zPosition = 100
        toast.alpha = 0
        toast.setScale(0.5)

        // Background
        let background = SKShapeNode(rectOf: CGSize(width: 120, height: 44), cornerRadius: 12)
        background.fillColor = gold
        background.strokeColor = SKColor(red: 0.7, green: 0.55, blue: 0.2, alpha: 1.0)
        background.lineWidth = 1.5
        toast.addChild(background)

        // Coin icon
        let coinIcon = SKShapeNode(circleOfRadius: 10)
        coinIcon.fillColor = SKColor(red: 1.0, green: 0.9, blue: 0.5, alpha: 1.0)
        coinIcon.strokeColor = SKColor(red: 0.7, green: 0.55, blue: 0.2, alpha: 1.0)
        coinIcon.lineWidth = 1.5
        coinIcon.position = CGPoint(x: -35, y: 0)
        toast.addChild(coinIcon)

        // Coin text
        let label = SKLabelNode(fontNamed: uiFont)
        label.text = "+\(coins)"
        label.fontSize = fontSize(.title2)
        label.fontColor = SKColor(red: 0.30, green: 0.22, blue: 0.10, alpha: 1.0)
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .left
        label.position = CGPoint(x: -15, y: 0)
        toast.addChild(label)

        addChild(toast)

        // Animate in, hold, animate out
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.3)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.3)
        scaleUp.timingMode = .easeOut
        let entrance = SKAction.group([fadeIn, scaleUp])

        let wait = SKAction.wait(forDuration: 2.0)

        let moveUp = SKAction.moveBy(x: 0, y: 30, duration: 0.4)
        let fadeOut = SKAction.fadeOut(withDuration: 0.4)
        let exit = SKAction.group([moveUp, fadeOut])

        let remove = SKAction.removeFromParent()

        toast.run(SKAction.sequence([entrance, wait, exit, remove]))
    }

    private func showShareButton() {
        // Remove any existing share button
        shareButton?.removeFromParent()
        shareButtonBackground?.removeFromParent()

        let isZenTheme = theme.id == "zen"
        let uiFont = isZenTheme ? "Hiragino Mincho ProN" : "AvenirNext-Medium"

        // Create share button background
        shareButtonBackground = SKShapeNode(rectOf: CGSize(width: 120, height: 44), cornerRadius: 12)
        shareButtonBackground?.fillColor = theme.buttonBackgroundColor.skColor
        shareButtonBackground?.strokeColor = theme.buttonStrokeColor.skColor
        shareButtonBackground?.lineWidth = 1.5
        shareButtonBackground?.position = CGPoint(x: size.width / 2, y: 110)
        shareButtonBackground?.name = "shareButton"
        shareButtonBackground?.zPosition = 10
        shareButtonBackground?.alpha = 0
        shareButtonBackground?.setScale(0.8)

        if let bg = shareButtonBackground {
            addChild(bg)
        }

        // Create share button label
        shareButton = SKLabelNode(fontNamed: uiFont)
        shareButton?.text = isZenTheme ? "共有 · Share" : "Share"
        shareButton?.fontSize = fontSize(.headline)
        shareButton?.fontColor = theme.buttonTextColor.skColor
        shareButton?.position = CGPoint(x: size.width / 2, y: 110)
        shareButton?.name = "shareButton"
        shareButton?.verticalAlignmentMode = .center
        shareButton?.zPosition = 11
        shareButton?.alpha = 0

        if let btn = shareButton {
            addChild(btn)
        }

        // Animate in
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.4)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.4)
        scaleUp.timingMode = .easeOut
        let entrance = SKAction.group([fadeIn, scaleUp])
        let delay = SKAction.wait(forDuration: 1.5)

        shareButtonBackground?.run(SKAction.sequence([delay, entrance]))
        shareButton?.run(SKAction.sequence([delay, entrance]))
    }

    private func hideShareButton() {
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let scaleDown = SKAction.scale(to: 0.8, duration: 0.3)
        let exit = SKAction.group([fadeOut, scaleDown])
        let remove = SKAction.removeFromParent()

        shareButtonBackground?.run(SKAction.sequence([exit, remove]))
        shareButton?.run(SKAction.sequence([exit, remove]))
    }

    private func shareScreenshot() {
        guard let view = self.view else { return }

        SoundManager.shared.buttonTapped()

        // Capture the view as an image
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, UIScreen.main.scale)
        view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        let screenshot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let image = screenshot else { return }

        // Present share sheet
        let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: nil)

        // For iPad support
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        // Present from the view controller
        if let viewController = view.window?.rootViewController {
            viewController.present(activityViewController, animated: true)
        }
    }

    private func goBackToMenu() {
        let transition = SKTransition.fade(withDuration: 0.5)
        let menuScene = MenuScene(size: size)
        menuScene.scaleMode = .aspectFill
        view?.presentScene(menuScene, transition: transition)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodes = self.nodes(at: location)

        // Handle coin paywall interactions first (it's on top)
        if coinPaywallNode != nil {
            if nodes.contains(where: { $0.name == "closeCoinPaywall" }) {
                SoundManager.shared.buttonTapped()
                hideCoinPaywall()
                return
            }

            for node in nodes {
                if let name = node.name, name.hasPrefix("coinPaywallPack_") {
                    let packId = String(name.dropFirst("coinPaywallPack_".count))
                    if let pack = CoinPack.allCases.first(where: { $0.rawValue == packId }) {
                        handleCoinPaywallPurchase(pack)
                        return
                    }
                }
            }
            return // Don't process other touches when coin paywall is open
        }

        // Handle hint paywall interactions
        if hintPaywallNode != nil {
            // Check for close button
            if nodes.contains(where: { $0.name == "closePaywall" }) {
                SoundManager.shared.buttonTapped()
                hideHintPaywall()
                return
            }

            // Check for "Get More Coins" button
            if nodes.contains(where: { $0.name == "getMoreCoins" }) {
                SoundManager.shared.buttonTapped()
                showCoinPaywall()
                return
            }

            // Check for hint pack purchases
            for node in nodes {
                if let name = node.name, name.hasPrefix("paywallPack_") {
                    let packId = String(name.dropFirst("paywallPack_".count))
                    if let pack = HintPack.allCases.first(where: { $0.rawValue == packId }) {
                        handlePaywallPurchase(pack)
                        return
                    }
                }
            }

            // Check for tapping the overlay background to close
            if nodes.contains(where: { $0.name == "paywallOverlay" }) {
                SoundManager.shared.buttonTapped()
                hideHintPaywall()
                return
            }

            // Block other interactions while paywall is shown
            return
        }

        // Check if back button was tapped
        if nodes.contains(where: { $0.name == "backButton" }) {
            SoundManager.shared.buttonTapped()
            goBackToMenu()
            return
        }

        // Check if reset button was tapped
        if nodes.contains(where: { $0.name == "resetButton" }) {
            animateButtonPress()
            resetGame()
            return
        }

        // Check if undo button was tapped
        if nodes.contains(where: { $0.name == "undoButton" }) {
            if board.canUndo() {
                animateUndoButtonPress()
                undoLastMove()
            }
            return
        }

        // Check if hint button was tapped
        if nodes.contains(where: { $0.name == "hintButton" }) {
            handleHintTap()
            return
        }

        // Check if confirm button was tapped
        if nodes.contains(where: { $0.name == "confirmButton" }) {
            confirmPendingMove()
            return
        }

        // Check if cancel button was tapped
        if nodes.contains(where: { $0.name == "cancelButton" }) {
            cancelPendingMove()
            return
        }

        // Check if share button was tapped
        if nodes.contains(where: { $0.name == "shareButton" }) {
            animateShareButtonPress()
            shareScreenshot()
            return
        }

        // Check if tap is on the board
        guard case .playing = board.gameState else { return }

        // Prevent interaction if AI is thinking
        if gameMode == .vsAI && isAIThinking {
            return
        }

        // In AI mode, only allow human player to move
        if gameMode == .vsAI && board.currentPlayer != humanPlayer {
            return
        }

        let boardLocation = CGPoint(
            x: location.x - boardOffset.x,
            y: location.y - boardOffset.y
        )

        // Convert to grid coordinates with proper snapping to intersections
        let col = Int((boardLocation.x / cellSize).rounded())
        let row = Int((boardLocation.y / cellSize).rounded())

        // Check if the position is valid and empty
        if row >= 0 && row < board.size && col >= 0 && col < board.size && board.getPlayer(at: row, col: col) == .none {
            // Show preview stone and confirmation buttons
            showMovePreview(at: row, col: col)
        }
    }

    // MARK: - Move Confirmation System

    private func showMovePreview(at row: Int, col: Int) {
        // Remove any existing preview
        clearMovePreview()
        clearHintStone()

        pendingMove = (row, col)

        let stoneRadius = cellSize * 0.43
        let position = CGPoint(
            x: boardOffset.x + CGFloat(col) * cellSize,
            y: boardOffset.y + CGFloat(row) * cellSize
        )

        // Create preview stone with pulsing effect
        previewStone = SKShapeNode(circleOfRadius: stoneRadius)
        let stoneColor = board.currentPlayer == .black ? theme.blackStoneColor : theme.whiteStoneColor
        let highlightColor = board.currentPlayer == .black ? theme.blackStoneHighlight : theme.whiteStoneHighlight

        previewStone?.fillColor = stoneColor.skColor.withAlphaComponent(0.7)
        previewStone?.strokeColor = highlightColor.skColor
        previewStone?.lineWidth = 3
        previewStone?.position = position
        previewStone?.zPosition = 6

        // Add pulsing animation
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.08, duration: 0.5),
            SKAction.scale(to: 1.0, duration: 0.5)
        ])
        previewStone?.run(SKAction.repeatForever(pulse))

        // Add glow effect
        let glow = SKShapeNode(circleOfRadius: stoneRadius * 1.3)
        glow.fillColor = .clear
        glow.strokeColor = SKColor(red: 0.3, green: 0.8, blue: 0.5, alpha: 0.6)
        glow.lineWidth = 3
        glow.name = "previewGlow"
        previewStone?.addChild(glow)

        if let stone = previewStone {
            addChild(stone)
        }

        // Show confirm/cancel buttons near the preview stone
        showConfirmationButtons(near: position)

        SoundManager.shared.hapticLight()
    }

    private func showConfirmationButtons(near position: CGPoint) {
        let buttonY = max(120, position.y - 70) // Don't go below bottom UI
        let isZenTheme = theme.id == "zen"
        let buttonRadius: CGFloat = 26
        let buttonSpacing: CGFloat = 45
        let edgePadding: CGFloat = 40

        // Determine button positions based on screen edges
        var confirmX: CGFloat
        var cancelX: CGFloat

        let nearRightEdge = position.x + buttonSpacing + buttonRadius > size.width - edgePadding
        let nearLeftEdge = position.x - buttonSpacing - buttonRadius < edgePadding

        if nearRightEdge {
            // Both buttons go to the left of the stone
            confirmX = position.x - buttonSpacing
            cancelX = position.x - buttonSpacing - 60  // Stack them horizontally to the left
        } else if nearLeftEdge {
            // Both buttons go to the right of the stone
            cancelX = position.x + buttonSpacing
            confirmX = position.x + buttonSpacing + 60  // Stack them horizontally to the right
        } else {
            // Default: confirm right, cancel left
            confirmX = position.x + buttonSpacing
            cancelX = position.x - buttonSpacing
        }

        // Confirm button - green style
        confirmButton = SKShapeNode(circleOfRadius: buttonRadius)
        confirmButton?.fillColor = bamboo
        confirmButton?.strokeColor = SKColor.white.withAlphaComponent(0.3)
        confirmButton?.lineWidth = 1.5
        confirmButton?.position = CGPoint(x: confirmX, y: buttonY)
        confirmButton?.name = "confirmButton"
        confirmButton?.zPosition = 20

        confirmButtonLabel = SKLabelNode(fontNamed: isZenTheme ? "Hiragino Mincho ProN" : "AvenirNext-Bold")
        confirmButtonLabel?.text = isZenTheme ? "決" : "✓"
        confirmButtonLabel?.fontSize = isZenTheme ? fontSize(.title2) : fontSize(.title)
        confirmButtonLabel?.fontColor = .white
        confirmButtonLabel?.verticalAlignmentMode = .center
        confirmButtonLabel?.horizontalAlignmentMode = .center
        confirmButtonLabel?.position = .zero
        confirmButtonLabel?.name = "confirmButton"

        if let btn = confirmButton, let label = confirmButtonLabel {
            btn.addChild(label)
            addChild(btn)

            // Entrance animation
            btn.setScale(0.5)
            btn.alpha = 0
            let scaleUp = SKAction.scale(to: 1.0, duration: 0.2)
            let fadeIn = SKAction.fadeIn(withDuration: 0.2)
            btn.run(SKAction.group([scaleUp, fadeIn]))
        }

        // Cancel button - red style
        cancelButton = SKShapeNode(circleOfRadius: buttonRadius)
        cancelButton?.fillColor = accentRed
        cancelButton?.strokeColor = SKColor.white.withAlphaComponent(0.3)
        cancelButton?.lineWidth = 1.5
        cancelButton?.position = CGPoint(x: cancelX, y: buttonY)
        cancelButton?.name = "cancelButton"
        cancelButton?.zPosition = 20

        cancelButtonLabel = SKLabelNode(fontNamed: isZenTheme ? "Hiragino Mincho ProN" : "AvenirNext-Bold")
        cancelButtonLabel?.text = isZenTheme ? "消" : "✕"
        cancelButtonLabel?.fontSize = isZenTheme ? fontSize(.title2) : fontSize(.title2)
        cancelButtonLabel?.fontColor = .white
        cancelButtonLabel?.verticalAlignmentMode = .center
        cancelButtonLabel?.horizontalAlignmentMode = .center
        cancelButtonLabel?.position = .zero
        cancelButtonLabel?.name = "cancelButton"

        if let btn = cancelButton, let label = cancelButtonLabel {
            btn.addChild(label)
            addChild(btn)

            // Entrance animation
            btn.setScale(0.5)
            btn.alpha = 0
            let scaleUp = SKAction.scale(to: 1.0, duration: 0.2)
            let fadeIn = SKAction.fadeIn(withDuration: 0.2)
            btn.run(SKAction.group([scaleUp, fadeIn]))
        }
    }

    private func confirmPendingMove() {
        guard let move = pendingMove else { return }

        SoundManager.shared.buttonTapped()

        // Clear preview UI
        clearMovePreview()

        // Actually place the stone
        placeStone(at: move.row, col: move.col)

        pendingMove = nil
    }

    private func cancelPendingMove() {
        SoundManager.shared.buttonTapped()
        clearMovePreview()
        pendingMove = nil
    }

    private func clearMovePreview() {
        // Animate out and remove
        let fadeOut = SKAction.fadeOut(withDuration: 0.15)
        let scaleDown = SKAction.scale(to: 0.5, duration: 0.15)
        let group = SKAction.group([fadeOut, scaleDown])
        let remove = SKAction.removeFromParent()

        previewStone?.run(SKAction.sequence([group, remove]))
        confirmButton?.run(SKAction.sequence([group, remove]))
        cancelButton?.run(SKAction.sequence([group, remove]))

        previewStone = nil
        confirmButton = nil
        confirmButtonLabel = nil
        cancelButton = nil
        cancelButtonLabel = nil
    }

    // MARK: - Hint System

    private func handleHintTap() {
        guard case .playing = board.gameState else { return }
        guard gameMode == .vsAI else { return }
        guard !isAIThinking else { return }
        guard board.currentPlayer == humanPlayer else { return }

        if HintManager.shared.hasHints {
            // Use a hint and show it
            HintManager.shared.useHint()
            showHint()
        } else {
            showNoHintsAvailable()
        }
    }

    private func showHint() {
        SoundManager.shared.buttonTapped()

        // Clear any existing hint or preview
        clearHintStone()
        clearMovePreview()
        pendingMove = nil

        // Use AI to find the best move for the human player
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            if let move = self.ai.findBestMove(board: self.board, player: self.humanPlayer) {
                DispatchQueue.main.async {
                    self.displayHintStone(at: move.row, col: move.col)
                }
            }
        }
    }

    private func displayHintStone(at row: Int, col: Int) {
        let stoneRadius = cellSize * 0.43
        let position = CGPoint(
            x: boardOffset.x + CGFloat(col) * cellSize,
            y: boardOffset.y + CGFloat(row) * cellSize
        )

        // Create hint indicator (glowing ring)
        hintStone = SKShapeNode(circleOfRadius: stoneRadius * 1.2)
        hintStone?.fillColor = .clear
        hintStone?.strokeColor = SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 0.9)
        hintStone?.lineWidth = 4
        hintStone?.position = position
        hintStone?.zPosition = 7
        hintStone?.name = "hintStone"

        // Add inner glow
        let innerGlow = SKShapeNode(circleOfRadius: stoneRadius * 0.8)
        innerGlow.fillColor = SKColor(red: 1.0, green: 0.9, blue: 0.5, alpha: 0.3)
        innerGlow.strokeColor = .clear
        hintStone?.addChild(innerGlow)

        // Pulsing animation
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.15, duration: 0.6),
            SKAction.scale(to: 1.0, duration: 0.6)
        ])
        hintStone?.run(SKAction.repeatForever(pulse))

        // Fade out after a few seconds
        let wait = SKAction.wait(forDuration: 5.0)
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let remove = SKAction.removeFromParent()
        hintStone?.run(SKAction.sequence([wait, fadeOut, remove]))

        if let hint = hintStone {
            addChild(hint)
        }

        // Show toast
        showHintToast()
    }

    private func clearHintStone() {
        hintStone?.removeFromParent()
        hintStone = nil
    }

    private func showHintToast() {
        let isZenTheme = theme.id == "zen"
        let uiFont = isZenTheme ? "Hiragino Mincho ProN" : "AvenirNext-Medium"

        let toast = SKNode()
        toast.position = CGPoint(x: size.width / 2, y: size.height / 2 + 100)
        toast.zPosition = 100
        toast.alpha = 0
        toast.setScale(0.8)

        // Background
        let background = SKShapeNode(rectOf: CGSize(width: 160, height: 45), cornerRadius: 12)
        background.fillColor = gold
        background.strokeColor = SKColor(red: 0.7, green: 0.55, blue: 0.2, alpha: 1.0)
        background.lineWidth = 1.5
        toast.addChild(background)

        let label = SKLabelNode(fontNamed: uiFont)
        label.text = isZenTheme ? "推奨手 · Hint" : "Suggested Move"
        label.fontSize = fontSize(.body)
        label.fontColor = SKColor(red: 0.30, green: 0.22, blue: 0.10, alpha: 1.0)
        label.verticalAlignmentMode = .center
        toast.addChild(label)

        addChild(toast)

        // Animate
        let fadeIn = SKAction.fadeIn(withDuration: 0.25)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.25)
        let entrance = SKAction.group([fadeIn, scaleUp])
        let wait = SKAction.wait(forDuration: 2.0)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let remove = SKAction.removeFromParent()

        toast.run(SKAction.sequence([entrance, wait, fadeOut, remove]))
    }

    private func showNoHintsAvailable() {
        showHintPaywall()
    }

    // MARK: - Hint Paywall

    private var hintPaywallNode: SKNode?
    private var coinPaywallNode: SKNode?

    private func showHintPaywall() {
        // Don't show if already visible
        guard hintPaywallNode == nil else { return }

        let isZenTheme = theme.id == "zen"
        let uiFont = isZenTheme ? "Hiragino Mincho ProN" : "AvenirNext-Medium"
        let uiFontBold = isZenTheme ? "Hiragino Mincho ProN" : "AvenirNext-DemiBold"

        // Premium colors
        let gold = SKColor(red: 0.92, green: 0.75, blue: 0.30, alpha: 1.0)
        let goldDark = SKColor(red: 0.75, green: 0.58, blue: 0.18, alpha: 1.0)
        let goldLight = SKColor(red: 1.0, green: 0.88, blue: 0.55, alpha: 1.0)
        let hintGreen = SKColor(red: 0.35, green: 0.65, blue: 0.45, alpha: 1.0)

        // Create container
        let container = SKNode()
        container.zPosition = 500
        container.alpha = 0
        hintPaywallNode = container

        // Semi-transparent background with blur effect simulation
        let overlay = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height))
        overlay.fillColor = SKColor.black.withAlphaComponent(0.65)
        overlay.strokeColor = .clear
        overlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.name = "paywallOverlay"
        container.addChild(overlay)

        // Main card with shadow
        let cardWidth: CGFloat = 300
        let cardHeight: CGFloat = 420
        let centerX = size.width / 2
        let centerY = size.height / 2

        // Card shadow
        let cardShadow = SKShapeNode(rectOf: CGSize(width: cardWidth, height: cardHeight), cornerRadius: 20)
        cardShadow.fillColor = SKColor.black.withAlphaComponent(0.3)
        cardShadow.strokeColor = .clear
        cardShadow.position = CGPoint(x: centerX + 4, y: centerY - 6)
        container.addChild(cardShadow)

        // Main card
        let card = SKShapeNode(rectOf: CGSize(width: cardWidth, height: cardHeight), cornerRadius: 20)
        card.fillColor = SKColor.white
        card.strokeColor = gold.withAlphaComponent(0.4)
        card.lineWidth = 2
        card.position = CGPoint(x: centerX, y: centerY)
        container.addChild(card)

        // Decorative top accent
        let topAccent = SKShapeNode(rectOf: CGSize(width: cardWidth - 40, height: 4), cornerRadius: 2)
        topAccent.fillColor = gold
        topAccent.strokeColor = .clear
        topAccent.position = CGPoint(x: centerX, y: centerY + cardHeight / 2 - 20)
        container.addChild(topAccent)

        // Large lightbulb icon at top
        let bulbContainer = SKNode()
        bulbContainer.position = CGPoint(x: centerX, y: centerY + cardHeight / 2 - 60)
        container.addChild(bulbContainer)

        // Glow behind bulb
        let bulbGlow = SKShapeNode(circleOfRadius: 30)
        bulbGlow.fillColor = SKColor.yellow.withAlphaComponent(0.2)
        bulbGlow.strokeColor = .clear
        bulbContainer.addChild(bulbGlow)

        let bulbIcon = SKLabelNode(text: "💡")
        bulbIcon.fontSize = scaledFontSize(44)
        bulbIcon.verticalAlignmentMode = .center
        bulbContainer.addChild(bulbIcon)

        // Pulsing glow animation
        let glowPulse = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 1.0),
            SKAction.scale(to: 1.0, duration: 1.0)
        ])
        bulbGlow.run(SKAction.repeatForever(glowPulse))

        // Title
        let title = SKLabelNode(fontNamed: uiFontBold)
        title.text = isZenTheme ? "助言が必要？" : "Need a Hint?"
        title.fontSize = fontSize(.title)
        title.fontColor = SKColor(red: 0.2, green: 0.2, blue: 0.25, alpha: 1.0)
        title.position = CGPoint(x: centerX, y: centerY + cardHeight / 2 - 110)
        container.addChild(title)

        // Coin balance display - styled card
        let balanceContainer = SKNode()
        balanceContainer.position = CGPoint(x: centerX, y: centerY + cardHeight / 2 - 150)
        container.addChild(balanceContainer)

        let balanceBg = SKShapeNode(rectOf: CGSize(width: 130, height: 36), cornerRadius: 18)
        balanceBg.fillColor = SKColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)
        balanceBg.strokeColor = gold.withAlphaComponent(0.5)
        balanceBg.lineWidth = 1.5
        balanceContainer.addChild(balanceBg)

        let coinIcon = SKShapeNode(circleOfRadius: 10)
        coinIcon.fillColor = gold
        coinIcon.strokeColor = goldDark
        coinIcon.lineWidth = 1.5
        coinIcon.position = CGPoint(x: -42, y: 0)
        balanceContainer.addChild(coinIcon)

        // Coin shine
        let coinShine = SKShapeNode(circleOfRadius: 4)
        coinShine.fillColor = goldLight.withAlphaComponent(0.6)
        coinShine.strokeColor = .clear
        coinShine.position = CGPoint(x: -45, y: 3)
        balanceContainer.addChild(coinShine)

        let balanceLabel = SKLabelNode(fontNamed: uiFontBold)
        balanceLabel.text = "\(CoinManager.shared.balance)"
        balanceLabel.fontSize = fontSize(.headline)
        balanceLabel.fontColor = goldDark
        balanceLabel.horizontalAlignmentMode = .left
        balanceLabel.verticalAlignmentMode = .center
        balanceLabel.position = CGPoint(x: -25, y: 0)
        balanceLabel.name = "balanceLabel"
        balanceContainer.addChild(balanceLabel)

        // Hint pack options
        let packs = HintPack.allCases
        let packStartY = centerY + 35
        let packSpacing: CGFloat = 62

        for (index, pack) in packs.enumerated() {
            let packY = packStartY - CGFloat(index) * packSpacing
            let packNode = createHintPackOption(pack: pack, at: CGPoint(x: centerX, y: packY), uiFont: uiFont, uiFontBold: uiFontBold, isZenTheme: isZenTheme, gold: gold, goldDark: goldDark, goldLight: goldLight, hintGreen: hintGreen)
            packNode.name = "paywallPack_\(pack.rawValue)"
            container.addChild(packNode)
        }

        // Close button - X in corner
        let closeButton = SKNode()
        closeButton.position = CGPoint(x: centerX + cardWidth / 2 - 25, y: centerY + cardHeight / 2 - 25)
        closeButton.name = "closePaywall"
        container.addChild(closeButton)

        let closeBg = SKShapeNode(circleOfRadius: 14)
        closeBg.fillColor = SKColor(red: 0.9, green: 0.9, blue: 0.92, alpha: 1.0)
        closeBg.strokeColor = SKColor(red: 0.8, green: 0.8, blue: 0.82, alpha: 1.0)
        closeBg.lineWidth = 1
        closeBg.name = "closePaywall"
        closeButton.addChild(closeBg)

        let closeX = SKLabelNode(fontNamed: uiFontBold)
        closeX.text = "✕"
        closeX.fontSize = fontSize(.callout)
        closeX.fontColor = SKColor(red: 0.5, green: 0.5, blue: 0.55, alpha: 1.0)
        closeX.verticalAlignmentMode = .center
        closeX.horizontalAlignmentMode = .center
        closeX.position = CGPoint(x: 0, y: 0)
        closeX.name = "closePaywall"
        closeButton.addChild(closeX)

        // "Get More Coins" button
        let getCoinsButton = SKNode()
        getCoinsButton.position = CGPoint(x: centerX, y: centerY - cardHeight / 2 + 70)
        getCoinsButton.name = "getMoreCoins"
        container.addChild(getCoinsButton)

        let getCoinsBg = SKShapeNode(rectOf: CGSize(width: 150, height: 34), cornerRadius: 17)
        getCoinsBg.fillColor = gold
        getCoinsBg.strokeColor = goldDark
        getCoinsBg.lineWidth = 1.5
        getCoinsBg.name = "getMoreCoins"
        getCoinsButton.addChild(getCoinsBg)

        let getCoinsLabel = SKLabelNode(fontNamed: uiFontBold)
        getCoinsLabel.text = isZenTheme ? "🪙 コインを購入" : "🪙 Get More Coins"
        getCoinsLabel.fontSize = fontSize(.subheadline)
        getCoinsLabel.fontColor = SKColor(red: 0.35, green: 0.25, blue: 0.10, alpha: 1.0)
        getCoinsLabel.verticalAlignmentMode = .center
        getCoinsLabel.name = "getMoreCoins"
        getCoinsButton.addChild(getCoinsLabel)

        // "No thanks" text at bottom
        let noThanks = SKLabelNode(fontNamed: uiFont)
        noThanks.text = isZenTheme ? "閉じる" : "No thanks"
        noThanks.fontSize = fontSize(.subheadline)
        noThanks.fontColor = SKColor(red: 0.5, green: 0.5, blue: 0.55, alpha: 1.0)
        noThanks.position = CGPoint(x: centerX, y: centerY - cardHeight / 2 + 30)
        noThanks.name = "closePaywall"
        container.addChild(noThanks)

        addChild(container)

        // Animate in with scale
        container.setScale(0.9)
        let fadeIn = SKAction.fadeIn(withDuration: 0.2)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.2)
        scaleUp.timingMode = .easeOut
        container.run(SKAction.group([fadeIn, scaleUp]))
    }

    private func createHintPackOption(pack: HintPack, at position: CGPoint, uiFont: String, uiFontBold: String, isZenTheme: Bool, gold: SKColor, goldDark: SKColor, goldLight: SKColor, hintGreen: SKColor) -> SKNode {
        let container = SKNode()
        container.position = position

        let canAfford = CoinManager.shared.balance >= pack.coinCost
        let isBestValue = pack == .large
        let optionWidth: CGFloat = 260
        let optionHeight: CGFloat = 50

        // Shadow
        let shadow = SKShapeNode(rectOf: CGSize(width: optionWidth - 4, height: optionHeight - 4), cornerRadius: 12)
        shadow.fillColor = SKColor.black.withAlphaComponent(canAfford ? 0.08 : 0.04)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 2, y: -2)
        shadow.zPosition = -1
        container.addChild(shadow)

        // Background
        let bg = SKShapeNode(rectOf: CGSize(width: optionWidth, height: optionHeight), cornerRadius: 12)
        if canAfford {
            bg.fillColor = isBestValue ? hintGreen.withAlphaComponent(0.12) : SKColor(red: 0.96, green: 0.96, blue: 0.97, alpha: 1.0)
            bg.strokeColor = isBestValue ? hintGreen.withAlphaComponent(0.5) : SKColor(red: 0.88, green: 0.88, blue: 0.9, alpha: 1.0)
        } else {
            bg.fillColor = SKColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 0.6)
            bg.strokeColor = SKColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 0.5)
        }
        bg.lineWidth = 1.5
        bg.name = "paywallPack_\(pack.rawValue)"
        container.addChild(bg)

        // Best value badge
        if isBestValue && canAfford {
            let badge = SKShapeNode(rectOf: CGSize(width: 50, height: 14), cornerRadius: 7)
            badge.fillColor = hintGreen
            badge.strokeColor = .clear
            badge.position = CGPoint(x: 0, y: optionHeight / 2 + 2)
            badge.zPosition = 5
            container.addChild(badge)

            let badgeLabel = SKLabelNode(fontNamed: uiFontBold)
            badgeLabel.text = "BEST"
            badgeLabel.fontSize = fontSize(.caption2)
            badgeLabel.fontColor = .white
            badgeLabel.verticalAlignmentMode = .center
            badgeLabel.position = CGPoint(x: 0, y: optionHeight / 2 + 2)
            badgeLabel.zPosition = 6
            container.addChild(badgeLabel)
        }

        // Lightbulb icon with glow
        let iconContainer = SKNode()
        iconContainer.position = CGPoint(x: -optionWidth / 2 + 30, y: 0)
        container.addChild(iconContainer)

        if canAfford {
            let iconGlow = SKShapeNode(circleOfRadius: 14)
            iconGlow.fillColor = SKColor.yellow.withAlphaComponent(0.15)
            iconGlow.strokeColor = .clear
            iconContainer.addChild(iconGlow)
        }

        let icon = SKLabelNode(text: "💡")
        icon.fontSize = fontSize(.title)
        icon.verticalAlignmentMode = .center
        icon.alpha = canAfford ? 1.0 : 0.4
        iconContainer.addChild(icon)

        // Pack name and count
        let nameLabel = SKLabelNode(fontNamed: uiFontBold)
        nameLabel.text = pack.displayName
        nameLabel.fontSize = fontSize(.body)
        nameLabel.fontColor = canAfford ? SKColor(red: 0.2, green: 0.2, blue: 0.25, alpha: 1.0) : SKColor.gray
        nameLabel.horizontalAlignmentMode = .left
        nameLabel.verticalAlignmentMode = .center
        let hasSubtext = pack.savingsText != nil
        nameLabel.position = CGPoint(x: -optionWidth / 2 + 55, y: hasSubtext ? 7 : 0)
        nameLabel.name = "paywallPack_\(pack.rawValue)"
        container.addChild(nameLabel)

        // Savings text (if any)
        if let savings = pack.savingsText {
            let savingsLabel = SKLabelNode(fontNamed: uiFont)
            savingsLabel.text = savings
            savingsLabel.fontSize = fontSize(.caption)
            savingsLabel.fontColor = canAfford ? hintGreen : SKColor.gray.withAlphaComponent(0.6)
            savingsLabel.horizontalAlignmentMode = .left
            savingsLabel.verticalAlignmentMode = .center
            savingsLabel.position = CGPoint(x: -optionWidth / 2 + 55, y: -8)
            container.addChild(savingsLabel)
        }

        // Price button
        let priceButton = SKShapeNode(rectOf: CGSize(width: 60, height: 28), cornerRadius: 14)
        priceButton.fillColor = canAfford ? gold : SKColor(red: 0.8, green: 0.8, blue: 0.82, alpha: 1.0)
        priceButton.strokeColor = canAfford ? goldDark : .clear
        priceButton.lineWidth = 1
        priceButton.position = CGPoint(x: optionWidth / 2 - 42, y: 0)
        priceButton.name = "paywallPack_\(pack.rawValue)"
        container.addChild(priceButton)

        // Coin icon in price
        let miniCoin = SKShapeNode(circleOfRadius: 6)
        miniCoin.fillColor = canAfford ? goldLight : SKColor.white.withAlphaComponent(0.6)
        miniCoin.strokeColor = canAfford ? goldDark.withAlphaComponent(0.5) : .clear
        miniCoin.lineWidth = 1
        miniCoin.position = CGPoint(x: optionWidth / 2 - 58, y: 0)
        container.addChild(miniCoin)

        let priceLabel = SKLabelNode(fontNamed: uiFontBold)
        priceLabel.text = "\(pack.coinCost)"
        priceLabel.fontSize = fontSize(.footnote)
        priceLabel.fontColor = canAfford ? SKColor(red: 0.35, green: 0.25, blue: 0.10, alpha: 1.0) : SKColor.white
        priceLabel.verticalAlignmentMode = .center
        priceLabel.position = CGPoint(x: optionWidth / 2 - 35, y: 0)
        priceLabel.name = "paywallPack_\(pack.rawValue)"
        container.addChild(priceLabel)

        return container
    }

    private func hideHintPaywall() {
        guard let paywall = hintPaywallNode else { return }

        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        let remove = SKAction.run { [weak self] in
            paywall.removeFromParent()
            self?.hintPaywallNode = nil
        }
        paywall.run(SKAction.sequence([fadeOut, remove]))
    }

    private func handlePaywallPurchase(_ pack: HintPack) {
        guard CoinManager.shared.balance >= pack.coinCost else {
            showInsufficientCoinsForHintPack(pack)
            return
        }

        if HintManager.shared.purchaseHintPack(pack) {
            SoundManager.shared.buttonTapped()
            hideHintPaywall()
            updateHintDisplay()
            showHintPurchaseSuccessToast(pack.hintCount)
        }
    }

    private func showInsufficientCoinsForHintPack(_ pack: HintPack) {
        guard let view = self.view,
              let viewController = view.window?.rootViewController else { return }

        let isZenTheme = theme.id == "zen"
        let deficit = pack.coinCost - CoinManager.shared.balance
        let title = isZenTheme ? "コイン不足" : "Insufficient Coins"
        let message = isZenTheme
            ? "あと\(deficit)コイン必要です。\n\n商店でコインを購入できます。"
            : "You need \(deficit) more coins.\n\nVisit the shop to purchase coins."

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        alert.addAction(UIAlertAction(title: isZenTheme ? "商店へ" : "Go to Shop", style: .default) { [weak self] _ in
            self?.hideHintPaywall()
            self?.goToShop()
        })

        viewController.present(alert, animated: true)
    }

    private func showHintPurchaseSuccessToast(_ hints: Int) {
        let isZenTheme = theme.id == "zen"
        let uiFont = isZenTheme ? "Hiragino Mincho ProN" : "AvenirNext-Medium"

        let toast = SKNode()
        toast.position = CGPoint(x: size.width / 2, y: size.height / 2)
        toast.zPosition = 100
        toast.alpha = 0
        toast.setScale(0.8)

        let bg = SKShapeNode(rectOf: CGSize(width: 180, height: 50), cornerRadius: 10)
        bg.fillColor = SKColor(red: 0.45, green: 0.55, blue: 0.40, alpha: 1.0)
        bg.strokeColor = SKColor.white.withAlphaComponent(0.2)
        bg.lineWidth = 1
        toast.addChild(bg)

        let label = SKLabelNode(fontNamed: uiFont)
        label.text = isZenTheme ? "+\(hints) 助言!" : "+\(hints) Hints!"
        label.fontSize = fontSize(.headline)
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        toast.addChild(label)

        addChild(toast)

        let fadeIn = SKAction.fadeIn(withDuration: 0.2)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.2)
        scaleUp.timingMode = .easeOut
        let entrance = SKAction.group([fadeIn, scaleUp])
        let wait = SKAction.wait(forDuration: 1.5)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let moveUp = SKAction.moveBy(x: 0, y: 50, duration: 0.3)
        let exit = SKAction.group([fadeOut, moveUp])
        let remove = SKAction.removeFromParent()

        toast.run(SKAction.sequence([entrance, wait, exit, remove]))
    }

    private func goToShop() {
        let transition = SKTransition.fade(withDuration: 0.4)
        let shopScene = ShopScene(size: size)
        shopScene.scaleMode = .aspectFill
        view?.presentScene(shopScene, transition: transition)
    }

    // MARK: - Coin Paywall

    private func showCoinPaywall() {
        guard coinPaywallNode == nil else { return }

        let isZenTheme = theme.id == "zen"
        let uiFont = isZenTheme ? "Hiragino Mincho ProN" : "AvenirNext-Medium"
        let uiFontBold = isZenTheme ? "Hiragino Mincho ProN" : "AvenirNext-DemiBold"

        // Premium colors
        let gold = SKColor(red: 0.92, green: 0.75, blue: 0.30, alpha: 1.0)
        let goldDark = SKColor(red: 0.75, green: 0.58, blue: 0.18, alpha: 1.0)
        let goldLight = SKColor(red: 1.0, green: 0.88, blue: 0.55, alpha: 1.0)
        let purchaseGreen = SKColor(red: 0.35, green: 0.65, blue: 0.45, alpha: 1.0)

        let container = SKNode()
        container.zPosition = 600  // Above hint paywall
        container.alpha = 0
        coinPaywallNode = container

        // Semi-transparent background
        let overlay = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height))
        overlay.fillColor = SKColor.black.withAlphaComponent(0.7)
        overlay.strokeColor = .clear
        overlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.name = "closeCoinPaywall"
        container.addChild(overlay)

        // Main card
        let cardWidth: CGFloat = 300
        let cardHeight: CGFloat = 340
        let centerX = size.width / 2
        let centerY = size.height / 2

        // Card shadow
        let cardShadow = SKShapeNode(rectOf: CGSize(width: cardWidth, height: cardHeight), cornerRadius: 20)
        cardShadow.fillColor = SKColor.black.withAlphaComponent(0.3)
        cardShadow.strokeColor = .clear
        cardShadow.position = CGPoint(x: centerX + 4, y: centerY - 6)
        container.addChild(cardShadow)

        // Main card
        let card = SKShapeNode(rectOf: CGSize(width: cardWidth, height: cardHeight), cornerRadius: 20)
        card.fillColor = SKColor.white
        card.strokeColor = gold.withAlphaComponent(0.4)
        card.lineWidth = 2
        card.position = CGPoint(x: centerX, y: centerY)
        container.addChild(card)

        // Top gold accent
        let topAccent = SKShapeNode(rectOf: CGSize(width: cardWidth - 40, height: 4), cornerRadius: 2)
        topAccent.fillColor = gold
        topAccent.strokeColor = .clear
        topAccent.position = CGPoint(x: centerX, y: centerY + cardHeight / 2 - 20)
        container.addChild(topAccent)

        // Coin stack icon at top
        let coinStackContainer = SKNode()
        coinStackContainer.position = CGPoint(x: centerX, y: centerY + cardHeight / 2 - 60)
        container.addChild(coinStackContainer)

        // Animated glow
        let coinGlow = SKShapeNode(circleOfRadius: 35)
        coinGlow.fillColor = gold.withAlphaComponent(0.2)
        coinGlow.strokeColor = .clear
        coinStackContainer.addChild(coinGlow)

        let glowPulse = SKAction.sequence([
            SKAction.scale(to: 1.15, duration: 1.0),
            SKAction.scale(to: 1.0, duration: 1.0)
        ])
        coinGlow.run(SKAction.repeatForever(glowPulse))

        // Stacked coins visual
        for i in 0..<4 {
            let yOffset = CGFloat(i) * 6
            let coinSize: CGFloat = 18 - CGFloat(i)
            let coin = SKShapeNode(circleOfRadius: coinSize)
            coin.fillColor = gold
            coin.strokeColor = goldDark
            coin.lineWidth = 2
            coin.position = CGPoint(x: 0, y: yOffset - 5)
            coin.zPosition = CGFloat(i)
            coinStackContainer.addChild(coin)

            if i == 3 {
                let shine = SKShapeNode(circleOfRadius: coinSize * 0.4)
                shine.fillColor = goldLight.withAlphaComponent(0.6)
                shine.strokeColor = .clear
                shine.position = CGPoint(x: -coinSize * 0.3, y: yOffset - 5 + coinSize * 0.3)
                shine.zPosition = CGFloat(i) + 0.5
                coinStackContainer.addChild(shine)
            }
        }

        // Title
        let title = SKLabelNode(fontNamed: uiFontBold)
        title.text = isZenTheme ? "コインを購入" : "Get Coins"
        title.fontSize = fontSize(.title)
        title.fontColor = SKColor(red: 0.2, green: 0.2, blue: 0.25, alpha: 1.0)
        title.position = CGPoint(x: centerX, y: centerY + cardHeight / 2 - 110)
        container.addChild(title)

        // Coin pack options
        let packs = CoinPack.allCases
        let packStartY = centerY + 20
        let packSpacing: CGFloat = 58

        for (index, pack) in packs.enumerated() {
            let packY = packStartY - CGFloat(index) * packSpacing
            let packNode = createCoinPackPaywallOption(pack: pack, at: CGPoint(x: centerX, y: packY), uiFont: uiFont, uiFontBold: uiFontBold, gold: gold, goldDark: goldDark, goldLight: goldLight, purchaseGreen: purchaseGreen, isZenTheme: isZenTheme)
            packNode.name = "coinPaywallPack_\(pack.rawValue)"
            container.addChild(packNode)
        }

        // Close button - X in corner
        let closeButton = SKNode()
        closeButton.position = CGPoint(x: centerX + cardWidth / 2 - 25, y: centerY + cardHeight / 2 - 25)
        closeButton.name = "closeCoinPaywall"
        container.addChild(closeButton)

        let closeBg = SKShapeNode(circleOfRadius: 14)
        closeBg.fillColor = SKColor(red: 0.9, green: 0.9, blue: 0.92, alpha: 1.0)
        closeBg.strokeColor = SKColor(red: 0.8, green: 0.8, blue: 0.82, alpha: 1.0)
        closeBg.lineWidth = 1
        closeBg.name = "closeCoinPaywall"
        closeButton.addChild(closeBg)

        let closeX = SKLabelNode(fontNamed: uiFontBold)
        closeX.text = "✕"
        closeX.fontSize = fontSize(.callout)
        closeX.fontColor = SKColor(red: 0.5, green: 0.5, blue: 0.55, alpha: 1.0)
        closeX.verticalAlignmentMode = .center
        closeX.horizontalAlignmentMode = .center
        closeX.name = "closeCoinPaywall"
        closeButton.addChild(closeX)

        // Back text at bottom
        let backLabel = SKLabelNode(fontNamed: uiFont)
        backLabel.text = isZenTheme ? "戻る" : "Back"
        backLabel.fontSize = fontSize(.subheadline)
        backLabel.fontColor = SKColor(red: 0.5, green: 0.5, blue: 0.55, alpha: 1.0)
        backLabel.position = CGPoint(x: centerX, y: centerY - cardHeight / 2 + 25)
        backLabel.name = "closeCoinPaywall"
        container.addChild(backLabel)

        addChild(container)

        // Animate in
        container.setScale(0.9)
        let fadeIn = SKAction.fadeIn(withDuration: 0.2)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.2)
        scaleUp.timingMode = .easeOut
        container.run(SKAction.group([fadeIn, scaleUp]))
    }

    private func createCoinPackPaywallOption(pack: CoinPack, at position: CGPoint, uiFont: String, uiFontBold: String, gold: SKColor, goldDark: SKColor, goldLight: SKColor, purchaseGreen: SKColor, isZenTheme: Bool) -> SKNode {
        let container = SKNode()
        container.position = position

        let isBestValue = pack == .large
        let isPopular = pack == .medium
        let optionWidth: CGFloat = 260
        let optionHeight: CGFloat = 50

        // Shadow
        let shadow = SKShapeNode(rectOf: CGSize(width: optionWidth - 4, height: optionHeight - 4), cornerRadius: 12)
        shadow.fillColor = SKColor.black.withAlphaComponent(0.08)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 2, y: -2)
        shadow.zPosition = -1
        container.addChild(shadow)

        // Background
        let bg = SKShapeNode(rectOf: CGSize(width: optionWidth, height: optionHeight), cornerRadius: 12)
        bg.fillColor = isBestValue ? gold.withAlphaComponent(0.12) : SKColor(red: 0.96, green: 0.96, blue: 0.97, alpha: 1.0)
        bg.strokeColor = isBestValue ? gold.withAlphaComponent(0.5) : (isPopular ? purchaseGreen.withAlphaComponent(0.4) : SKColor(red: 0.88, green: 0.88, blue: 0.9, alpha: 1.0))
        bg.lineWidth = 1.5
        bg.name = "coinPaywallPack_\(pack.rawValue)"
        container.addChild(bg)

        // Badge
        if isBestValue {
            let badge = SKShapeNode(rectOf: CGSize(width: 50, height: 14), cornerRadius: 7)
            badge.fillColor = gold
            badge.strokeColor = .clear
            badge.position = CGPoint(x: 0, y: optionHeight / 2 + 2)
            badge.zPosition = 5
            container.addChild(badge)

            let badgeLabel = SKLabelNode(fontNamed: uiFontBold)
            badgeLabel.text = "BEST"
            badgeLabel.fontSize = fontSize(.caption2)
            badgeLabel.fontColor = .white
            badgeLabel.verticalAlignmentMode = .center
            badgeLabel.position = CGPoint(x: 0, y: optionHeight / 2 + 2)
            badgeLabel.zPosition = 6
            container.addChild(badgeLabel)
        } else if isPopular {
            let badge = SKShapeNode(rectOf: CGSize(width: 50, height: 14), cornerRadius: 7)
            badge.fillColor = purchaseGreen
            badge.strokeColor = .clear
            badge.position = CGPoint(x: 0, y: optionHeight / 2 + 2)
            badge.zPosition = 5
            container.addChild(badge)

            let badgeLabel = SKLabelNode(fontNamed: uiFontBold)
            badgeLabel.text = "HOT"
            badgeLabel.fontSize = fontSize(.caption2)
            badgeLabel.fontColor = .white
            badgeLabel.verticalAlignmentMode = .center
            badgeLabel.position = CGPoint(x: 0, y: optionHeight / 2 + 2)
            badgeLabel.zPosition = 6
            container.addChild(badgeLabel)
        }

        // Coin icon
        let coinIcon = SKShapeNode(circleOfRadius: 14)
        coinIcon.fillColor = gold
        coinIcon.strokeColor = goldDark
        coinIcon.lineWidth = 1.5
        coinIcon.position = CGPoint(x: -optionWidth / 2 + 30, y: 0)
        container.addChild(coinIcon)

        let coinShine = SKShapeNode(circleOfRadius: 5)
        coinShine.fillColor = goldLight.withAlphaComponent(0.6)
        coinShine.strokeColor = .clear
        coinShine.position = CGPoint(x: -optionWidth / 2 + 26, y: 4)
        container.addChild(coinShine)

        // Amount
        let amountLabel = SKLabelNode(fontNamed: uiFontBold)
        amountLabel.text = "\(pack.coinAmount) Coins"
        amountLabel.fontSize = fontSize(.body)
        amountLabel.fontColor = SKColor(red: 0.2, green: 0.2, blue: 0.25, alpha: 1.0)
        amountLabel.horizontalAlignmentMode = .left
        amountLabel.verticalAlignmentMode = .center
        amountLabel.position = CGPoint(x: -optionWidth / 2 + 55, y: 0)
        amountLabel.name = "coinPaywallPack_\(pack.rawValue)"
        container.addChild(amountLabel)

        // Price button
        let priceButton = SKShapeNode(rectOf: CGSize(width: 65, height: 28), cornerRadius: 14)
        priceButton.fillColor = purchaseGreen
        priceButton.strokeColor = purchaseGreen.withAlphaComponent(0.8)
        priceButton.lineWidth = 1
        priceButton.position = CGPoint(x: optionWidth / 2 - 45, y: 0)
        priceButton.name = "coinPaywallPack_\(pack.rawValue)"
        container.addChild(priceButton)

        let priceLabel = SKLabelNode(fontNamed: uiFontBold)
        priceLabel.text = StoreManager.shared.getLocalizedPrice(for: pack)
        priceLabel.fontSize = fontSize(.footnote)
        priceLabel.fontColor = .white
        priceLabel.verticalAlignmentMode = .center
        priceLabel.position = CGPoint(x: optionWidth / 2 - 45, y: 0)
        priceLabel.name = "coinPaywallPack_\(pack.rawValue)"
        container.addChild(priceLabel)

        return container
    }

    private func hideCoinPaywall() {
        guard let paywall = coinPaywallNode else { return }

        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        let scaleDown = SKAction.scale(to: 0.9, duration: 0.2)
        let remove = SKAction.run { [weak self] in
            paywall.removeFromParent()
            self?.coinPaywallNode = nil
        }
        paywall.run(SKAction.sequence([SKAction.group([fadeOut, scaleDown]), remove]))
    }

    private func handleCoinPaywallPurchase(_ pack: CoinPack) {
        SoundManager.shared.buttonTapped()

        // Show loading state
        let loadingNode = createCoinPaywallLoading()
        coinPaywallNode?.addChild(loadingNode)

        Task { @MainActor in
            do {
                let success = try await StoreManager.shared.purchase(pack)
                loadingNode.removeFromParent()

                if success {
                    // Update the hint paywall balance display
                    hideCoinPaywall()
                    refreshHintPaywallBalance()
                    showCoinPurchaseSuccessToast(pack.coinAmount)
                }
            } catch {
                loadingNode.removeFromParent()
                showCoinPurchaseError(error.localizedDescription)
            }
        }
    }

    private func createCoinPaywallLoading() -> SKNode {
        let container = SKNode()
        container.zPosition = 100

        let overlay = SKShapeNode(rectOf: CGSize(width: 300, height: 340), cornerRadius: 20)
        overlay.fillColor = SKColor.white.withAlphaComponent(0.9)
        overlay.strokeColor = .clear
        overlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        container.addChild(overlay)

        let gold = SKColor(red: 0.92, green: 0.75, blue: 0.30, alpha: 1.0)
        let goldDark = SKColor(red: 0.75, green: 0.58, blue: 0.18, alpha: 1.0)

        // Spinner
        let spinnerContainer = SKNode()
        spinnerContainer.position = CGPoint(x: size.width / 2, y: size.height / 2 + 10)
        container.addChild(spinnerContainer)

        for i in 0..<3 {
            let coin = SKShapeNode(circleOfRadius: 8)
            coin.fillColor = gold
            coin.strokeColor = goldDark
            coin.lineWidth = 1
            let angle = CGFloat(i) * (.pi * 2 / 3)
            coin.position = CGPoint(x: cos(angle) * 20, y: sin(angle) * 20)
            spinnerContainer.addChild(coin)
        }

        spinnerContainer.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2, duration: 1.0)))

        let uiFont = theme.id == "zen" ? "Hiragino Mincho ProN" : "AvenirNext-Medium"
        let label = SKLabelNode(fontNamed: uiFont)
        label.text = theme.id == "zen" ? "処理中..." : "Processing..."
        label.fontSize = fontSize(.callout)
        label.fontColor = SKColor(red: 0.3, green: 0.3, blue: 0.35, alpha: 1.0)
        label.position = CGPoint(x: size.width / 2, y: size.height / 2 - 40)
        container.addChild(label)

        return container
    }

    private func refreshHintPaywallBalance() {
        guard let paywall = hintPaywallNode else { return }

        // Find and update the balance label
        paywall.enumerateChildNodes(withName: "//balanceLabel") { node, _ in
            if let label = node as? SKLabelNode {
                label.text = "\(CoinManager.shared.balance)"
            }
        }

        // Rebuild hint pack options to update affordability
        // This is a simple approach - remove old packs and recreate
        paywall.children.filter { $0.name?.hasPrefix("paywallPack_") == true }.forEach { $0.removeFromParent() }

        let isZenTheme = theme.id == "zen"
        let uiFont = isZenTheme ? "Hiragino Mincho ProN" : "AvenirNext-Medium"
        let uiFontBold = isZenTheme ? "Hiragino Mincho ProN" : "AvenirNext-DemiBold"
        let gold = SKColor(red: 0.92, green: 0.75, blue: 0.30, alpha: 1.0)
        let goldDark = SKColor(red: 0.75, green: 0.58, blue: 0.18, alpha: 1.0)
        let goldLight = SKColor(red: 1.0, green: 0.88, blue: 0.55, alpha: 1.0)
        let hintGreen = SKColor(red: 0.35, green: 0.65, blue: 0.45, alpha: 1.0)

        let centerX = size.width / 2
        let centerY = size.height / 2
        let packStartY = centerY + 35
        let packSpacing: CGFloat = 62

        for (index, pack) in HintPack.allCases.enumerated() {
            let packY = packStartY - CGFloat(index) * packSpacing
            let packNode = createHintPackOption(pack: pack, at: CGPoint(x: centerX, y: packY), uiFont: uiFont, uiFontBold: uiFontBold, isZenTheme: isZenTheme, gold: gold, goldDark: goldDark, goldLight: goldLight, hintGreen: hintGreen)
            packNode.name = "paywallPack_\(pack.rawValue)"
            paywall.addChild(packNode)
        }
    }

    private func showCoinPurchaseSuccessToast(_ coins: Int) {
        let isZenTheme = theme.id == "zen"
        let uiFontBold = isZenTheme ? "Hiragino Mincho ProN" : "AvenirNext-DemiBold"
        let gold = SKColor(red: 0.92, green: 0.75, blue: 0.30, alpha: 1.0)

        let toast = SKNode()
        toast.position = CGPoint(x: size.width / 2, y: size.height / 2 + 50)
        toast.zPosition = 700
        toast.alpha = 0
        toast.setScale(0.8)

        let bg = SKShapeNode(rectOf: CGSize(width: 180, height: 50), cornerRadius: 25)
        bg.fillColor = gold
        bg.strokeColor = SKColor.white.withAlphaComponent(0.3)
        bg.lineWidth = 2
        toast.addChild(bg)

        let label = SKLabelNode(fontNamed: uiFontBold)
        label.text = "+\(coins) 🪙"
        label.fontSize = fontSize(.title2)
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        toast.addChild(label)

        addChild(toast)

        let fadeIn = SKAction.fadeIn(withDuration: 0.2)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.2)
        scaleUp.timingMode = .easeOut
        let entrance = SKAction.group([fadeIn, scaleUp])
        let wait = SKAction.wait(forDuration: 1.5)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let moveUp = SKAction.moveBy(x: 0, y: 50, duration: 0.3)
        let exit = SKAction.group([fadeOut, moveUp])
        let remove = SKAction.removeFromParent()

        toast.run(SKAction.sequence([entrance, wait, exit, remove]))
    }

    private func showCoinPurchaseError(_ message: String) {
        guard let view = self.view,
              let viewController = view.window?.rootViewController else { return }

        let isZenTheme = theme.id == "zen"
        let title = isZenTheme ? "エラー" : "Purchase Failed"

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        viewController.present(alert, animated: true)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        // Only show ghost stone during active gameplay
        guard case .playing = board.gameState else {
            ghostStone?.removeFromParent()
            ghostStone = nil
            return
        }

        // Don't show ghost if AI is thinking or it's not player's turn
        if gameMode == .vsAI && (isAIThinking || board.currentPlayer != humanPlayer) {
            ghostStone?.removeFromParent()
            ghostStone = nil
            return
        }

        let boardLocation = CGPoint(
            x: location.x - boardOffset.x,
            y: location.y - boardOffset.y
        )

        let col = Int((boardLocation.x / cellSize).rounded())
        let row = Int((boardLocation.y / cellSize).rounded())

        if row >= 0 && row < board.size && col >= 0 && col < board.size && board.getPlayer(at: row, col: col) == .none {
            showGhostStone(at: row, col: col)
        } else {
            ghostStone?.removeFromParent()
            ghostStone = nil
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        ghostStone?.removeFromParent()
        ghostStone = nil
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        ghostStone?.removeFromParent()
        ghostStone = nil
    }

    private func showGhostStone(at row: Int, col: Int) {
        let stoneRadius = cellSize * 0.43
        let position = CGPoint(
            x: boardOffset.x + CGFloat(col) * cellSize,
            y: boardOffset.y + CGFloat(row) * cellSize
        )

        if ghostStone == nil {
            ghostStone = SKShapeNode(circleOfRadius: stoneRadius)
            ghostStone?.zPosition = 4.8
        }

        if let ghost = ghostStone {
            // Style based on current player using theme colors
            let stoneColor = board.currentPlayer == .black ? theme.blackStoneColor : theme.whiteStoneColor
            let highlightColor = board.currentPlayer == .black ? theme.blackStoneHighlight : theme.whiteStoneHighlight

            ghost.fillColor = stoneColor.skColor.withAlphaComponent(0.4)
            ghost.strokeColor = highlightColor.skColor.withAlphaComponent(0.6)
            ghost.lineWidth = 2
            ghost.position = position

            if ghost.parent == nil {
                addChild(ghost)
                // Gentle pulse
                let pulse = SKAction.sequence([
                    SKAction.fadeAlpha(to: 0.5, duration: 0.4),
                    SKAction.fadeAlpha(to: 0.3, duration: 0.4)
                ])
                ghost.run(SKAction.repeatForever(pulse))
            } else {
                ghost.position = position
            }
        }
    }

    private func animateButtonPress() {
        SoundManager.shared.buttonTapped()
        let scaleDown = SKAction.scale(to: 0.95, duration: 0.1)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.1)
        let sequence = SKAction.sequence([scaleDown, scaleUp])
        resetButtonBackground.run(sequence)
    }

    private func animateUndoButtonPress() {
        SoundManager.shared.buttonTapped()
        let scaleDown = SKAction.scale(to: 0.95, duration: 0.1)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.1)
        let sequence = SKAction.sequence([scaleDown, scaleUp])
        undoButtonBackground.run(sequence)
    }

    private func animateShareButtonPress() {
        let scaleDown = SKAction.scale(to: 0.95, duration: 0.1)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.1)
        let sequence = SKAction.sequence([scaleDown, scaleUp])
        shareButtonBackground?.run(sequence)
    }

    private func undoLastMove() {
        // Clear any pending move preview
        clearMovePreview()
        clearHintStone()
        pendingMove = nil

        // In AI mode, undo both AI move and human move
        let undoCount = (gameMode == .vsAI) ? 2 : 1

        for i in 0..<undoCount {
            guard board.canUndo(), let lastMove = board.undoMove() else {
                break
            }

            // Remove the last stone from the visual board with dramatic animation
            if let lastStone = stonesNode.children.last {
                // Dramatic lift-off and disappear animation
                let liftUp = SKAction.moveBy(x: 0, y: 80, duration: 0.3)
                liftUp.timingMode = .easeIn
                let fadeOut = SKAction.fadeOut(withDuration: 0.25)
                let rotate = SKAction.rotate(byAngle: CGFloat.random(in: -1...1), duration: 0.3)
                let scaleDown = SKAction.scale(to: 0.3, duration: 0.3)
                scaleDown.timingMode = .easeIn

                let group = SKAction.group([liftUp, fadeOut, rotate, scaleDown])
                let remove = SKAction.removeFromParent()

                // Add a whoosh particle effect
                if let stonePosition = (lastStone as? SKShapeNode)?.position {
                    addUndoParticles(at: stonePosition)
                }

                // Slight delay between multiple undos for visual clarity
                let delay = SKAction.wait(forDuration: Double(i) * 0.15)
                lastStone.run(SKAction.sequence([delay, group, remove]))

                // Also remove its shadow if it exists
                if stonesNode.children.count >= 2 {
                    let shadow = stonesNode.children[stonesNode.children.count - 2]
                    shadow.run(SKAction.sequence([delay, group, remove]))
                }
            }
        }

        updateStatusLabel()
        updateUndoButtonState()

        // Auto-save after undo (skip practice mode)
        if !isPracticeMode {
            GameStateManager.shared.saveGame(
                board: board,
                gameMode: gameMode,
                aiDifficulty: aiDifficulty,
                humanPlayer: humanPlayer
            )
        }
    }

    private func addUndoParticles(at position: CGPoint) {
        for _ in 0..<12 {
            let particle = SKShapeNode(circleOfRadius: 2)
            particle.fillColor = SKColor(red: 0.5, green: 0.7, blue: 1.0, alpha: 1.0)
            particle.strokeColor = .clear
            particle.position = position
            particle.zPosition = 10

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 30...60)
            let endX = position.x + cos(angle) * distance
            let endY = position.y + sin(angle) * distance + 40 // Bias upward

            let move = SKAction.move(to: CGPoint(x: endX, y: endY), duration: 0.4)
            move.timingMode = .easeOut
            let fade = SKAction.fadeOut(withDuration: 0.4)
            let scale = SKAction.scale(to: 0.1, duration: 0.4)
            let group = SKAction.group([move, fade, scale])
            let remove = SKAction.removeFromParent()

            particle.run(SKAction.sequence([group, remove]))
            addChild(particle)
        }
    }

    private func resetGame() {
        // Increment generation to invalidate any pending AI moves
        gameGeneration += 1

        // Clear saved game when starting fresh
        GameStateManager.shared.clearSavedGame()

        board.reset()
        stonesNode.removeAllChildren()
        isAIThinking = false
        hideAIThinkingIndicator()

        // Clear move preview and hint
        clearMovePreview()
        clearHintStone()
        pendingMove = nil

        // Reset stonesNode position (it may have been moved by shake animation)
        stonesNode.removeAllActions()
        stonesNode.position = .zero

        // Reset boardBackground position and remove any actions
        boardBackground.removeAllActions()
        boardBackground.position = CGPoint(x: size.width / 2, y: boardOffset.y + (cellSize * CGFloat(board.size - 1)) / 2)

        // Remove all win glow effects
        enumerateChildNodes(withName: "winGlow") { node, _ in
            node.removeFromParent()
        }

        // Hide share button
        hideShareButton()

        updateStatusLabel()
        updateUndoButtonState()
        updateHintButtonState()

        // If AI goes first (human is white), trigger AI move
        if gameMode == .vsAI && board.currentPlayer != humanPlayer {
            isAIThinking = true
            showAIThinkingIndicator()
            let wait = SKAction.wait(forDuration: 1.0)
            let aiMove = SKAction.run { [weak self] in
                self?.makeAIMove()
            }
            run(SKAction.sequence([wait, aiMove]))
        }
    }

    // MARK: - Game Restoration

    private func restoreFromSavedGame(_ savedGame: SavedGame) {
        // Replay all moves to restore board state
        for encodedMove in savedGame.moves {
            let player: Player = encodedMove.playerIndex == 0 ? .black : .white
            board.currentPlayer = player
            _ = board.placeStone(at: encodedMove.row, col: encodedMove.col)
        }
    }

    private func redrawAllStones() {
        // Draw all stones from move history without animation
        let highContrast = AccessibilityManager.shared.isHighContrastEnabled

        for move in board.getMoveHistory() {
            let player = move.player
            let row = move.row
            let col = move.col

            let stoneRadius = cellSize * 0.43
            let stone = SKShapeNode(circleOfRadius: stoneRadius)

            let stoneColor = player == .black ? theme.blackStoneColor : theme.whiteStoneColor
            let highlightColor = player == .black ? theme.blackStoneHighlight : theme.whiteStoneHighlight

            stone.fillColor = stoneColor.skColor

            // High contrast mode: stronger borders
            if highContrast {
                stone.strokeColor = player == .black ? SKColor.white : SKColor.black
                stone.lineWidth = 3.0
            } else {
                stone.strokeColor = highlightColor.skColor.withAlphaComponent(0.8)
                stone.lineWidth = player == .black ? 2 : 2.5
            }

            stone.position = CGPoint(
                x: boardOffset.x + CGFloat(col) * cellSize,
                y: boardOffset.y + CGFloat(row) * cellSize
            )
            stone.zPosition = 5

            // Add shadow
            if let stoneShadow = makeShadow(for: stone, offset: CGPoint(x: 0, y: -4), alpha: 0.35) {
                stonesNode.addChild(stoneShadow)
                stoneShadow.zPosition = stone.zPosition - 0.5
            }

            // Apply stone style from theme
            switch theme.stoneStyle {
            case .classic, .glossy:
                let mainHighlight = SKShapeNode(circleOfRadius: stoneRadius * 0.45)
                let mainHighlightAlpha: CGFloat = theme.stoneStyle == .glossy ? 0.35 : 0.25
                if player == .black {
                    mainHighlight.fillColor = highlightColor.skColor.withAlphaComponent(mainHighlightAlpha)
                } else {
                    mainHighlight.fillColor = SKColor(white: 1.0, alpha: theme.stoneStyle == .glossy ? 0.5 : 0.4)
                }
                mainHighlight.strokeColor = .clear
                mainHighlight.position = CGPoint(x: -stoneRadius * 0.25, y: stoneRadius * 0.25)
                stone.addChild(mainHighlight)

                let secondaryHighlight = SKShapeNode(circleOfRadius: stoneRadius * 0.25)
                let secondaryAlpha: CGFloat = theme.stoneStyle == .glossy ? 0.3 : 0.2
                if player == .black {
                    secondaryHighlight.fillColor = highlightColor.skColor.withAlphaComponent(secondaryAlpha)
                } else {
                    secondaryHighlight.fillColor = SKColor(white: 1.0, alpha: theme.stoneStyle == .glossy ? 0.7 : 0.6)
                }
                secondaryHighlight.strokeColor = .clear
                secondaryHighlight.position = CGPoint(x: -stoneRadius * 0.3, y: stoneRadius * 0.3)
                stone.addChild(secondaryHighlight)

                let rimLight = SKShapeNode(circleOfRadius: stoneRadius * 0.95)
                rimLight.fillColor = .clear
                let rimAlpha: CGFloat = theme.stoneStyle == .glossy ? 0.25 : 0.15
                if player == .black {
                    rimLight.strokeColor = highlightColor.skColor.withAlphaComponent(rimAlpha)
                } else {
                    rimLight.strokeColor = SKColor(red: 0.70, green: 0.80, blue: 1.0, alpha: rimAlpha * 2)
                }
                rimLight.lineWidth = theme.stoneStyle == .glossy ? 3 : 2
                stone.addChild(rimLight)

            case .flat:
                stone.strokeColor = .clear
            }

            stonesNode.addChild(stone)

            // Add colorblind marker if enabled
            AccessibilityManager.shared.addColorblindMarker(to: stone, player: player, radius: stoneRadius)
        }

        updateStatusLabel()
        updateUndoButtonState()
    }

    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}

