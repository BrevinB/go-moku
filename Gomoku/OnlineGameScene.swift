//
//  OnlineGameScene.swift
//  Gomoku
//
//  Created by Brevin Blalock on 10/13/25.
//

import SpriteKit
import GameKit

class OnlineGameScene: SKScene {

    private var board: GomokuBoard!
    private var cellSize: CGFloat = 0
    private var boardOffset: CGPoint = .zero
    private var statusLabel: SKLabelNode!
    private var statusBackground: SKShapeNode!
    private var opponentLabel: SKLabelNode!
    private var backButton: SKLabelNode!
    private var resignButton: SKLabelNode!
    private var resignButtonBackground: SKShapeNode!
    private var stonesNode: SKNode!
    private var boardBackground: SKShapeNode!
    private var ghostStone: SKShapeNode?
    private var waitingIndicator: SKNode?
    private var shareButton: SKLabelNode?
    private var shareButtonBackground: SKShapeNode?

    var match: GKTurnBasedMatch?

    private var isProcessingMove = false
    private var lastPlacedStoneNode: SKShapeNode?
    private var pendingMovePosition: (row: Int, col: Int)?
    private var sendingIndicator: SKNode?

    // Theme reference for convenience
    private var theme: BoardTheme { ThemeManager.shared.currentTheme }

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

