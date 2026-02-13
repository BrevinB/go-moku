//
//  MenuScene.swift
//  Gomoku
//
//  Created by Brevin Blalock on 10/13/25.
//

import SpriteKit
import GameKit

class MenuScene: SKScene {

    private var titleLabel: SKLabelNode!
    private var coinDisplay: SKNode!
    private var coinLabel: SKLabelNode!
    private var particleLayer: SKNode!

    // Track if we've shown the continue prompt this session
    private static var hasShownContinuePrompt = false

    // Practice mode toggle state
    private var isPracticeModeEnabled = false

    // Theme reference
    private var theme: BoardTheme { ThemeManager.shared.currentTheme }
    private var isZenTheme: Bool { theme.id == "zen" }
    private var uiFont: String { isZenTheme ? "Hiragino Mincho ProN" : "AvenirNext-Medium" }
    private var uiFontBold: String { isZenTheme ? "Hiragino Mincho ProN" : "AvenirNext-DemiBold" }

    // Accent colors
    private let accentRed = SKColor(red: 0.75, green: 0.22, blue: 0.17, alpha: 1.0)
    private let bamboo = SKColor(red: 0.45, green: 0.52, blue: 0.35, alpha: 1.0)
    private let gold = SKColor(red: 0.85, green: 0.68, blue: 0.25, alpha: 1.0)

