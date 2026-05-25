//
//  PuzzleScene.swift
//  Gomoku
//
//  Daily challenge puzzle: present a fixed position, accept one tap, reward on solve.
//  Deliberately self-contained — doesn't reuse GameScene's full machinery because
//  puzzles are short, single-move interactions with no AI or persistence.
//

import SpriteKit

class PuzzleScene: SKScene {

    private var theme: BoardTheme { ThemeManager.shared.currentTheme }
    private var isZenTheme: Bool { theme.id == "zen" }
    private var uiFont: String { isZenTheme ? "Hiragino Mincho ProN" : "AvenirNext-Medium" }
    private var uiFontBold: String { isZenTheme ? "Hiragino Mincho ProN" : "AvenirNext-DemiBold" }

    private var puzzle: DailyPuzzle!
    private var alreadySolved: Bool = false

    private var board: GomokuBoard!
    private var stonesNode: SKNode!
    private var statusLabel: SKLabelNode!
    private var rewardLabel: SKLabelNode?

    private let boardSize = 15
    private var cellSize: CGFloat = 0
    private var boardOffset: CGPoint = .zero

    private var hasResolved: Bool = false

    override func didMove(to view: SKView) {
        puzzle = PuzzleManager.shared.todaysPuzzle
        alreadySolved = PuzzleManager.shared.hasSolvedToday

        setupBackground()
        setupHeader()
        setupBoard()
        setupBackButton()
    }

    // MARK: - Setup

    private func setupBackground() {
        let top = theme.backgroundGradient.topColor.skColor
        let bot = theme.backgroundGradient.bottomColor.skColor
        for i in 0..<6 {
            let p = CGFloat(i) / 5.0
            let r = top.interpolate(to: bot, progress: p)
            let h = size.height / 6
            let strip = SKShapeNode(rect: CGRect(x: 0, y: CGFloat(5 - i) * h, width: size.width, height: h + 1))
            strip.fillColor = r
            strip.strokeColor = .clear
            strip.zPosition = -100
            addChild(strip)
        }
    }

    private func setupHeader() {
        let title = SKLabelNode(fontNamed: uiFontBold)
        title.text = isZenTheme ? "日替わりパズル · Daily Puzzle" : "Daily Puzzle"
        title.fontSize = 26
        title.fontColor = theme.statusTextColor.skColor
        title.position = CGPoint(x: size.width / 2, y: size.height - 80)
        title.zPosition = 10
        addChild(title)

        statusLabel = SKLabelNode(fontNamed: uiFont)
        statusLabel.text = puzzle.title
        statusLabel.fontSize = 18
        statusLabel.fontColor = theme.statusTextColor.skColor.withAlphaComponent(0.85)
        statusLabel.position = CGPoint(x: size.width / 2, y: size.height - 115)
        statusLabel.zPosition = 10
        addChild(statusLabel)

        rewardLabel = SKLabelNode(fontNamed: uiFontBold)
        rewardLabel?.text = alreadySolved ? "✓ Already solved today" : "Solve to earn 🪙 \(puzzle.reward)"
        rewardLabel?.fontSize = 14
        rewardLabel?.fontColor = alreadySolved
            ? theme.statusTextColor.skColor.withAlphaComponent(0.5)
            : theme.statusTextColor.skColor.withAlphaComponent(0.8)
        rewardLabel?.position = CGPoint(x: size.width / 2, y: size.height - 140)
        rewardLabel?.zPosition = 10
        if let r = rewardLabel { addChild(r) }
    }

    private func setupBoard() {
        board = GomokuBoard(size: boardSize)
        board.currentPlayer = puzzle.playerToMove
        for stone in puzzle.stones {
            board.currentPlayer = stone.player
            _ = board.placeStone(at: stone.row, col: stone.col)
        }
        board.currentPlayer = puzzle.playerToMove

        // Layout
        let padding: CGFloat = 30
        let availableWidth = size.width - padding * 2
        cellSize = availableWidth / CGFloat(boardSize)
        let boardWidth = cellSize * CGFloat(boardSize - 1)
        boardOffset = CGPoint(
            x: (size.width - boardWidth) / 2,
            y: 180
        )

        // Board panel
        let panel = SKShapeNode(
            rectOf: CGSize(width: boardWidth + 30, height: boardWidth + 30),
            cornerRadius: 12
        )
        panel.fillColor = theme.innerBoardColor.skColor
        panel.strokeColor = theme.boardStrokeColor.skColor
        panel.lineWidth = 2
        panel.position = CGPoint(x: size.width / 2, y: boardOffset.y + boardWidth / 2)
        panel.zPosition = 0
        addChild(panel)

        // Grid lines
        for i in 0..<boardSize {
            let v = SKShapeNode(
                rectOf: CGSize(width: 1, height: boardWidth),
                cornerRadius: 0
            )
            v.fillColor = theme.gridLineColor.skColor
            v.strokeColor = .clear
            v.position = CGPoint(
                x: boardOffset.x + CGFloat(i) * cellSize,
                y: boardOffset.y + boardWidth / 2
            )
            v.zPosition = 1
            addChild(v)

            let h = SKShapeNode(
                rectOf: CGSize(width: boardWidth, height: 1),
                cornerRadius: 0
            )
            h.fillColor = theme.gridLineColor.skColor
            h.strokeColor = .clear
            h.position = CGPoint(
                x: boardOffset.x + boardWidth / 2,
                y: boardOffset.y + CGFloat(i) * cellSize
            )
            h.zPosition = 1
            addChild(h)
        }

        stonesNode = SKNode()
        stonesNode.zPosition = 5
        addChild(stonesNode)
        renderAllStones()
    }