    override func didMove(to view: SKView) {
        let gradientLayer = createGradientBackground()
        addChild(gradientLayer)

        stonesNode = SKNode()
        addChild(stonesNode)

        // Setup match and board
        if let match = match {
            TurnBasedMatchManager.shared.setCurrentMatch(match)
            board = TurnBasedMatchManager.shared.reconstructBoard()
        } else {
            board = GomokuBoard(size: 15)
        }

        setupBoard()
        setupUI()
        updateBoardFromMatchData()

        // Register for notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTurnUpdate(_:)),
            name: .onlineGameTurnUpdated,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMatchEnded(_:)),
            name: .onlineGameMatchEnded,
            object: nil
        )

        // Show waiting indicator if it's not our turn
        if !TurnBasedMatchManager.shared.isMyTurn {
            showWaitingIndicator()
        }
    }

    override func willMove(from view: SKView) {
        NotificationCenter.default.removeObserver(self)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
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

        // Decorative elements from theme
        let positions: [(x: CGFloat, y: CGFloat, radius: CGFloat)] = [
            (x: 0.15, y: 0.80, radius: 85),
            (x: 0.85, y: 0.30, radius: 95),
            (x: 0.20, y: 0.20, radius: 75)
        ]

        for (index, pos) in positions.enumerated() {
            let decorColor = theme.decorativeCircleColors.indices.contains(index)
                ? theme.decorativeCircleColors[index]
                : theme.decorativeCircleColors.first ?? ThemeColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.2)

            for i in 0..<2 {
                let radius = pos.radius + CGFloat(i * 50)
                let circle = SKShapeNode(circleOfRadius: radius)
                let adjustedAlpha = max(0, min(1, decorColor.alpha - CGFloat(i) * 0.05))
                circle.fillColor = SKColor(red: decorColor.red, green: decorColor.green, blue: decorColor.blue, alpha: adjustedAlpha)
                circle.strokeColor = .clear
                circle.position = CGPoint(x: size.width * pos.x, y: size.height * pos.y)
                circle.zPosition = -99

                let float = SKAction.sequence([
                    SKAction.moveBy(x: 0, y: 12, duration: 3.5 + Double(index) * 0.5),
                    SKAction.moveBy(x: 0, y: -12, duration: 3.5 + Double(index) * 0.5)
                ])
                circle.run(SKAction.repeatForever(float))

                node.addChild(circle)
            }
        }

        return node
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
        let topUIHeight: CGFloat = 130
        let bottomUIHeight: CGFloat = 90
        let margin: CGFloat = 24

        let availableWidth = size.width - (margin * 2)
        let availableHeight = size.height - topUIHeight - bottomUIHeight - (margin * 2)

        let maxBoardSize = min(availableWidth, availableHeight)
        cellSize = (maxBoardSize / CGFloat(board.size - 1)).rounded()

        let actualGridSize = cellSize * CGFloat(board.size - 1)

        boardOffset = CGPoint(
            x: ((size.width - actualGridSize) / 2).rounded(),
            y: (bottomUIHeight + margin + (availableHeight - actualGridSize) / 2).rounded()
        )

        // Board background using theme colors
        let boardPadding: CGFloat = 24
        boardBackground = SKShapeNode(
            rectOf: CGSize(width: actualGridSize + boardPadding * 2, height: actualGridSize + boardPadding * 2),
            cornerRadius: 28
        )
        boardBackground.fillColor = theme.boardColor.skColor
        boardBackground.strokeColor = theme.boardStrokeColor.skColor
        boardBackground.lineWidth = 3
        boardBackground.position = CGPoint(x: size.width / 2, y: boardOffset.y + actualGridSize / 2)
        boardBackground.zPosition = -1
        addChild(boardBackground)

        // Shadows
        let shadowOffsets = [(0.0, -12.0, 0.30), (0.0, -6.0, 0.18)]
        for (x, y, alpha) in shadowOffsets {
            if let boardShadow = makeShadow(for: boardBackground, offset: CGPoint(x: x, y: y), alpha: alpha) {
                addChild(boardShadow)
                boardShadow.zPosition = boardBackground.zPosition - 1
            }
        }

        // Inner board using theme colors
        let innerBoard = SKShapeNode(
            rectOf: CGSize(width: actualGridSize + 4, height: actualGridSize + 4),
            cornerRadius: 18
        )
        innerBoard.fillColor = theme.innerBoardColor.skColor
        innerBoard.strokeColor = theme.innerBoardStrokeColor.skColor
        innerBoard.lineWidth = 1
        innerBoard.position = CGPoint(x: size.width / 2, y: boardOffset.y + actualGridSize / 2)
        innerBoard.zPosition = 0
        addChild(innerBoard)

        // Grid lines using theme colors
        let gridNode = SKNode()
        let totalGridSize = cellSize * CGFloat(board.size - 1)

        for i in 0..<board.size {
            let position = CGFloat(i) * cellSize

            let verticalLine = SKShapeNode()
            let verticalPath = CGMutablePath()
            verticalPath.move(to: CGPoint(x: position, y: 0))
            verticalPath.addLine(to: CGPoint(x: position, y: totalGridSize))
            verticalLine.path = verticalPath
            verticalLine.strokeColor = theme.gridLineColor.skColor
            verticalLine.lineWidth = 1.2
            gridNode.addChild(verticalLine)

            let horizontalLine = SKShapeNode()
            let horizontalPath = CGMutablePath()
            horizontalPath.move(to: CGPoint(x: 0, y: position))
            horizontalPath.addLine(to: CGPoint(x: totalGridSize, y: position))
            horizontalLine.path = horizontalPath
            horizontalLine.strokeColor = theme.gridLineColor.skColor
            horizontalLine.lineWidth = 1.2
            gridNode.addChild(horizontalLine)
        }

        gridNode.position = boardOffset
        gridNode.zPosition = 1
        addChild(gridNode)

        // Star points using theme colors
        let starPoints = [(3, 3), (3, 11), (7, 7), (11, 3), (11, 11)]
        for (row, col) in starPoints {
            let star = SKShapeNode(circleOfRadius: 4)
            star.fillColor = theme.starPointColor.skColor
            star.strokeColor = .clear
            star.position = CGPoint(
                x: boardOffset.x + CGFloat(col) * cellSize,
                y: boardOffset.y + CGFloat(row) * cellSize
            )
            star.zPosition = 1
            addChild(star)
        }
    }

    private func setupUI() {
        // Status background using theme colors
        statusBackground = SKShapeNode(rectOf: CGSize(width: 250, height: 68), cornerRadius: 34)
        statusBackground.fillColor = theme.statusBackgroundColor.skColor
        statusBackground.strokeColor = theme.statusStrokeColor.skColor
        statusBackground.lineWidth = 2
        statusBackground.position = CGPoint(x: size.width / 2, y: size.height - 80)
        statusBackground.zPosition = 10
        addChild(statusBackground)

        let statusShadowOffsets = [(0.0, -8.0, 0.28), (0.0, -4.0, 0.16)]
        for (x, y, alpha) in statusShadowOffsets {
            if let statusShadow = makeShadow(for: statusBackground, offset: CGPoint(x: x, y: y), alpha: alpha) {
                addChild(statusShadow)
                statusShadow.zPosition = statusBackground.zPosition - 1
            }
        }

        statusLabel = SKLabelNode(fontNamed: "SF Pro Rounded")
        statusLabel.fontSize = 28
        statusLabel.position = CGPoint(x: size.width / 2, y: size.height - 80)
        statusLabel.fontColor = theme.statusTextColor.skColor
        statusLabel.verticalAlignmentMode = .center
        statusLabel.zPosition = 11
        updateStatusLabel()
        addChild(statusLabel)

        // Opponent name label using theme colors
        opponentLabel = SKLabelNode(fontNamed: "SF Pro Rounded")
        opponentLabel.text = "vs \(TurnBasedMatchManager.shared.opponentName)"
        opponentLabel.fontSize = 16
        opponentLabel.fontColor = theme.statusTextColor.skColor.withAlphaComponent(0.8)
        opponentLabel.position = CGPoint(x: size.width / 2, y: size.height - 120)
        opponentLabel.zPosition = 11
        addChild(opponentLabel)

        // Your color indicator
        let localColor = TurnBasedMatchManager.shared.localPlayerColor
        let colorText = localColor == .black ? "You are Black" : "You are White"
        let colorLabel = SKLabelNode(fontNamed: "SF Pro Rounded")
        colorLabel.text = colorText
        colorLabel.fontSize = 14
        colorLabel.fontColor = theme.statusTextColor.skColor.withAlphaComponent(0.6)
        colorLabel.position = CGPoint(x: size.width / 2, y: size.height - 140)
        colorLabel.zPosition = 11
        addChild(colorLabel)

        // Back button using theme colors
        backButton = SKLabelNode(fontNamed: "SF Pro Rounded")
        backButton.text = "← Menu"
        backButton.fontSize = 18
        backButton.fontColor = theme.buttonTextColor.skColor
        backButton.position = CGPoint(x: 24, y: size.height - 165)
        backButton.name = "backButton"
        backButton.horizontalAlignmentMode = .left
        backButton.verticalAlignmentMode = .center
        backButton.zPosition = 12
        addChild(backButton)

        // Resign button (keep red for clear action distinction)
        resignButtonBackground = SKShapeNode(rectOf: CGSize(width: 140, height: 54), cornerRadius: 27)
        resignButtonBackground.fillColor = SKColor(red: 0.75, green: 0.45, blue: 0.40, alpha: 1.0)
        resignButtonBackground.strokeColor = SKColor(white: 1.0, alpha: 0.35)
        resignButtonBackground.lineWidth = 2
        resignButtonBackground.position = CGPoint(x: size.width / 2, y: 45)
        resignButtonBackground.name = "resignButton"
        resignButtonBackground.zPosition = 10
        addChild(resignButtonBackground)

        let resignShadowOffsets = [(0.0, -6.0, 0.30), (0.0, -3.0, 0.18)]
        for (x, y, alpha) in resignShadowOffsets {
            if let shadow = makeShadow(for: resignButtonBackground, offset: CGPoint(x: x, y: y), alpha: alpha) {
                addChild(shadow)
                shadow.zPosition = resignButtonBackground.zPosition - 1
            }
        }

        resignButton = SKLabelNode(fontNamed: "SF Pro Rounded")
        resignButton.text = "Resign"
        resignButton.fontSize = 22
        resignButton.fontColor = SKColor(red: 0.98, green: 0.97, blue: 0.95, alpha: 1.0)
        resignButton.position = CGPoint(x: size.width / 2, y: 45)
        resignButton.name = "resignButton"
        resignButton.verticalAlignmentMode = .center
        resignButton.zPosition = 11
        addChild(resignButton)
    }

    private func updateStatusLabel() {
        switch board.gameState {
        case .playing:
            if TurnBasedMatchManager.shared.isMyTurn {
                statusLabel.text = "Your Turn"
                statusBackground.fillColor = SKColor(red: 0.85, green: 0.95, blue: 0.88, alpha: 0.95)
            } else {
                statusLabel.text = "Waiting..."
                statusBackground.fillColor = SKColor(red: 0.92, green: 0.88, blue: 0.82, alpha: 0.95)
            }
        case .won(let player):
            let localColor = TurnBasedMatchManager.shared.localPlayerColor
            if player == localColor {
                statusLabel.text = "You Win!"
                statusBackground.fillColor = SKColor(red: 0.85, green: 0.95, blue: 0.88, alpha: 0.95)
            } else {
                statusLabel.text = "You Lose"
                statusBackground.fillColor = SKColor(red: 0.95, green: 0.85, blue: 0.85, alpha: 0.95)
            }
        case .draw:
            statusLabel.text = "Draw!"
        }
    }

    private func updateBoardFromMatchData() {
        // Reconstruct the board from match data
        board = TurnBasedMatchManager.shared.reconstructBoard()

        // Clear existing stones
        stonesNode.removeAllChildren()

        // Redraw all stones from move history
        let moves = board.getMoveHistory()
        for move in moves {
            drawStone(at: move.row, col: move.col, player: move.player, animated: false)
        }

        updateStatusLabel()

        // Check game state
        if case .won(let winner) = board.gameState {
            let moveCount = moves.count
            let localColor = TurnBasedMatchManager.shared.localPlayerColor
            if winner == localColor {
                StatisticsManager.shared.recordOnlineWin(moveCount: moveCount)
            } else {
                StatisticsManager.shared.recordOnlineLoss(moveCount: moveCount)
            }
            celebrateWin()
        }
    }

    @discardableResult
    private func drawStone(at row: Int, col: Int, player: Player, animated: Bool) -> SKShapeNode {
        let stoneRadius = cellSize * 0.43
        let stone = SKShapeNode(circleOfRadius: stoneRadius)
        stone.name = "stone_\(row)_\(col)"

        // Stone colors from theme
        let stoneColor = player == .black ? theme.blackStoneColor : theme.whiteStoneColor
        let highlightColor = player == .black ? theme.blackStoneHighlight : theme.whiteStoneHighlight

        stone.fillColor = stoneColor.skColor
        stone.strokeColor = highlightColor.skColor.withAlphaComponent(0.8)
        stone.lineWidth = player == .black ? 2 : 2.5

        stone.position = CGPoint(
            x: boardOffset.x + CGFloat(col) * cellSize,
            y: boardOffset.y + CGFloat(row) * cellSize
        )
        stone.zPosition = 5

        // Shadow
        if let stoneShadow = makeShadow(for: stone, offset: CGPoint(x: 0, y: -4), alpha: 0.35) {
            stonesNode.addChild(stoneShadow)
            stoneShadow.zPosition = stone.zPosition - 0.5
        }

        // Apply stone style from theme
        switch theme.stoneStyle {
        case .classic, .glossy:
            // Highlights
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

        case .flat:
            // Flat style - no highlights
            stone.strokeColor = .clear
        }

        if animated {
            let originalY = stone.position.y
            stone.position.y += 60
            stone.alpha = 0
            stone.setScale(0.3)

            let moveAction = SKAction.moveTo(y: originalY, duration: 0.35)
            moveAction.timingMode = .easeOut

            let fadeAction = SKAction.fadeAlpha(to: 1.0, duration: 0.25)

            let scaleUp = SKAction.scale(to: 1.15, duration: 0.2)
            scaleUp.timingMode = .easeOut
            let squash = SKAction.scaleY(to: 0.85, duration: 0.08)
            let stretch = SKAction.group([
                SKAction.scaleY(to: 1.1, duration: 0.08),
                SKAction.scaleX(to: 0.95, duration: 0.08)
            ])
            let settle = SKAction.scale(to: 1.0, duration: 0.12)
            let scaleSequence = SKAction.sequence([scaleUp, squash, stretch, settle])

            let group = SKAction.group([moveAction, fadeAction, scaleSequence])
            stone.run(group)

            addPlacementParticles(at: CGPoint(x: boardOffset.x + CGFloat(col) * cellSize, y: boardOffset.y + CGFloat(row) * cellSize), color: player == .black ? .black : .white)
        }

        stonesNode.addChild(stone)
        return stone
    }

    private func removeStone(at row: Int, col: Int) {
        // Remove the stone and its shadow by name
        let stoneName = "stone_\(row)_\(col)"
        stonesNode.children.filter { $0.name == stoneName || $0.name == "\(stoneName)_shadow" }.forEach { node in
            let fadeOut = SKAction.fadeOut(withDuration: 0.2)
            let remove = SKAction.removeFromParent()
            node.run(SKAction.sequence([fadeOut, remove]))
        }

        // Also remove the shadow (last child before the stone was added)
        if let lastStone = lastPlacedStoneNode {
            // Find and remove the shadow which was added just before the stone
            stonesNode.children.filter { node in
                guard let shapeNode = node as? SKShapeNode else { return false }
                return shapeNode.zPosition == lastStone.zPosition - 0.5 &&
                       abs(shapeNode.position.x - lastStone.position.x) < 5 &&
                       abs(shapeNode.position.y - (lastStone.position.y - 4)) < 5
            }.forEach { $0.removeFromParent() }
        }
    }

    private func placeStone(at row: Int, col: Int) {
        guard case .playing = board.gameState,
              TurnBasedMatchManager.shared.isMyTurn,
              !isProcessingMove else { return }

        let player = board.currentPlayer

        if board.placeStone(at: row, col: col) {
            isProcessingMove = true
            pendingMovePosition = (row, col)
            SoundManager.shared.stonePlaced()

            lastPlacedStoneNode = drawStone(at: row, col: col, player: player, animated: true)
            updateStatusLabel()
            animateStatusUpdate()

            // Check for win
            if case .won(let winner) = board.gameState {
                SoundManager.shared.gameWon()
                let moveCount = board.getMoveHistory().count

                // Record stats
                let localColor = TurnBasedMatchManager.shared.localPlayerColor
                if winner == localColor {
                    StatisticsManager.shared.recordOnlineWin(moveCount: moveCount)
                    TurnBasedMatchManager.shared.endMatchWithWin { [weak self] error in
                        if let error = error {
                            print("Error ending match: \(error.localizedDescription)")
                        }
                        self?.isProcessingMove = false
                        self?.pendingMovePosition = nil
                        self?.lastPlacedStoneNode = nil
                    }
                } else {
                    StatisticsManager.shared.recordOnlineLoss(moveCount: moveCount)
                    TurnBasedMatchManager.shared.endMatchWithLoss { [weak self] error in
                        if let error = error {
                            print("Error ending match: \(error.localizedDescription)")
                        }
                        self?.isProcessingMove = false
                        self?.pendingMovePosition = nil
                        self?.lastPlacedStoneNode = nil
                    }
                }

                celebrateWin()
            } else if case .draw = board.gameState {
                TurnBasedMatchManager.shared.endMatchWithDraw { [weak self] error in
                    if let error = error {
                        print("Error ending match: \(error.localizedDescription)")
                    }
                    self?.isProcessingMove = false
                    self?.pendingMovePosition = nil
                    self?.lastPlacedStoneNode = nil
                }
            } else {
                // Show sending indicator while move is being sent
                showSendingIndicator()

                // Send move to opponent
                TurnBasedMatchManager.shared.makeMove(row: row, col: col) { [weak self] success, error in
                    guard let self = self else { return }

                    DispatchQueue.main.async {
                        self.hideSendingIndicator()
                        self.isProcessingMove = false

                        if !success {
                            // Rollback: undo the move and remove the stone
                            print("Failed to send move: \(error?.localizedDescription ?? "Unknown error")")
                            self.rollbackFailedMove()
                            self.showMoveFailedAlert()
                        } else {
                            self.pendingMovePosition = nil
                            self.lastPlacedStoneNode = nil
                            self.updateStatusLabel()
                            self.showWaitingIndicator()
                        }
                    }
                }
            }
        }
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

    private func showWaitingIndicator() {
        hideWaitingIndicator()

        let indicatorNode = SKNode()
        indicatorNode.name = "waitingIndicator"
        indicatorNode.position = CGPoint(x: size.width / 2, y: size.height - 170)
        indicatorNode.zPosition = 12

        let dotRadius: CGFloat = 4
        let spacing: CGFloat = 12
        let colors: [SKColor] = [
            SKColor(red: 0.45, green: 0.65, blue: 0.75, alpha: 1.0),
            SKColor(red: 0.52, green: 0.70, blue: 0.80, alpha: 1.0),
            SKColor(red: 0.58, green: 0.75, blue: 0.85, alpha: 1.0)
        ]

        for i in 0..<3 {
            let dot = SKShapeNode(circleOfRadius: dotRadius)
            dot.fillColor = colors[i]
            dot.strokeColor = .clear
            dot.position = CGPoint(x: CGFloat(i - 1) * spacing, y: 0)

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

        let label = SKLabelNode(fontNamed: "SF Pro Rounded")
        label.text = "Waiting for opponent..."
        label.fontSize = 14
        label.fontColor = SKColor(red: 0.45, green: 0.38, blue: 0.30, alpha: 1.0)
        label.position = CGPoint(x: 0, y: -20)
        label.verticalAlignmentMode = .center

        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.5)
        let fadeOut = SKAction.fadeAlpha(to: 0.5, duration: 0.5)
        let fade = SKAction.sequence([fadeIn, fadeOut])
        label.run(SKAction.repeatForever(fade))

        indicatorNode.addChild(label)
        addChild(indicatorNode)
        waitingIndicator = indicatorNode
    }

    private func hideWaitingIndicator() {
        waitingIndicator?.removeFromParent()
        waitingIndicator = nil
    }

    private func showSendingIndicator() {
        hideSendingIndicator()

        statusLabel.text = "Sending..."
        statusBackground.fillColor = SKColor(red: 0.88, green: 0.92, blue: 0.95, alpha: 0.95)

        // Add pulsing animation to status
        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.6, duration: 0.4),
            SKAction.fadeAlpha(to: 1.0, duration: 0.4)
        ])
        statusLabel.run(SKAction.repeatForever(pulse), withKey: "sendingPulse")
    }

    private func hideSendingIndicator() {
        statusLabel.removeAction(forKey: "sendingPulse")
        statusLabel.alpha = 1.0
        sendingIndicator?.removeFromParent()
        sendingIndicator = nil
    }

    private func celebrateWin() {
        hideWaitingIndicator()
        hideResignButton()

        // Screen shake
        let shakeAmount: CGFloat = 8
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

        highlightWinningLine()

        // Confetti
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

        showShareButton()
    }

    private func highlightWinningLine() {
        guard !board.winningPositions.isEmpty else { return }

        for (row, col) in board.winningPositions {
            let position = CGPoint(
                x: boardOffset.x + CGFloat(col) * cellSize,
                y: boardOffset.y + CGFloat(row) * cellSize
            )

            let stoneRadius = cellSize * 0.43
            let glow = SKShapeNode(circleOfRadius: stoneRadius * 1.3)
            glow.fillColor = .clear
            glow.strokeColor = SKColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 0.8)
            glow.lineWidth = 4
            glow.position = position
            glow.zPosition = 6
            glow.name = "winGlow"

            let pulseUp = SKAction.scale(to: 1.2, duration: 0.6)
            pulseUp.timingMode = .easeInEaseOut
            let pulseDown = SKAction.scale(to: 1.0, duration: 0.6)
            pulseDown.timingMode = .easeInEaseOut
            let pulse = SKAction.sequence([pulseUp, pulseDown])
            let repeatPulse = SKAction.repeatForever(pulse)

            let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.3)
            let fadeOut = SKAction.fadeAlpha(to: 0.3, duration: 0.6)
            let fade = SKAction.sequence([fadeIn, fadeOut])
            let repeatFade = SKAction.repeatForever(fade)

            glow.run(SKAction.group([repeatPulse, repeatFade]))
            stonesNode.addChild(glow)
        }
    }

    private func showShareButton() {
        shareButton?.removeFromParent()
        shareButtonBackground?.removeFromParent()

        shareButtonBackground = SKShapeNode(rectOf: CGSize(width: 140, height: 54), cornerRadius: 27)
        shareButtonBackground?.fillColor = SKColor(red: 0.3, green: 0.6, blue: 0.9, alpha: 1.0)
        shareButtonBackground?.strokeColor = SKColor(white: 1.0, alpha: 0.35)
        shareButtonBackground?.lineWidth = 2
        shareButtonBackground?.position = CGPoint(x: size.width / 2, y: 45)
        shareButtonBackground?.name = "shareButton"
        shareButtonBackground?.zPosition = 10
        shareButtonBackground?.alpha = 0
        shareButtonBackground?.setScale(0.8)

        if let bg = shareButtonBackground {
            addChild(bg)

            let shadowOffsets = [(0.0, -6.0, 0.30), (0.0, -3.0, 0.18)]
            for (x, y, alpha) in shadowOffsets {
                if let shadow = makeShadow(for: bg, offset: CGPoint(x: x, y: y), alpha: alpha) {
                    addChild(shadow)
                    shadow.zPosition = bg.zPosition - 1
                }
            }
        }

        shareButton = SKLabelNode(fontNamed: "SF Pro Rounded")
        shareButton?.text = "Share"
        shareButton?.fontSize = 22
        shareButton?.fontColor = SKColor(red: 0.98, green: 0.97, blue: 0.95, alpha: 1.0)
        shareButton?.position = CGPoint(x: size.width / 2, y: 45)
        shareButton?.name = "shareButton"
        shareButton?.verticalAlignmentMode = .center
        shareButton?.zPosition = 11
        shareButton?.alpha = 0

        if let btn = shareButton {
            addChild(btn)
        }

        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.4)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.4)
        scaleUp.timingMode = .easeOut
        let entrance = SKAction.group([fadeIn, scaleUp])
        let delay = SKAction.wait(forDuration: 1.5)

        shareButtonBackground?.run(SKAction.sequence([delay, entrance]))
        shareButton?.run(SKAction.sequence([delay, entrance]))
    }

    private func hideResignButton() {
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let remove = SKAction.removeFromParent()
        resignButton.run(SKAction.sequence([fadeOut, remove]))
        resignButtonBackground.run(SKAction.sequence([fadeOut, remove]))
    }

    private func rollbackFailedMove() {
        guard let position = pendingMovePosition else { return }

        // Undo the board state
        _ = board.undoMove()

        // Remove the visual stone
        removeStone(at: position.row, col: position.col)

        // Clear pending state
        pendingMovePosition = nil
        lastPlacedStoneNode = nil

        // Update UI
        updateStatusLabel()
    }

    private func showMoveFailedAlert() {
        guard let view = self.view,
              let viewController = view.window?.rootViewController else { return }

        let alert = UIAlertController(
            title: "Move Failed",
            message: "Unable to send your move. Please check your connection and try again.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "OK", style: .default))

        viewController.present(alert, animated: true)
    }

    private func resignGame() {
        SoundManager.shared.buttonTapped()

        TurnBasedMatchManager.shared.resignMatch { [weak self] error in
            if let error = error {
                print("Error resigning: \(error.localizedDescription)")
            }
            DispatchQueue.main.async {
                self?.goBackToMenu()
            }
        }
    }

    private func shareScreenshot() {
        guard let view = self.view else { return }

        SoundManager.shared.buttonTapped()

        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, UIScreen.main.scale)
        view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        let screenshot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let image = screenshot else { return }

        let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: nil)

        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        if let viewController = view.window?.rootViewController {
            viewController.present(activityViewController, animated: true)
        }
    }

    private func goBackToMenu() {
        TurnBasedMatchManager.shared.clearCurrentMatch()
        let transition = SKTransition.fade(withDuration: 0.5)
        let menuScene = MenuScene(size: size)
        menuScene.scaleMode = .aspectFill
        view?.presentScene(menuScene, transition: transition)
    }

    // MARK: - Notification Handlers

    @objc private func handleTurnUpdate(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.hideWaitingIndicator()
            self?.updateBoardFromMatchData()
        }
    }

    @objc private func handleMatchEnded(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.hideWaitingIndicator()
            self?.updateBoardFromMatchData()
        }
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodes = self.nodes(at: location)

        if nodes.contains(where: { $0.name == "backButton" }) {
            SoundManager.shared.buttonTapped()
            goBackToMenu()
            return
        }

        if nodes.contains(where: { $0.name == "resignButton" }) {
            resignGame()
            return
        }

        if nodes.contains(where: { $0.name == "shareButton" }) {
            shareScreenshot()
            return
        }

        guard case .playing = board.gameState,
              TurnBasedMatchManager.shared.isMyTurn else { return }

        let boardLocation = CGPoint(
            x: location.x - boardOffset.x,
            y: location.y - boardOffset.y
        )

        let col = Int((boardLocation.x / cellSize).rounded())
        let row = Int((boardLocation.y / cellSize).rounded())

        if row >= 0 && row < board.size && col >= 0 && col < board.size {
            placeStone(at: row, col: col)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        guard case .playing = board.gameState,
              TurnBasedMatchManager.shared.isMyTurn else {
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
            let localColor = TurnBasedMatchManager.shared.localPlayerColor
            if localColor == .black {
                ghost.fillColor = SKColor(red: 0.08, green: 0.10, blue: 0.14, alpha: 0.4)
                ghost.strokeColor = SKColor(red: 0.25, green: 0.30, blue: 0.38, alpha: 0.6)
            } else {
                ghost.fillColor = SKColor(red: 0.98, green: 0.98, blue: 1.0, alpha: 0.4)
                ghost.strokeColor = SKColor(red: 0.85, green: 0.88, blue: 0.95, alpha: 0.6)
            }
            ghost.lineWidth = 2
            ghost.position = position

            if ghost.parent == nil {
                addChild(ghost)
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
}
