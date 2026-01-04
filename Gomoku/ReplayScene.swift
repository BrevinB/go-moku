//
//  ReplayScene.swift
//  Gomoku
//
//  Full replay viewer with playback controls for completed games.
//

import SpriteKit

class ReplayScene: SKScene {

    // Game data
    private let game: CompletedGame
    private var currentMoveIndex: Int = 0

    // Board rendering
    private var cellSize: CGFloat = 0
    private var boardOffset: CGPoint = .zero
    private var stonesNode: SKNode!
    private var boardBackground: SKShapeNode!
    private var innerBoard: SKShapeNode!
    private var gridNode: SKNode!
    private let boardSize = 15

    // Playback state
    private var isPlaying: Bool = false
    private var playbackSpeed: TimeInterval = 1.0
    private var playbackTimer: Timer?

    // UI elements
    private var moveCountLabel: SKLabelNode!
    private var playPauseButton: SKNode!
    private var playPauseIcon: SKLabelNode!
    private var prevButton: SKNode!
    private var nextButton: SKNode!
    private var speedButton: SKNode!
    private var speedLabel: SKLabelNode!
    private var sliderNode: SKNode!
    private var sliderTrack: SKShapeNode!
    private var sliderHandle: SKShapeNode!
    private var sliderWidth: CGFloat = 280

    // Theme reference
    private var theme: BoardTheme { ThemeManager.shared.currentTheme }
    private var isZenTheme: Bool { theme.id == "zen" }
    private var uiFont: String { isZenTheme ? "Hiragino Mincho ProN" : "AvenirNext-Medium" }

    // Theme-derived colors
    private var primaryTextColor: SKColor { theme.boardColor.skColor }
    private var secondaryTextColor: SKColor { theme.gridLineColor.skColor }
    private var accentColor: SKColor { theme.decorativeCircleColors.first?.skColor ?? SKColor.gray }

    init(size: CGSize, game: CompletedGame) {
        self.game = game
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        setupBackground()
        setupBoard()
        setupHeader()
        setupControls()
        setupSlider()
        updateMoveDisplay()
    }

    override func willMove(from view: SKView) {
        stopPlayback()
    }

    // MARK: - Background Setup

    private func setupBackground() {
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
                color = interpolateColor(from: topColor, to: midColor, progress: localProgress)
            } else {
                let localProgress = (progress - 0.5) * 2
                color = interpolateColor(from: midColor, to: bottomColor, progress: localProgress)
            }

            let height = size.height / CGFloat(numSteps)
            let rect = SKShapeNode(rect: CGRect(x: 0, y: CGFloat(i) * height, width: size.width, height: height + 1))
            rect.fillColor = color
            rect.strokeColor = .clear
            rect.zPosition = -100
            addChild(rect)
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

    // MARK: - Board Setup