    private func renderAllStones() {
        stonesNode.removeAllChildren()
        for row in 0..<boardSize {
            for col in 0..<boardSize {
                let p = board.getPlayer(at: row, col: col)
                guard p != .none else { continue }
                addStone(at: row, col: col, player: p)
            }
        }
    }

    private func addStone(at row: Int, col: Int, player: Player) {
        let radius = cellSize * 0.43
        let stone = SKShapeNode(circleOfRadius: radius)
        stone.fillColor = (player == .black)
            ? StoneSkinManager.shared.blackStoneColor(theme: theme).skColor
            : StoneSkinManager.shared.whiteStoneColor(theme: theme).skColor
        stone.strokeColor = (player == .black)
            ? StoneSkinManager.shared.blackHighlightColor(theme: theme).skColor.withAlphaComponent(0.7)
            : StoneSkinManager.shared.whiteHighlightColor(theme: theme).skColor.withAlphaComponent(0.7)
        stone.lineWidth = 2
        stone.position = CGPoint(
            x: boardOffset.x + CGFloat(col) * cellSize,
            y: boardOffset.y + CGFloat(row) * cellSize
        )
        stonesNode.addChild(stone)
    }

    private func setupBackButton() {
        let container = SKNode()
        container.position = CGPoint(x: size.width / 2, y: 80)
        container.name = "backButton"
        container.zPosition = 20
        addChild(container)

        let bg = SKShapeNode(rectOf: CGSize(width: 220, height: 50), cornerRadius: 12)
        bg.fillColor = theme.buttonBackgroundColor.skColor
        bg.strokeColor = theme.buttonStrokeColor.skColor
        bg.lineWidth = 1.5
        bg.name = "backButton"
        container.addChild(bg)

        let label = SKLabelNode(fontNamed: uiFontBold)
        label.text = isZenTheme ? "← メニュー · Menu" : "← Back to Menu"
        label.fontSize = 16
        label.fontColor = theme.buttonTextColor.skColor
        label.verticalAlignmentMode = .center
        label.name = "backButton"
        container.addChild(label)
    }

    // MARK: - Touch handling

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodesHere = self.nodes(at: location)

        if nodesHere.contains(where: { $0.name == "backButton" }) {
            SoundManager.shared.buttonTapped()
            goBackToMenu()
            return
        }

        if hasResolved { return }

        // Convert tap to board coordinates
        let relX = location.x - boardOffset.x
        let relY = location.y - boardOffset.y
        let col = Int((relX / cellSize).rounded())
        let row = Int((relY / cellSize).rounded())
        guard row >= 0, row < boardSize, col >= 0, col < boardSize else { return }
        guard board.getPlayer(at: row, col: col) == .none else { return }

        if puzzle.winningMoves.contains(where: { $0.row == row && $0.col == col }) {
            handleCorrect(row: row, col: col)
        } else {
            handleIncorrect()
        }
    }

    private func handleCorrect(row: Int, col: Int) {
        hasResolved = true
        board.currentPlayer = puzzle.playerToMove
        _ = board.placeStone(at: row, col: col)
        addStone(at: row, col: col, player: puzzle.playerToMove)
        SoundManager.shared.gameWon()
        SoundManager.shared.hapticHeavy()

        let reward = PuzzleManager.shared.markSolved()
        let alreadyCollected = (reward == 0)

        statusLabel.text = isZenTheme ? "正解！" : "Correct!"
        statusLabel.fontColor = SKColor(red: 0.30, green: 0.65, blue: 0.30, alpha: 1.0)
        rewardLabel?.text = alreadyCollected
            ? "Already collected today"
            : "+\(reward) 🪙 added to your balance"
        rewardLabel?.fontColor = theme.statusTextColor.skColor
    }

    private func handleIncorrect() {
        SoundManager.shared.hapticLight()
        let shakeLeft = SKAction.moveBy(x: -8, y: 0, duration: 0.05)
        let shakeRight = SKAction.moveBy(x: 16, y: 0, duration: 0.05)
        let shakeBack = SKAction.moveBy(x: -8, y: 0, duration: 0.05)
        stonesNode.run(SKAction.sequence([shakeLeft, shakeRight, shakeBack]))

        statusLabel.text = isZenTheme ? "もう一度 · Try again" : "Not quite — try another move"
        statusLabel.fontColor = SKColor(red: 0.75, green: 0.22, blue: 0.17, alpha: 1.0)
    }

    private func goBackToMenu() {
        let transition = SKTransition.fade(withDuration: 0.4)
        let scene = MenuScene(size: size)
        scene.scaleMode = .aspectFill
        view?.presentScene(scene, transition: transition)
    }
}

// Small helper — mirrors the lerp used in other scenes.
private extension SKColor {
    func interpolate(to other: SKColor, progress: CGFloat) -> SKColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        other.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return SKColor(
            red: r1 + (r2 - r1) * progress,
            green: g1 + (g2 - g1) * progress,
            blue: b1 + (b2 - b1) * progress,
            alpha: a1 + (a2 - a1) * progress
        )
    }
}