    override func didMove(to view: SKView) {
        // Initialize font scaling for this scene
        initializeFontScaling()

        setupParticleLayer()
        setupBackground()
        if isZenTheme {
            setupZenDecorations()
        } else {
            setupSimpleDecorations()
        }
        setupHeader()
        setupTitle()
        setupMenuButtons()
        setupBottomElements()
        startAmbientCoinSparkle()

        // Listen for Game Center notifications
        NotificationCenter.default.addObserver(self, selector: #selector(onMatchesRefreshed), name: .gameCenterMatchesRefreshed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onShouldOpenMatch(_:)), name: .gameCenterShouldOpenMatch, object: nil)

        // Show continue prompt on first launch if there's a saved game
        if !MenuScene.hasShownContinuePrompt && GameStateManager.shared.hasSavedGame {
            MenuScene.hasShownContinuePrompt = true
            // Small delay so the menu renders first
            let wait = SKAction.wait(forDuration: 0.3)
            let showPrompt = SKAction.run { [weak self] in
                self?.showContinuePrompt()
            }
            run(SKAction.sequence([wait, showPrompt]))
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func onMatchesRefreshed() {
        // Refresh menu to show/hide Continue Online Match button
        refreshMenuButtons()
    }

    @objc private func onShouldOpenMatch(_ notification: Notification) {
        guard let match = notification.object as? GKTurnBasedMatch else { return }
        openOnlineMatch(match)
    }

    private func refreshMenuButtons() {
        // Remove existing menu buttons
        for name in ["continueGame", "continueOnlineMatch", "playAI", "playFriend", "playOnline", "statistics", "settings", "howToPlay"] {
            enumerateChildNodes(withName: name) { node, _ in
                node.removeFromParent()
            }
        }
        // Recreate menu buttons
        setupMenuButtons()
    }

    private func openOnlineMatch(_ match: GKTurnBasedMatch) {
        // Navigate to the online game scene with this match
        let transition = SKTransition.fade(withDuration: 0.4)
        let scene = OnlineGameScene(size: size)
        scene.scaleMode = .aspectFill
        scene.match = match
        view?.presentScene(scene, transition: transition)
    }

    private func setupParticleLayer() {
        particleLayer = SKNode()
        particleLayer.zPosition = 500
        addChild(particleLayer)
    }

    private func startAmbientCoinSparkle() {
        let sparkleAction = SKAction.run { [weak self] in
            guard let self = self, let coinPos = self.coinDisplay?.position else { return }
            self.createSparkle(at: CGPoint(
                x: coinPos.x + 47 + CGFloat.random(in: -30...30),
                y: coinPos.y + CGFloat.random(in: -15...15)
            ))
        }
        let wait = SKAction.wait(forDuration: 3.0)
        run(SKAction.repeatForever(SKAction.sequence([wait, sparkleAction])))
    }

    private func createSparkle(at position: CGPoint) {
        let sparkle = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.5...2.5))
        sparkle.fillColor = gold
        sparkle.strokeColor = SKColor.white.withAlphaComponent(0.5)
        sparkle.lineWidth = 0.5
        sparkle.position = position
        sparkle.zPosition = 200
        sparkle.alpha = 0
        particleLayer.addChild(sparkle)

        let offsetX = CGFloat.random(in: -15...15)
        let offsetY = CGFloat.random(in: 8...20)

        let fadeIn = SKAction.fadeIn(withDuration: 0.12)
        let move = SKAction.moveBy(x: offsetX, y: offsetY, duration: 0.5)
        let fadeOut = SKAction.fadeOut(withDuration: 0.25)
        let scale = SKAction.scale(to: 0.3, duration: 0.5)
        let remove = SKAction.removeFromParent()

        move.timingMode = .easeOut
        sparkle.run(SKAction.sequence([
            fadeIn,
            SKAction.group([move, scale, SKAction.sequence([SKAction.wait(forDuration: 0.25), fadeOut])]),
            remove
        ]))
    }

    // MARK: - Background

    private func setupBackground() {
        let gradient = theme.backgroundGradient
        let topColor = gradient.topColor.skColor
        let bottomColor = gradient.bottomColor.skColor

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

        // Subtle texture dots
        let textureColor = theme.statusTextColor.skColor
        for _ in 0..<60 {
            let dot = SKShapeNode(circleOfRadius: CGFloat.random(in: 0.5...1.5))
            dot.fillColor = textureColor.withAlphaComponent(CGFloat.random(in: 0.02...0.04))
            dot.strokeColor = .clear
            dot.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height)
            )
            dot.zPosition = -99
            addChild(dot)
        }
    }

    private func setupZenDecorations() {
        // Enso circle (Zen brush stroke)
        drawEnsoCircle(at: CGPoint(x: size.width - 80, y: size.height - 160), radius: 60)

        // Ink wash mountains
        drawMountains()

        // Bamboo stalks
        drawBambooAccent()

        // Subtle grid pattern
        drawSubtleGrid()
    }

    private func setupSimpleDecorations() {
        // Large soft decorative circles
        let circleConfigs: [(x: CGFloat, y: CGFloat, radius: CGFloat, alpha: CGFloat)] = [
            (0.15, 0.82, 120, 0.08),
            (0.85, 0.25, 140, 0.06),
            (0.20, 0.15, 100, 0.05),
            (0.90, 0.70, 80, 0.04)
        ]

        for (index, config) in circleConfigs.enumerated() {
            let baseColor = index < theme.decorativeCircleColors.count
                ? theme.decorativeCircleColors[index].skColor
                : theme.boardColor.skColor

            let circle = SKShapeNode(circleOfRadius: config.radius)
            circle.fillColor = baseColor.withAlphaComponent(config.alpha)
            circle.strokeColor = .clear
            circle.position = CGPoint(x: size.width * config.x, y: size.height * config.y)
            circle.zPosition = -90
            addChild(circle)
        }
    }

    private func drawEnsoCircle(at position: CGPoint, radius: CGFloat) {
        let inkColor = theme.statusTextColor.skColor

        let path = CGMutablePath()
        let startAngle: CGFloat = .pi * 0.1
        let endAngle: CGFloat = .pi * 1.85
        path.addArc(center: .zero, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)

        let enso = SKShapeNode(path: path)
        enso.strokeColor = inkColor.withAlphaComponent(0.08)
        enso.lineWidth = 8
        enso.lineCap = .round
        enso.fillColor = .clear
        enso.position = position
        enso.zPosition = -90
        addChild(enso)

        let innerPath = CGMutablePath()
        innerPath.addArc(center: .zero, radius: radius - 15, startAngle: startAngle + 0.2, endAngle: endAngle - 0.3, clockwise: false)

        let innerEnso = SKShapeNode(path: innerPath)
        innerEnso.strokeColor = inkColor.withAlphaComponent(0.04)
        innerEnso.lineWidth = 3
        innerEnso.lineCap = .round
        innerEnso.fillColor = .clear
        innerEnso.position = position
        innerEnso.zPosition = -90
        addChild(innerEnso)
    }

    private func drawMountains() {
        let inkColor = theme.statusTextColor.skColor

        let mountainPath = CGMutablePath()
        mountainPath.move(to: CGPoint(x: 0, y: 60))
        mountainPath.addQuadCurve(to: CGPoint(x: size.width * 0.25, y: 100), control: CGPoint(x: size.width * 0.12, y: 85))
        mountainPath.addQuadCurve(to: CGPoint(x: size.width * 0.4, y: 130), control: CGPoint(x: size.width * 0.32, y: 145))
        mountainPath.addQuadCurve(to: CGPoint(x: size.width * 0.6, y: 90), control: CGPoint(x: size.width * 0.5, y: 110))
        mountainPath.addQuadCurve(to: CGPoint(x: size.width * 0.8, y: 120), control: CGPoint(x: size.width * 0.7, y: 140))
        mountainPath.addQuadCurve(to: CGPoint(x: size.width, y: 70), control: CGPoint(x: size.width * 0.9, y: 100))
        mountainPath.addLine(to: CGPoint(x: size.width, y: 0))
        mountainPath.addLine(to: CGPoint(x: 0, y: 0))
        mountainPath.closeSubpath()

        let mountain = SKShapeNode(path: mountainPath)
        mountain.fillColor = inkColor.withAlphaComponent(0.04)
        mountain.strokeColor = .clear
        mountain.zPosition = -85
        addChild(mountain)

        let mountain2Path = CGMutablePath()
        mountain2Path.move(to: CGPoint(x: 0, y: 40))
        mountain2Path.addQuadCurve(to: CGPoint(x: size.width * 0.3, y: 70), control: CGPoint(x: size.width * 0.15, y: 80))
        mountain2Path.addQuadCurve(to: CGPoint(x: size.width * 0.5, y: 50), control: CGPoint(x: size.width * 0.4, y: 55))
        mountain2Path.addQuadCurve(to: CGPoint(x: size.width * 0.75, y: 80), control: CGPoint(x: size.width * 0.65, y: 90))
        mountain2Path.addQuadCurve(to: CGPoint(x: size.width, y: 45), control: CGPoint(x: size.width * 0.88, y: 60))
        mountain2Path.addLine(to: CGPoint(x: size.width, y: 0))
        mountain2Path.addLine(to: CGPoint(x: 0, y: 0))
        mountain2Path.closeSubpath()

        let mountain2 = SKShapeNode(path: mountain2Path)
        mountain2.fillColor = inkColor.withAlphaComponent(0.06)
        mountain2.strokeColor = .clear
        mountain2.zPosition = -84
        addChild(mountain2)
    }

    private func drawBambooAccent() {
        let stalkX: CGFloat = 35

        for i in 0..<3 {
            let xOffset = CGFloat(i) * 12
            let height = size.height * CGFloat.random(in: 0.5...0.7)

            let stalk = SKShapeNode(rectOf: CGSize(width: 3, height: height))
            stalk.fillColor = bamboo.withAlphaComponent(0.15)
            stalk.strokeColor = .clear
            stalk.position = CGPoint(x: stalkX + xOffset, y: height / 2)
            stalk.zPosition = -88
            addChild(stalk)

            for j in 1..<Int(height / 80) {
                let node = SKShapeNode(rectOf: CGSize(width: 6, height: 2))
                node.fillColor = bamboo.withAlphaComponent(0.2)
                node.strokeColor = .clear
                node.position = CGPoint(x: stalkX + xOffset, y: CGFloat(j) * 80)
                node.zPosition = -87
                addChild(node)
            }
        }

        for _ in 0..<5 {
            let leaf = SKShapeNode(ellipseOf: CGSize(width: 20, height: 6))
            leaf.fillColor = bamboo.withAlphaComponent(0.1)
            leaf.strokeColor = .clear
            leaf.position = CGPoint(
                x: CGFloat.random(in: 25...60),
                y: CGFloat.random(in: size.height * 0.4...size.height * 0.7)
            )
            leaf.zRotation = CGFloat.random(in: -0.5...0.5)
            leaf.zPosition = -86
            addChild(leaf)
        }
    }

    private func drawSubtleGrid() {
        let gridSize: CGFloat = 40
        let gridAlpha: CGFloat = 0.03
        let gridColor = theme.statusTextColor.skColor

        for i in stride(from: gridSize, to: size.width, by: gridSize) {
            let line = SKShapeNode(rectOf: CGSize(width: 1, height: size.height))
            line.fillColor = gridColor.withAlphaComponent(gridAlpha)
            line.strokeColor = .clear
            line.position = CGPoint(x: i, y: size.height / 2)
            line.zPosition = -95
            addChild(line)
        }

        for i in stride(from: gridSize, to: size.height, by: gridSize) {
            let line = SKShapeNode(rectOf: CGSize(width: size.width, height: 1))
            line.fillColor = gridColor.withAlphaComponent(gridAlpha)
            line.strokeColor = .clear
            line.position = CGPoint(x: size.width / 2, y: i)
            line.zPosition = -95
            addChild(line)
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

    // MARK: - Header

    private func setupHeader() {
        setupCoinDisplay()
        setupTrophyButton()
    }

    private func setupCoinDisplay() {
        let goldDark = SKColor(red: 0.70, green: 0.52, blue: 0.15, alpha: 1.0)
        let goldLight = SKColor(red: 1.0, green: 0.88, blue: 0.55, alpha: 1.0)

        coinDisplay = SKNode()
        coinDisplay.position = CGPoint(x: 28, y: size.height - 65)
        coinDisplay.zPosition = 15
        coinDisplay.name = "shopButton"
        addChild(coinDisplay)

        // Shadow for depth
        let shadow = SKShapeNode(rectOf: CGSize(width: 95, height: 38), cornerRadius: 19)
        shadow.fillColor = SKColor.black.withAlphaComponent(0.1)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 49, y: -2)
        shadow.name = "shopButton"
        coinDisplay.addChild(shadow)

        let background = SKShapeNode(rectOf: CGSize(width: 95, height: 38), cornerRadius: 19)
        background.fillColor = SKColor.white.withAlphaComponent(0.95)
        background.strokeColor = gold.withAlphaComponent(0.5)
        background.lineWidth = 1.5
        background.position = CGPoint(x: 47, y: 0)
        background.name = "shopButton"
        coinDisplay.addChild(background)

        // Coin icon with shine
        let coinIconContainer = SKNode()
        coinIconContainer.position = CGPoint(x: 18, y: 0)
        coinIconContainer.name = "shopButton"
        coinDisplay.addChild(coinIconContainer)

        let coinIcon = SKShapeNode(circleOfRadius: 12)
        coinIcon.fillColor = gold
        coinIcon.strokeColor = goldDark
        coinIcon.lineWidth = 1.5
        coinIcon.name = "shopButton"
        coinIconContainer.addChild(coinIcon)

        // Inner ring
        let innerRing = SKShapeNode(circleOfRadius: 8)
        innerRing.fillColor = .clear
        innerRing.strokeColor = goldDark.withAlphaComponent(0.3)
        innerRing.lineWidth = 1
        innerRing.name = "shopButton"
        coinIconContainer.addChild(innerRing)

        // Shine highlight
        let shine = SKShapeNode(circleOfRadius: 4)
        shine.fillColor = goldLight.withAlphaComponent(0.6)
        shine.strokeColor = .clear
        shine.position = CGPoint(x: -3, y: 3)
        shine.name = "shopButton"
        coinIconContainer.addChild(shine)

        // Enhanced animated shimmer with crop mask to stay within coin
        let cropNode = SKCropNode()
        cropNode.name = "shopButton"
        coinIconContainer.addChild(cropNode)

        // Circular mask matching the coin
        let maskNode = SKShapeNode(circleOfRadius: 12)
        maskNode.fillColor = .white
        maskNode.strokeColor = .clear
        cropNode.maskNode = maskNode

        // Shimmer container that will be masked
        let shimmerContainer = SKNode()
        shimmerContainer.name = "shopButton"
        cropNode.addChild(shimmerContainer)

        // Create multi-layer shimmer for gradient effect
        let shimmerWidths: [(width: CGFloat, alpha: CGFloat)] = [
            (6, 0.2),    // Outer glow
            (4, 0.35),   // Middle layer
            (2, 0.7),    // Core - bright
            (4, 0.35),   // Middle layer
            (6, 0.2)     // Outer glow
        ]

        var xOffset: CGFloat = -10
        for (width, alpha) in shimmerWidths {
            let shimmerLine = SKShapeNode(rectOf: CGSize(width: width, height: 30), cornerRadius: width / 2)
            shimmerLine.fillColor = SKColor.white.withAlphaComponent(alpha)
            shimmerLine.strokeColor = .clear
            shimmerLine.position = CGPoint(x: xOffset, y: 0)
            shimmerLine.name = "shopButton"
            shimmerContainer.addChild(shimmerLine)
            xOffset += width + 0.5
        }

        shimmerContainer.zRotation = .pi / 6
        shimmerContainer.position = CGPoint(x: -18, y: 0)

        // Shimmer animation
        let moveAcross = SKAction.moveTo(x: 18, duration: 0.5)
        moveAcross.timingMode = .easeInEaseOut
        let reset = SKAction.moveTo(x: -18, duration: 0)
        let wait = SKAction.wait(forDuration: 3.5)

        shimmerContainer.run(SKAction.repeatForever(SKAction.sequence([
            moveAcross,
            reset,
            wait
        ])))

        coinLabel = SKLabelNode(fontNamed: uiFontBold)
        coinLabel.text = "\(CoinManager.shared.balance)"
        coinLabel.fontSize = fontSize(.headline)
        coinLabel.fontColor = goldDark
        coinLabel.verticalAlignmentMode = .center
        coinLabel.horizontalAlignmentMode = .left
        coinLabel.position = CGPoint(x: 36, y: 0)
        coinLabel.name = "shopButton"
        coinDisplay.addChild(coinLabel)

        // Plus icon with background
        let plusBg = SKShapeNode(circleOfRadius: 10)
        plusBg.fillColor = bamboo.withAlphaComponent(0.2)
        plusBg.strokeColor = bamboo.withAlphaComponent(0.4)
        plusBg.lineWidth = 1
        plusBg.position = CGPoint(x: 82, y: 0)
        plusBg.name = "shopButton"
        coinDisplay.addChild(plusBg)

        let plus = SKLabelNode(fontNamed: uiFontBold)
        plus.text = "+"
        plus.fontSize = fontSize(.callout)
        plus.fontColor = bamboo
        plus.verticalAlignmentMode = .center
        plus.position = CGPoint(x: 82, y: 0)
        plus.name = "shopButton"
        coinDisplay.addChild(plus)

        NotificationCenter.default.addObserver(self, selector: #selector(onCoinsUpdated), name: .coinsUpdated, object: nil)
    }

    private func setupTrophyButton() {
        let container = SKNode()
        container.position = CGPoint(x: size.width - 48, y: size.height - 65)
        container.zPosition = 15
        container.name = "gameCenter"
        addChild(container)

        let bg = SKShapeNode(circleOfRadius: 22)
        bg.fillColor = theme.buttonBackgroundColor.skColor
        bg.strokeColor = theme.buttonStrokeColor.skColor
        bg.lineWidth = 1.5
        bg.name = "gameCenter"
        container.addChild(bg)

        let trophy = SKLabelNode(text: "🏆")
        trophy.fontSize = fontSize(.title2)
        trophy.position = CGPoint(x: 0, y: -7)
        trophy.name = "gameCenter"
        container.addChild(trophy)
    }

    @objc private func onCoinsUpdated() {
        coinLabel?.text = "\(CoinManager.shared.balance)"

        // Bounce animation
        let scaleUp = SKAction.scale(to: 1.15, duration: 0.12)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.12)
        scaleUp.timingMode = .easeOut
        scaleDown.timingMode = .easeOut
        coinDisplay?.run(SKAction.sequence([scaleUp, scaleDown]))

        // Burst of sparkles
        if let pos = coinDisplay?.position {
            for _ in 0..<5 {
                createSparkle(at: CGPoint(
                    x: pos.x + 47 + CGFloat.random(in: -25...25),
                    y: pos.y + CGFloat.random(in: -10...10)
                ))
            }
        }
    }

    // MARK: - Title

    private func setupTitle() {
        titleLabel = SKLabelNode(fontNamed: uiFontBold)
        if isZenTheme {
            titleLabel.text = "五目並べ"
            titleLabel.fontSize = scaledFontSize(44)
        } else {
            titleLabel.text = "go!moku"
            titleLabel.fontSize = scaledFontSize(52)
        }
        titleLabel.fontColor = theme.statusTextColor.skColor
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height - 160)
        titleLabel.zPosition = 10
        addChild(titleLabel)

        let subtitle = SKLabelNode(fontNamed: uiFont)
        if isZenTheme {
            subtitle.text = "Gomoku"
            subtitle.fontSize = fontSize(.title)
            subtitle.position = CGPoint(x: size.width / 2, y: size.height - 200)
            drawHankoSeal(at: CGPoint(x: size.width / 2 + 85, y: size.height - 180))
        } else {
            subtitle.text = "Five in a Row"
            subtitle.fontSize = fontSize(.title2)
            subtitle.position = CGPoint(x: size.width / 2, y: size.height - 205)
        }
        subtitle.fontColor = theme.statusTextColor.skColor.withAlphaComponent(0.6)
        subtitle.zPosition = 10
        addChild(subtitle)
    }

    private func drawHankoSeal(at position: CGPoint) {
        let seal = SKShapeNode(rectOf: CGSize(width: 32, height: 32), cornerRadius: 3)
        seal.fillColor = accentRed.withAlphaComponent(0.85)
        seal.strokeColor = accentRed
        seal.lineWidth = 1
        seal.position = position
        seal.zPosition = 10
        seal.zRotation = 0.08
        addChild(seal)

        let sealChar = SKLabelNode(fontNamed: "Hiragino Mincho ProN")
        sealChar.text = "碁"
        sealChar.fontSize = fontSize(.headline)
        sealChar.fontColor = .white
        sealChar.position = CGPoint(x: position.x, y: position.y - 6)
        sealChar.zPosition = 11
        sealChar.zRotation = 0.08
        addChild(sealChar)
    }

    // MARK: - Menu Buttons

    // Button colors
    private let buttonGreen = SKColor(red: 0.45, green: 0.58, blue: 0.40, alpha: 1.0)
    private let buttonOrange = SKColor(red: 0.78, green: 0.52, blue: 0.38, alpha: 1.0)
    private let buttonBlue = SKColor(red: 0.45, green: 0.58, blue: 0.72, alpha: 1.0)
    private let buttonLightBlue = SKColor(red: 0.65, green: 0.75, blue: 0.80, alpha: 1.0)
    private let buttonGray = SKColor(red: 0.60, green: 0.62, blue: 0.58, alpha: 1.0)

    private func setupMenuButtons() {
        let baseY = size.height / 2 + 100
        let spacing: CGFloat = 72

        // Check if there's a saved game
        let hasSavedGame = GameStateManager.shared.hasSavedGame
        let hasPendingOnlineMatch = GameCenterManager.shared.hasPendingMatches
        var currentY = baseY

        // Show Continue button if saved game exists
        if hasSavedGame {
            createMenuButton(
                title: "Continue Game",
                subtitle: isZenTheme ? "続きから" : "Resume your game",
                color: accentRed,
                position: CGPoint(x: size.width / 2, y: currentY),
                name: "continueGame"
            )
            currentY -= spacing
        }

        // Show Continue Online Match button if there's a pending match
        if hasPendingOnlineMatch {
            let pendingCount = GameCenterManager.shared.pendingTurnMatches.count
            let subtitle = isZenTheme
                ? "あなたの番 · Your turn"
                : (pendingCount == 1 ? "Your turn!" : "\(pendingCount) matches - Your turn!")
            createMenuButton(
                title: "Continue Online",
                subtitle: subtitle,
                color: buttonBlue,
                position: CGPoint(x: size.width / 2, y: currentY),
                name: "continueOnlineMatch"
            )
            currentY -= spacing
        }

        createMenuButton(
            title: "Play vs AI",
            subtitle: isZenTheme ? "対AI戦" : "Challenge the computer",
            color: buttonGreen,
            position: CGPoint(x: size.width / 2, y: currentY),
            name: "playAI"
        )

        createMenuButton(
            title: "Play vs Friend",
            subtitle: isZenTheme ? "二人対戦" : "Local 2-player mode",
            color: buttonOrange,
            position: CGPoint(x: size.width / 2, y: currentY - spacing),
            name: "playFriend"
        )

        createMenuButton(
            title: "Play Online",
            subtitle: isZenTheme ? "オンライン" : "Challenge players worldwide",
            color: buttonBlue,
            position: CGPoint(x: size.width / 2, y: currentY - spacing * 2),
            name: "playOnline"
        )

        createMenuButton(
            title: "Statistics",
            subtitle: isZenTheme ? "統計" : "View your game stats",
            color: buttonLightBlue,
            position: CGPoint(x: size.width / 2, y: currentY - spacing * 3),
            name: "statistics"
        )

        createMenuButton(
            title: "Settings",
            subtitle: isZenTheme ? "設定" : "Sound, Haptics & More",
            color: buttonGray,
            position: CGPoint(x: size.width / 2, y: currentY - spacing * 4),
            name: "settings"
        )

        createMenuButton(
            title: "How to Play",
            subtitle: isZenTheme ? "遊び方" : "Learn the rules",
            color: buttonLightBlue,
            position: CGPoint(x: size.width / 2, y: currentY - spacing * 5),
            name: "howToPlay"
        )
    }

    private func createMenuButton(title: String, subtitle: String, color: SKColor, position: CGPoint, name: String) {
        let container = SKNode()
        container.position = position
        container.name = name
        container.zPosition = 10
        addChild(container)

        let buttonWidth: CGFloat = 300
        let buttonHeight: CGFloat = 62

        let bg = SKShapeNode(rectOf: CGSize(width: buttonWidth, height: buttonHeight), cornerRadius: 14)
        bg.fillColor = color
        bg.strokeColor = .clear
        bg.name = name
        container.addChild(bg)

        let titleLabel = SKLabelNode(fontNamed: uiFontBold)
        titleLabel.text = title
        titleLabel.fontSize = fontSize(.title2)
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: 0, y: 6)
        titleLabel.name = name
        container.addChild(titleLabel)

        let subtitleLabel = SKLabelNode(fontNamed: uiFont)
        subtitleLabel.text = subtitle
        subtitleLabel.fontSize = fontSize(.subheadline)
        subtitleLabel.fontColor = SKColor.white.withAlphaComponent(0.8)
        subtitleLabel.position = CGPoint(x: 0, y: -14)
        subtitleLabel.name = name
        container.addChild(subtitleLabel)
    }

    // MARK: - Bottom Elements

    private func setupBottomElements() {
        // Bottom area is now empty since Settings is in the main buttons
        // Just keep the space clean
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodes = self.nodes(at: location)

        if children.contains(where: { $0.name == "difficultyOverlay" }) { return }

        for node in nodes {
            guard let name = node.name else { continue }
            if ["playAI", "playFriend", "playOnline", "continueOnlineMatch", "statistics", "settings", "howToPlay", "gameCenter", "shopButton"].contains(name) {
                if let parent = findButtonContainer(node) {
                    parent.run(SKAction.scale(to: 0.96, duration: 0.1))
                }
                return
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodes = self.nodes(at: location)

        let hasDifficultyOverlay = children.contains { $0.name == "difficultyOverlay" }
        let hasContinuePrompt = children.contains { $0.name == "continuePromptOverlay" }

        for node in nodes {
            guard let name = node.name else { continue }

            if let parent = findButtonContainer(node) {
                parent.run(SKAction.scale(to: 1.0, duration: 0.1))
            }

            if hasContinuePrompt {
                handleContinuePromptSelection(name: name)
            } else if hasDifficultyOverlay {
                handleDifficultySelection(name: name)
            } else {
                handleMenuSelection(name: name)
            }
            return
        }

        resetAllButtonScales()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        resetAllButtonScales()
    }

    private func findButtonContainer(_ node: SKNode) -> SKNode? {
        if node.parent?.zPosition == 10 || node.parent?.zPosition == 15 {
            return node.parent
        }
        return node
    }

    private func resetAllButtonScales() {
        for child in children where child.zPosition == 10 || child.zPosition == 15 {
            child.run(SKAction.scale(to: 1.0, duration: 0.1))
        }
    }

    private func handleMenuSelection(name: String) {
        SoundManager.shared.buttonTapped()

        switch name {
        case "continueGame": continueGame()
        case "continueOnlineMatch": continueOnlineMatch()
        case "playAI": showDifficultySelection()
        case "playFriend": startGame(mode: .twoPlayer, difficulty: .medium)
        case "playOnline": startOnlineGame()
        case "statistics": showStatistics()
        case "settings": showSettings()
        case "howToPlay": showHowToPlay()
        case "gameCenter": showGameCenter()
        case "shopButton": showShop()
        default: break
        }
    }

    private func continueOnlineMatch() {
        guard GameCenterManager.shared.isAuthenticated else {
            showNotAuthenticatedAlert()
            return
        }

        // Get pending matches
        let pendingMatches = GameCenterManager.shared.pendingTurnMatches

        if pendingMatches.count == 1, let match = pendingMatches.first {
            // Only one match, open it directly
            openOnlineMatch(match)
        } else if pendingMatches.count > 1 {
            // Multiple matches - show the matchmaker UI which lists existing matches
            guard let vc = view?.window?.rootViewController else { return }
            GameCenterManager.shared.findMatch(from: vc) { [weak self] match, _ in
                guard let self = self, let match = match else { return }
                DispatchQueue.main.async {
                    self.openOnlineMatch(match)
                }
            }
        }
    }

    private func handleDifficultySelection(name: String) {
        if name.starts(with: "difficulty_") {
            let diffStr = name.replacingOccurrences(of: "difficulty_", with: "")
            let difficulty: AIDifficulty = diffStr == "easy" ? .easy : (diffStr == "hard" ? .hard : .medium)
            SoundManager.shared.buttonTapped()
            startGame(mode: .vsAI, difficulty: difficulty, isPractice: isPracticeModeEnabled)
        } else if name == "practiceToggle" || name == "practiceToggleKnob" {
            togglePracticeMode()
        } else if name == "cancelDifficulty" || name == "difficultyOverlay" {
            SoundManager.shared.buttonTapped()
            hideDifficultySelection()
        }
    }

    // MARK: - Difficulty Selection

    private func showDifficultySelection() {
        // Reset practice mode when opening dialog
        isPracticeModeEnabled = false

        let overlayColor = theme.statusTextColor.skColor

        let overlay = SKShapeNode(rect: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        overlay.fillColor = overlayColor.withAlphaComponent(0.5)
        overlay.strokeColor = .clear
        overlay.zPosition = 100
        overlay.name = "difficultyOverlay"
        overlay.alpha = 0
        addChild(overlay)
        overlay.run(SKAction.fadeAlpha(to: 1.0, duration: 0.25))

        let modal = SKShapeNode(rectOf: CGSize(width: 300, height: 400), cornerRadius: 16)
        modal.fillColor = theme.statusBackgroundColor.skColor
        modal.strokeColor = theme.statusStrokeColor.skColor
        modal.lineWidth = 2
        modal.position = CGPoint(x: size.width / 2, y: size.height / 2)
        modal.zPosition = 101
        modal.name = "difficultyOverlay"
        modal.setScale(0.9)
        modal.alpha = 0
        addChild(modal)
        modal.run(SKAction.group([
            SKAction.fadeIn(withDuration: 0.25),
            SKAction.scale(to: 1.0, duration: 0.25)
        ]))

        let title = SKLabelNode(fontNamed: uiFontBold)
        title.text = isZenTheme ? "難易度選択" : "Select Difficulty"
        title.fontSize = fontSize(.title)
        title.fontColor = theme.statusTextColor.skColor
        title.position = CGPoint(x: size.width / 2, y: size.height / 2 + 160)
        title.zPosition = 102
        title.name = "difficultyOverlay"
        addChild(title)

        if isZenTheme {
            let subtitle = SKLabelNode(fontNamed: uiFont)
            subtitle.text = "Select Difficulty"
            subtitle.fontSize = fontSize(.callout)
            subtitle.fontColor = theme.statusTextColor.skColor.withAlphaComponent(0.6)
            subtitle.position = CGPoint(x: size.width / 2, y: size.height / 2 + 130)
            subtitle.zPosition = 102
            subtitle.name = "difficultyOverlay"
            addChild(subtitle)
        }

        let yOffset: CGFloat = isZenTheme ? 0 : 15
        createDifficultyOption(title: "Easy", subtitle: isZenTheme ? "初級" : nil, position: CGPoint(x: size.width / 2, y: size.height / 2 + 70 + yOffset), name: "difficulty_easy")
        createDifficultyOption(title: "Medium", subtitle: isZenTheme ? "中級" : nil, position: CGPoint(x: size.width / 2, y: size.height / 2 + 5 + yOffset), name: "difficulty_medium")
        createDifficultyOption(title: "Hard", subtitle: isZenTheme ? "上級" : nil, position: CGPoint(x: size.width / 2, y: size.height / 2 - 60 + yOffset), name: "difficulty_hard")

        // Practice mode toggle
        createPracticeModeToggle(position: CGPoint(x: size.width / 2, y: size.height / 2 - 130))

        let cancel = SKLabelNode(fontNamed: uiFont)
        cancel.text = isZenTheme ? "Cancel · 取消" : "Cancel"
        cancel.fontSize = fontSize(.callout)
        cancel.fontColor = theme.statusTextColor.skColor.withAlphaComponent(0.6)
        cancel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 175)
        cancel.zPosition = 102
        cancel.name = "cancelDifficulty"
        addChild(cancel)
    }

    private func createPracticeModeToggle(position: CGPoint) {
        let container = SKNode()
        container.position = position
        container.zPosition = 102
        container.name = "practiceToggle"
        addChild(container)

        // Toggle background
        let toggleBg = SKShapeNode(rectOf: CGSize(width: 44, height: 26), cornerRadius: 13)
        toggleBg.fillColor = isPracticeModeEnabled ? bamboo : theme.buttonBackgroundColor.skColor
        toggleBg.strokeColor = isPracticeModeEnabled ? bamboo.withAlphaComponent(0.8) : theme.buttonStrokeColor.skColor
        toggleBg.lineWidth = 1.5
        toggleBg.position = CGPoint(x: 80, y: 0)
        toggleBg.name = "practiceToggle"
        container.addChild(toggleBg)

        // Toggle knob
        let knob = SKShapeNode(circleOfRadius: 10)
        knob.fillColor = .white
        knob.strokeColor = SKColor.gray.withAlphaComponent(0.3)
        knob.lineWidth = 0.5
        knob.position = CGPoint(x: isPracticeModeEnabled ? 90 : 70, y: 0)
        knob.name = "practiceToggleKnob"
        container.addChild(knob)

        // Label
        let label = SKLabelNode(fontNamed: uiFont)
        label.text = isZenTheme ? "Practice Mode · 練習" : "Practice Mode"
        label.fontSize = fontSize(.callout)
        label.fontColor = theme.statusTextColor.skColor.withAlphaComponent(0.8)
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: -100, y: 0)
        label.name = "practiceToggle"
        container.addChild(label)

        // Subtitle
        let subtitle = SKLabelNode(fontNamed: uiFont)
        subtitle.text = isZenTheme ? "Stats not recorded" : "Stats not recorded"
        subtitle.fontSize = fontSize(.caption)
        subtitle.fontColor = theme.statusTextColor.skColor.withAlphaComponent(0.5)
        subtitle.horizontalAlignmentMode = .left
        subtitle.verticalAlignmentMode = .center
        subtitle.position = CGPoint(x: -100, y: -16)
        subtitle.name = "practiceToggle"
        container.addChild(subtitle)
    }

    private func togglePracticeMode() {
        isPracticeModeEnabled.toggle()
        SoundManager.shared.buttonTapped()

        // Update toggle visual
        enumerateChildNodes(withName: "practiceToggle") { node, _ in
            node.removeFromParent()
        }
        enumerateChildNodes(withName: "practiceToggleKnob") { node, _ in
            node.removeFromParent()
        }

        createPracticeModeToggle(position: CGPoint(x: size.width / 2, y: size.height / 2 - 130))
    }

    private func createDifficultyOption(title: String, subtitle: String?, position: CGPoint, name: String) {
        let container = SKNode()
        container.position = position
        container.zPosition = 102
        container.name = name
        addChild(container)

        let bg = SKShapeNode(rectOf: CGSize(width: 250, height: 50), cornerRadius: 10)
        bg.fillColor = theme.buttonBackgroundColor.skColor
        bg.strokeColor = theme.buttonStrokeColor.skColor
        bg.lineWidth = 1.5
        bg.name = name
        container.addChild(bg)

        let titleLabel = SKLabelNode(fontNamed: uiFont)
        if let subtitle = subtitle {
            titleLabel.text = "\(title) · \(subtitle)"
        } else {
            titleLabel.text = title
        }
        titleLabel.fontSize = fontSize(.headline)
        titleLabel.fontColor = theme.buttonTextColor.skColor
        titleLabel.position = CGPoint(x: 0, y: -5)
        titleLabel.name = name
        container.addChild(titleLabel)
    }

    private func hideDifficultySelection() {
        for name in ["difficultyOverlay", "cancelDifficulty", "difficulty_easy", "difficulty_medium", "difficulty_hard", "practiceToggle", "practiceToggleKnob"] {
            enumerateChildNodes(withName: name) { node, _ in
                node.run(SKAction.sequence([SKAction.fadeOut(withDuration: 0.2), SKAction.removeFromParent()]))
            }
        }
    }

    // MARK: - Continue Prompt

    private func showContinuePrompt() {
        let overlayColor = theme.statusTextColor.skColor

        // Background overlay
        let overlay = SKShapeNode(rect: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        overlay.fillColor = overlayColor.withAlphaComponent(0.5)
        overlay.strokeColor = .clear
        overlay.zPosition = 100
        overlay.name = "continuePromptOverlay"
        overlay.alpha = 0
        addChild(overlay)
        overlay.run(SKAction.fadeAlpha(to: 1.0, duration: 0.25))

        // Modal background - increased height for better spacing
        let modal = SKShapeNode(rectOf: CGSize(width: 300, height: 260), cornerRadius: 16)
        modal.fillColor = theme.statusBackgroundColor.skColor
        modal.strokeColor = theme.statusStrokeColor.skColor
        modal.lineWidth = 2
        modal.position = CGPoint(x: size.width / 2, y: size.height / 2)
        modal.zPosition = 101
        modal.name = "continuePromptOverlay"
        modal.setScale(0.9)
        modal.alpha = 0
        addChild(modal)
        modal.run(SKAction.group([
            SKAction.fadeIn(withDuration: 0.25),
            SKAction.scale(to: 1.0, duration: 0.25)
        ]))

        // Title
        let title = SKLabelNode(fontNamed: uiFontBold)
        title.text = isZenTheme ? "中断中のゲーム" : "Game in Progress"
        title.fontSize = fontSize(.title)
        title.fontColor = theme.statusTextColor.skColor
        title.position = CGPoint(x: size.width / 2, y: size.height / 2 + 85)
        title.zPosition = 102
        title.name = "continuePromptOverlay"
        title.alpha = 0
        addChild(title)
        title.run(SKAction.fadeIn(withDuration: 0.25))

        // Subtitle
        let subtitle = SKLabelNode(fontNamed: uiFont)
        subtitle.text = isZenTheme ? "ゲームを続けますか？" : "Would you like to continue?"
        subtitle.fontSize = fontSize(.headline)
        subtitle.fontColor = theme.statusTextColor.skColor.withAlphaComponent(0.8)
        subtitle.position = CGPoint(x: size.width / 2, y: size.height / 2 + 50)
        subtitle.zPosition = 102
        subtitle.name = "continuePromptOverlay"
        subtitle.alpha = 0
        addChild(subtitle)
        subtitle.run(SKAction.fadeIn(withDuration: 0.25))

        // Continue button
        let continueBtn = SKShapeNode(rectOf: CGSize(width: 220, height: 52), cornerRadius: 12)
        continueBtn.fillColor = buttonGreen
        continueBtn.strokeColor = .clear
        continueBtn.position = CGPoint(x: size.width / 2, y: size.height / 2 - 10)
        continueBtn.zPosition = 102
        continueBtn.name = "promptContinue"
        continueBtn.alpha = 0
        addChild(continueBtn)
        continueBtn.run(SKAction.fadeIn(withDuration: 0.25))

        let continueLabel = SKLabelNode(fontNamed: uiFontBold)
        continueLabel.text = isZenTheme ? "続ける" : "Continue"
        continueLabel.fontSize = fontSize(.headline)
        continueLabel.fontColor = .white
        continueLabel.verticalAlignmentMode = .center
        continueLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 10)
        continueLabel.zPosition = 103
        continueLabel.name = "promptContinue"
        continueLabel.alpha = 0
        addChild(continueLabel)
        continueLabel.run(SKAction.fadeIn(withDuration: 0.25))

        // New Game button
        let newGameBtn = SKShapeNode(rectOf: CGSize(width: 220, height: 52), cornerRadius: 12)
        newGameBtn.fillColor = buttonGray
        newGameBtn.strokeColor = .clear
        newGameBtn.position = CGPoint(x: size.width / 2, y: size.height / 2 - 75)
        newGameBtn.zPosition = 102
        newGameBtn.name = "promptNewGame"
        newGameBtn.alpha = 0
        addChild(newGameBtn)
        newGameBtn.run(SKAction.fadeIn(withDuration: 0.25))

        let newGameLabel = SKLabelNode(fontNamed: uiFontBold)
        newGameLabel.text = isZenTheme ? "新規ゲーム" : "New Game"
        newGameLabel.fontSize = fontSize(.headline)
        newGameLabel.fontColor = .white
        newGameLabel.verticalAlignmentMode = .center
        newGameLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 75)
        newGameLabel.zPosition = 103
        newGameLabel.name = "promptNewGame"
        newGameLabel.alpha = 0
        addChild(newGameLabel)
        newGameLabel.run(SKAction.fadeIn(withDuration: 0.25))
    }

    private func hideContinuePrompt() {
        enumerateChildNodes(withName: "continuePromptOverlay") { node, _ in
            node.run(SKAction.sequence([SKAction.fadeOut(withDuration: 0.2), SKAction.removeFromParent()]))
        }
        enumerateChildNodes(withName: "promptContinue") { node, _ in
            node.run(SKAction.sequence([SKAction.fadeOut(withDuration: 0.2), SKAction.removeFromParent()]))
        }
        enumerateChildNodes(withName: "promptNewGame") { node, _ in
            node.run(SKAction.sequence([SKAction.fadeOut(withDuration: 0.2), SKAction.removeFromParent()]))
        }
    }

    private func handleContinuePromptSelection(name: String) {
        SoundManager.shared.buttonTapped()

        if name == "promptContinue" {
            hideContinuePrompt()
            continueGame()
        } else if name == "promptNewGame" || name == "continuePromptOverlay" {
            hideContinuePrompt()
        }
    }

    // MARK: - Navigation

    private func startGame(mode: GameMode, difficulty: AIDifficulty, isPractice: Bool = false) {
        let transition = SKTransition.fade(withDuration: 0.4)
        let scene = GameScene(size: size)
        scene.scaleMode = .aspectFill
        scene.gameMode = mode
        scene.aiDifficulty = difficulty
        scene.isPracticeMode = isPractice
        view?.presentScene(scene, transition: transition)
    }

    private func continueGame() {
        guard let savedGame = GameStateManager.shared.loadSavedGame() else {
            return
        }

        let transition = SKTransition.fade(withDuration: 0.4)
        let scene = GameScene(size: size)
        scene.scaleMode = .aspectFill
        scene.gameMode = savedGame.gameMode
        scene.aiDifficulty = savedGame.aiDifficulty
        scene.restoredGame = savedGame
        view?.presentScene(scene, transition: transition)
    }

    private func showStatistics() {
        let transition = SKTransition.fade(withDuration: 0.4)
        let scene = StatisticsScene(size: size)
        scene.scaleMode = .aspectFill
        view?.presentScene(scene, transition: transition)
    }

    private func showSettings() {
        let transition = SKTransition.fade(withDuration: 0.4)
        let scene = SettingsScene(size: size)
        scene.scaleMode = .aspectFill
        view?.presentScene(scene, transition: transition)
    }

    private func showHowToPlay() {
        let transition = SKTransition.fade(withDuration: 0.4)
        let scene = HowToPlayScene(size: size)
        scene.scaleMode = .aspectFill
        view?.presentScene(scene, transition: transition)
    }

    private func showShop() {
        let transition = SKTransition.fade(withDuration: 0.4)
        let scene = ShopScene(size: size)
        scene.scaleMode = .aspectFill
        view?.presentScene(scene, transition: transition)
    }

    private func startOnlineGame() {
        guard GameCenterManager.shared.isAuthenticated else {
            showNotAuthenticatedAlert()
            return
        }
        guard let vc = view?.window?.rootViewController else { return }
        GameCenterManager.shared.findMatch(from: vc) { [weak self] match, _ in
            guard let self = self, let match = match else { return }
            DispatchQueue.main.async {
                let transition = SKTransition.fade(withDuration: 0.4)
                let scene = OnlineGameScene(size: self.size)
                scene.scaleMode = .aspectFill
                scene.match = match
                self.view?.presentScene(scene, transition: transition)
            }
        }
    }

    private func showGameCenter() {
        guard GameCenterManager.shared.isAuthenticated else {
            showNotAuthenticatedAlert()
            return
        }
        guard let vc = view?.window?.rootViewController else { return }
        let gcVC = GKGameCenterViewController(state: .default)
        gcVC.gameCenterDelegate = self
        vc.present(gcVC, animated: true)
    }

    private func showNotAuthenticatedAlert() {
        guard let vc = view?.window?.rootViewController else { return }
        let alert = UIAlertController(title: "Game Center", message: "Please sign in to Game Center.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        vc.present(alert, animated: true)
    }
}

extension MenuScene: GKGameCenterControllerDelegate {
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
}