    private func setupBoard() {
        stonesNode = SKNode()
        addChild(stonesNode)

        // Calculate board dimensions
        let topUIHeight: CGFloat = 90
        let bottomUIHeight: CGFloat = 160  // More space for controls
        let margin: CGFloat = 24

        let availableWidth = size.width - (margin * 2)
        let availableHeight = size.height - topUIHeight - bottomUIHeight - (margin * 2)

        let maxBoardSize = min(availableWidth, availableHeight)
        cellSize = (maxBoardSize / CGFloat(boardSize - 1)).rounded()

        let actualGridSize = cellSize * CGFloat(boardSize - 1)

        boardOffset = CGPoint(
            x: ((size.width - actualGridSize) / 2).rounded(),
            y: (bottomUIHeight + margin + (availableHeight - actualGridSize) / 2).rounded()
        )

        // Board background
        let boardPadding: CGFloat = 20
        let cornerRadius: CGFloat = isZenTheme ? 6 : 12
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

        // Shadow
        if let path = boardBackground.path {
            let shadow = SKShapeNode(path: path)
            shadow.fillColor = .black
            shadow.strokeColor = .clear
            shadow.alpha = 0.15
            shadow.position = CGPoint(x: boardBackground.position.x, y: boardBackground.position.y - 6)
            shadow.zPosition = boardBackground.zPosition - 1
            addChild(shadow)
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

        // Grid lines
        gridNode = SKNode()
        let totalGridSize = cellSize * CGFloat(boardSize - 1)

        for i in 0..<boardSize {
            let position = CGFloat(i) * cellSize
            let isEdge = (i == 0 || i == boardSize - 1)
            let lineWidth: CGFloat = isEdge ? 1.5 : 1.0

            // Vertical line
            let vLine = SKShapeNode(rectOf: CGSize(width: lineWidth, height: totalGridSize + lineWidth))
            vLine.fillColor = theme.gridLineColor.skColor
            vLine.strokeColor = .clear
            vLine.position = CGPoint(x: boardOffset.x + position, y: boardOffset.y + totalGridSize / 2)
            vLine.zPosition = 1
            gridNode.addChild(vLine)

            // Horizontal line
            let hLine = SKShapeNode(rectOf: CGSize(width: totalGridSize + lineWidth, height: lineWidth))
            hLine.fillColor = theme.gridLineColor.skColor
            hLine.strokeColor = .clear
            hLine.position = CGPoint(x: boardOffset.x + totalGridSize / 2, y: boardOffset.y + position)
            hLine.zPosition = 1
            gridNode.addChild(hLine)
        }

        // Star points
        let starPoints = [3, 7, 11]
        for row in starPoints {
            for col in starPoints {
                let starPoint = SKShapeNode(circleOfRadius: cellSize * 0.1)
                starPoint.fillColor = theme.gridLineColor.skColor
                starPoint.strokeColor = .clear
                starPoint.position = CGPoint(
                    x: boardOffset.x + CGFloat(col) * cellSize,
                    y: boardOffset.y + CGFloat(row) * cellSize
                )
                starPoint.zPosition = 2
                gridNode.addChild(starPoint)
            }
        }

        addChild(gridNode)
    }

    // MARK: - Header

    private func setupHeader() {
        // Title with game info
        let titleLabel = SKLabelNode(fontNamed: uiFont)
        titleLabel.text = isZenTheme ? "リプレイ" : "Replay"
        titleLabel.fontSize = 24
        titleLabel.fontColor = primaryTextColor
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height - 50)
        titleLabel.zPosition = 10
        addChild(titleLabel)

        // Game info
        let infoLabel = SKLabelNode(fontNamed: uiFont)
        if let colorInfo = game.colorDescription {
            infoLabel.text = "\(game.modeDescription) · \(game.resultDescription) · \(colorInfo)"
        } else {
            infoLabel.text = "\(game.modeDescription) · \(game.resultDescription)"
        }
        infoLabel.fontSize = 13
        infoLabel.fontColor = secondaryTextColor
        infoLabel.position = CGPoint(x: size.width / 2, y: size.height - 75)
        infoLabel.zPosition = 10
        addChild(infoLabel)

        // Back button
        let backContainer = SKNode()
        backContainer.position = CGPoint(x: 50, y: size.height - 55)
        backContainer.name = "backButton"
        backContainer.zPosition = 10
        addChild(backContainer)

        let backBg = SKShapeNode(rectOf: CGSize(width: 70, height: 36), cornerRadius: 6)
        backBg.fillColor = accentColor.withAlphaComponent(0.15)
        backBg.strokeColor = accentColor.withAlphaComponent(0.3)
        backBg.lineWidth = 1
        backBg.name = "backButton"
        backContainer.addChild(backBg)

        let backLabel = SKLabelNode(fontNamed: uiFont)
        backLabel.text = "← Back"
        backLabel.fontSize = 14
        backLabel.fontColor = primaryTextColor
        backLabel.verticalAlignmentMode = .center
        backLabel.name = "backButton"
        backContainer.addChild(backLabel)
    }

    // MARK: - Playback Controls

    private func setupControls() {
        let controlsY: CGFloat = 100

        // Move count label
        moveCountLabel = SKLabelNode(fontNamed: uiFont)
        moveCountLabel.fontSize = 16
        moveCountLabel.fontColor = primaryTextColor
        moveCountLabel.position = CGPoint(x: size.width / 2, y: controlsY + 45)
        moveCountLabel.zPosition = 10
        addChild(moveCountLabel)

        // Previous button
        prevButton = createControlButton(icon: "⏮", position: CGPoint(x: size.width / 2 - 90, y: controlsY), name: "prevButton")
        addChild(prevButton)

        // Play/Pause button (larger)
        playPauseButton = SKNode()
        playPauseButton.position = CGPoint(x: size.width / 2, y: controlsY)
        playPauseButton.name = "playPauseButton"
        playPauseButton.zPosition = 10
        addChild(playPauseButton)

        let playPauseBg = SKShapeNode(circleOfRadius: 28)
        playPauseBg.fillColor = accentColor.withAlphaComponent(0.2)
        playPauseBg.strokeColor = accentColor.withAlphaComponent(0.5)
        playPauseBg.lineWidth = 2
        playPauseBg.name = "playPauseButton"
        playPauseButton.addChild(playPauseBg)

        playPauseIcon = SKLabelNode(fontNamed: "AvenirNext-Bold")
        playPauseIcon.text = "▶"
        playPauseIcon.fontSize = 24
        playPauseIcon.fontColor = accentColor
        playPauseIcon.verticalAlignmentMode = .center
        playPauseIcon.horizontalAlignmentMode = .center
        playPauseIcon.position = CGPoint(x: 2, y: 0)  // Slight offset for visual centering
        playPauseIcon.name = "playPauseButton"
        playPauseButton.addChild(playPauseIcon)

        // Next button
        nextButton = createControlButton(icon: "⏭", position: CGPoint(x: size.width / 2 + 90, y: controlsY), name: "nextButton")
        addChild(nextButton)

        // Speed button
        speedButton = SKNode()
        speedButton.position = CGPoint(x: size.width - 60, y: controlsY)
        speedButton.name = "speedButton"
        speedButton.zPosition = 10
        addChild(speedButton)

        let speedBg = SKShapeNode(rectOf: CGSize(width: 50, height: 32), cornerRadius: 6)
        speedBg.fillColor = secondaryTextColor.withAlphaComponent(0.15)
        speedBg.strokeColor = secondaryTextColor.withAlphaComponent(0.3)
        speedBg.lineWidth = 1
        speedBg.name = "speedButton"
        speedButton.addChild(speedBg)

        speedLabel = SKLabelNode(fontNamed: uiFont)
        speedLabel.text = "1x"
        speedLabel.fontSize = 14
        speedLabel.fontColor = primaryTextColor
        speedLabel.verticalAlignmentMode = .center
        speedLabel.name = "speedButton"
        speedButton.addChild(speedLabel)
    }

    private func createControlButton(icon: String, position: CGPoint, name: String) -> SKNode {
        let container = SKNode()
        container.position = position
        container.name = name
        container.zPosition = 10

        let bg = SKShapeNode(circleOfRadius: 22)
        bg.fillColor = secondaryTextColor.withAlphaComponent(0.15)
        bg.strokeColor = secondaryTextColor.withAlphaComponent(0.3)
        bg.lineWidth = 1.5
        bg.name = name
        container.addChild(bg)

        let iconLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        iconLabel.text = icon
        iconLabel.fontSize = 18
        iconLabel.fontColor = primaryTextColor
        iconLabel.verticalAlignmentMode = .center
        iconLabel.horizontalAlignmentMode = .center
        iconLabel.name = name
        container.addChild(iconLabel)

        return container
    }

    // MARK: - Slider

    private func setupSlider() {
        let sliderY: CGFloat = 45

        sliderNode = SKNode()
        sliderNode.position = CGPoint(x: size.width / 2, y: sliderY)
        sliderNode.zPosition = 10
        addChild(sliderNode)

        // Track
        sliderTrack = SKShapeNode(rectOf: CGSize(width: sliderWidth, height: 6), cornerRadius: 3)
        sliderTrack.fillColor = secondaryTextColor.withAlphaComponent(0.2)
        sliderTrack.strokeColor = .clear
        sliderTrack.name = "slider"
        sliderNode.addChild(sliderTrack)

        // Handle
        sliderHandle = SKShapeNode(circleOfRadius: 12)
        sliderHandle.fillColor = accentColor
        sliderHandle.strokeColor = SKColor.white.withAlphaComponent(0.5)
        sliderHandle.lineWidth = 2
        sliderHandle.position = CGPoint(x: -sliderWidth / 2, y: 0)
        sliderHandle.name = "sliderHandle"
        sliderHandle.zPosition = 1
        sliderNode.addChild(sliderHandle)

        updateSliderPosition()
    }

    private func updateSliderPosition() {
        guard game.moves.count > 0 else { return }
        let progress = CGFloat(currentMoveIndex) / CGFloat(game.moves.count)
        let xPosition = -sliderWidth / 2 + progress * sliderWidth
        sliderHandle.position.x = xPosition
    }

    // MARK: - Move Display

    private func updateMoveDisplay() {
        // Clear existing stones
        stonesNode.removeAllChildren()

        // Draw stones up to current move index
        for i in 0..<currentMoveIndex {
            let move = game.moves[i]
            let isLastMove = (i == currentMoveIndex - 1)
            drawStone(row: move.row, col: move.col, player: move.player, isLastMove: isLastMove)
        }

        // Update move count label
        moveCountLabel.text = isZenTheme ?
            "Move \(currentMoveIndex)/\(game.moves.count) · \(currentMoveIndex)/\(game.moves.count)手目" :
            "Move \(currentMoveIndex) of \(game.moves.count)"

        updateSliderPosition()
    }

    private func drawStone(row: Int, col: Int, player: Player, isLastMove: Bool) {
        let stoneRadius = cellSize * 0.43
        let stone = SKShapeNode(circleOfRadius: stoneRadius)

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
        if let path = stone.path {
            let shadow = SKShapeNode(path: path)
            shadow.fillColor = .black
            shadow.strokeColor = .clear
            shadow.alpha = 0.35
            shadow.position = CGPoint(x: stone.position.x, y: stone.position.y - 4)
            shadow.zPosition = stone.zPosition - 0.5
            stonesNode.addChild(shadow)
        }

        // Apply stone style
        switch theme.stoneStyle {
        case .glossy, .classic:
            let highlightSize = stoneRadius * (theme.stoneStyle == .glossy ? 0.35 : 0.25)
            let highlight = SKShapeNode(circleOfRadius: highlightSize)
            if player == .black {
                highlight.fillColor = SKColor.white.withAlphaComponent(theme.stoneStyle == .glossy ? 0.5 : 0.3)
            } else {
                highlight.fillColor = SKColor.white.withAlphaComponent(theme.stoneStyle == .glossy ? 0.7 : 0.4)
            }
            highlight.strokeColor = .clear
            highlight.position = CGPoint(x: -stoneRadius * 0.25, y: stoneRadius * 0.25)
            stone.addChild(highlight)

        case .flat:
            stone.strokeColor = .clear
        }

        stonesNode.addChild(stone)

        // Add colorblind marker if enabled
        AccessibilityManager.shared.addColorblindMarker(to: stone, player: player, radius: stoneRadius)

        // Last move indicator
        if isLastMove {
            let indicator = SKShapeNode(circleOfRadius: stoneRadius * 0.25)
            indicator.fillColor = player == .black ? SKColor.red : SKColor.red
            indicator.strokeColor = .clear
            indicator.position = stone.position
            indicator.zPosition = 6
            indicator.name = "lastMoveIndicator"
            stonesNode.addChild(indicator)
        }
    }

    // MARK: - Playback Control

    private func startPlayback() {
        guard !isPlaying else { return }
        isPlaying = true
        playPauseIcon.text = "⏸"

        playbackTimer = Timer.scheduledTimer(withTimeInterval: playbackSpeed, repeats: true) { [weak self] _ in
            self?.advanceMove()
        }
    }

    private func stopPlayback() {
        isPlaying = false
        playPauseIcon.text = "▶"
        playbackTimer?.invalidate()
        playbackTimer = nil
    }

    private func togglePlayback() {
        if isPlaying {
            stopPlayback()
        } else {
            if currentMoveIndex >= game.moves.count {
                currentMoveIndex = 0
                updateMoveDisplay()
            }
            startPlayback()
        }
    }

    private func advanceMove() {
        if currentMoveIndex < game.moves.count {
            currentMoveIndex += 1
            updateMoveDisplay()
            SoundManager.shared.stonePlaced()
        } else {
            stopPlayback()
        }
    }

    private func previousMove() {
        if currentMoveIndex > 0 {
            currentMoveIndex -= 1
            updateMoveDisplay()
            SoundManager.shared.buttonTapped()
        }
    }

    private func nextMove() {
        if currentMoveIndex < game.moves.count {
            currentMoveIndex += 1
            updateMoveDisplay()
            SoundManager.shared.stonePlaced()
        }
    }

    private func cycleSpeed() {
        switch playbackSpeed {
        case 1.0:
            playbackSpeed = 0.5
            speedLabel.text = "2x"
        case 0.5:
            playbackSpeed = 0.25
            speedLabel.text = "4x"
        default:
            playbackSpeed = 1.0
            speedLabel.text = "1x"
        }

        // Restart timer with new speed if playing
        if isPlaying {
            stopPlayback()
            startPlayback()
        }

        SoundManager.shared.buttonTapped()
    }

    private func updateSliderFromTouch(_ location: CGPoint) {
        let localX = location.x - sliderNode.position.x
        let clampedX = max(-sliderWidth / 2, min(sliderWidth / 2, localX))
        let progress = (clampedX + sliderWidth / 2) / sliderWidth
        let newIndex = Int(progress * CGFloat(game.moves.count))
        currentMoveIndex = max(0, min(game.moves.count, newIndex))
        updateMoveDisplay()
    }

    // MARK: - Touch Handling

    private var isDraggingSlider = false

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodes = self.nodes(at: location)

        for node in nodes {
            if node.name == "sliderHandle" || node.name == "slider" {
                isDraggingSlider = true
                stopPlayback()
                updateSliderFromTouch(location)
                return
            }

            if let name = node.name {
                if let parent = node.parent, ["backButton", "prevButton", "nextButton", "playPauseButton", "speedButton"].contains(name) {
                    parent.run(SKAction.scale(to: 0.92, duration: 0.1))
                }
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDraggingSlider, let touch = touches.first else { return }
        let location = touch.location(in: self)
        updateSliderFromTouch(location)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        if isDraggingSlider {
            isDraggingSlider = false
            SoundManager.shared.buttonTapped()
            return
        }

        let nodes = self.nodes(at: location)

        for node in nodes {
            if node.name == "backButton" {
                SoundManager.shared.buttonTapped()
                stopPlayback()
                let transition = SKTransition.fade(withDuration: 0.4)
                let historyScene = GameHistoryScene(size: size)
                historyScene.scaleMode = .aspectFill
                view?.presentScene(historyScene, transition: transition)
                return
            }

            if node.name == "prevButton" {
                stopPlayback()
                previousMove()
                return
            }

            if node.name == "nextButton" {
                nextMove()
                return
            }

            if node.name == "playPauseButton" {
                SoundManager.shared.buttonTapped()
                togglePlayback()
                return
            }

            if node.name == "speedButton" {
                cycleSpeed()
                return
            }
        }

        // Reset button scales
        for child in children where child.zPosition == 10 {
            child.run(SKAction.scale(to: 1.0, duration: 0.1))
        }
    }
}
