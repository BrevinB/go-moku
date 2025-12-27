//
//  SettingsScene.swift
//  Gomoku
//
//  Created by Brevin Blalock on 10/13/25.
//

import SpriteKit

class SettingsScene: SKScene {

    // Theme reference
    private var theme: BoardTheme { ThemeManager.shared.currentTheme }
    private var isZenTheme: Bool { theme.id == "zen" }
    private var uiFont: String { isZenTheme ? "Hiragino Mincho ProN" : "AvenirNext-Medium" }

    // Theme-derived colors
    private var primaryTextColor: SKColor { theme.boardColor.skColor }
    private var secondaryTextColor: SKColor { theme.gridLineColor.skColor }
    private var accentColor: SKColor { theme.decorativeCircleColors.first?.skColor ?? SKColor.gray }
    private var secondaryAccent: SKColor { theme.decorativeCircleColors.count > 1 ? theme.decorativeCircleColors[1].skColor : accentColor }

    // Static accent colors
    private let toggleOnColor = SKColor(red: 0.45, green: 0.52, blue: 0.35, alpha: 1.0)
    private let toggleOffColor = SKColor(red: 0.40, green: 0.38, blue: 0.35, alpha: 0.4)
    private let dangerColor = SKColor(red: 0.75, green: 0.22, blue: 0.17, alpha: 1.0)

    override func didMove(to view: SKView) {
        setupBackground()
        setupDecorations()
        setupHeader()
        setupSettings()
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

        // Small decorative circle
        let circle2 = SKShapeNode(circleOfRadius: 80)
        circle2.fillColor = accentColor.withAlphaComponent(0.04)
        circle2.strokeColor = .clear
        circle2.position = CGPoint(x: 50, y: 200)
        circle2.zPosition = -90
        addChild(circle2)
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
            circle2.position = CGPoint(x: 50, y: 200)
            circle2.zPosition = -90
            addChild(circle2)

            let circle3 = SKShapeNode(circleOfRadius: 60)
            circle3.fillColor = decorativeColors[2].skColor
            circle3.strokeColor = .clear
            circle3.position = CGPoint(x: size.width - 100, y: 400)
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
        titleLabel.text = isZenTheme ? "設定" : "Settings"
        titleLabel.fontSize = 36
        titleLabel.fontColor = primaryTextColor
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height - 100)
        titleLabel.zPosition = 10
        addChild(titleLabel)

        // Subtitle (only for Zen theme)
        if isZenTheme {
            let subtitle = SKLabelNode(fontNamed: uiFont)
            subtitle.text = "Settings"
            subtitle.fontSize = 16
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

    private func setupSettings() {
        let centerY = size.height / 2 + 80

        // Sound settings
        createSettingRow(
            title: isZenTheme ? "音効" : "Sound Effects",
            subtitle: isZenTheme ? "Sound Effects" : nil,
            yPosition: centerY,
            isEnabled: SoundManager.shared.isSoundEnabled(),
            toggleName: "soundToggle"
        )

        // Haptics settings
        createSettingRow(
            title: isZenTheme ? "振動" : "Haptic Feedback",
            subtitle: isZenTheme ? "Haptic Feedback" : nil,
            yPosition: centerY - 110,
            isEnabled: SoundManager.shared.isHapticsEnabled(),
            toggleName: "hapticsToggle"
        )

        #if DEBUG
        setupDebugSection(yPosition: centerY - 260)
        #endif
    }

    #if DEBUG
    private func setupDebugSection(yPosition: CGFloat) {
        // Debug section header
        let debugLabel = SKLabelNode(fontNamed: uiFont)
        debugLabel.text = isZenTheme ? "開発者設定 · Debug" : "Debug Settings"
        debugLabel.fontSize = 16
        debugLabel.fontColor = dangerColor
        debugLabel.position = CGPoint(x: size.width / 2, y: yPosition + 60)
        debugLabel.zPosition = 10
        addChild(debugLabel)

        // Coin balance display
        let balanceLabel = SKLabelNode(fontNamed: uiFont)
        balanceLabel.text = isZenTheme ? "所持コイン: \(CoinManager.shared.balance)" : "Balance: \(CoinManager.shared.balance) coins"
        balanceLabel.fontSize = 14
        balanceLabel.fontColor = secondaryTextColor
        balanceLabel.position = CGPoint(x: size.width / 2, y: yPosition + 30)
        balanceLabel.name = "debugBalanceLabel"
        balanceLabel.zPosition = 10
        addChild(balanceLabel)

        // Button row
        let buttonY = yPosition - 10
        let buttonSpacing: CGFloat = 90

        // +100 coins button
        createDebugButton(
            title: "+100",
            position: CGPoint(x: size.width / 2 - buttonSpacing, y: buttonY),
            name: "debug_add100",
            color: toggleOnColor
        )

        // +500 coins button
        createDebugButton(
            title: "+500",
            position: CGPoint(x: size.width / 2, y: buttonY),
            name: "debug_add500",
            color: accentColor
        )

        // Reset button
        createDebugButton(
            title: isZenTheme ? "リセット" : "Reset",
            position: CGPoint(x: size.width / 2 + buttonSpacing, y: buttonY),
            name: "debug_reset",
            color: dangerColor
        )

        // Unlock all themes button
        createDebugButton(
            title: isZenTheme ? "全テーマ解放" : "Unlock Themes",
            position: CGPoint(x: size.width / 2, y: buttonY - 55),
            name: "debug_unlockThemes",
            color: secondaryTextColor,
            width: 160
        )
    }

    private func createDebugButton(title: String, position: CGPoint, name: String, color: SKColor, width: CGFloat = 75) {
        let button = SKShapeNode(rectOf: CGSize(width: width, height: 36), cornerRadius: 6)
        button.fillColor = color
        button.strokeColor = color.withAlphaComponent(0.3)
        button.lineWidth = 1
        button.position = position
        button.name = name
        button.zPosition = 10
        addChild(button)

        let label = SKLabelNode(fontNamed: uiFont)
        label.text = title
        label.fontSize = 14
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.position = .zero
        label.zPosition = 1
        button.addChild(label)
    }

    private func updateDebugBalanceLabel() {
        if let label = childNode(withName: "debugBalanceLabel") as? SKLabelNode {
            label.text = isZenTheme ? "所持コイン: \(CoinManager.shared.balance)" : "Balance: \(CoinManager.shared.balance) coins"
        }
    }
    #endif

    private func createSettingRow(title: String, subtitle: String?, yPosition: CGFloat, isEnabled: Bool, toggleName: String) {
        let cardWidth: CGFloat = 320
        let cardHeight: CGFloat = subtitle != nil ? 75 : 60

        // Card background
        let card = SKShapeNode(rectOf: CGSize(width: cardWidth, height: cardHeight), cornerRadius: 8)
        card.fillColor = SKColor.white.withAlphaComponent(0.7)
        card.strokeColor = accentColor.withAlphaComponent(0.3)
        card.lineWidth = 1
        card.position = CGPoint(x: size.width / 2, y: yPosition)
        card.zPosition = 5
        addChild(card)

        // Accent line on left
        let accent = SKShapeNode(rectOf: CGSize(width: 3, height: cardHeight - 16), cornerRadius: 1.5)
        accent.fillColor = toggleOnColor
        accent.strokeColor = .clear
        accent.position = CGPoint(x: size.width / 2 - cardWidth/2 + 10, y: yPosition)
        accent.zPosition = 6
        addChild(accent)

        // Title
        let titleLabel = SKLabelNode(fontNamed: uiFont)
        titleLabel.text = title
        titleLabel.fontSize = 18
        titleLabel.fontColor = primaryTextColor
        titleLabel.horizontalAlignmentMode = .left
        titleLabel.position = CGPoint(x: size.width / 2 - cardWidth/2 + 24, y: yPosition + (subtitle != nil ? 8 : 0))
        titleLabel.zPosition = 6
        addChild(titleLabel)

        // Subtitle (if provided)
        if let subtitle = subtitle {
            let subtitleLabel = SKLabelNode(fontNamed: uiFont)
            subtitleLabel.text = subtitle
            subtitleLabel.fontSize = 11
            subtitleLabel.fontColor = secondaryTextColor
            subtitleLabel.horizontalAlignmentMode = .left
            subtitleLabel.position = CGPoint(x: size.width / 2 - cardWidth/2 + 24, y: yPosition - 12)
            subtitleLabel.zPosition = 6
            addChild(subtitleLabel)
        }

        // Toggle background
        let toggleBg = SKShapeNode(rectOf: CGSize(width: 56, height: 32), cornerRadius: 16)
        toggleBg.fillColor = isEnabled ? toggleOnColor : toggleOffColor
        toggleBg.strokeColor = isEnabled ? SKColor(red: 0.35, green: 0.42, blue: 0.25, alpha: 1.0) : secondaryTextColor.withAlphaComponent(0.2)
        toggleBg.lineWidth = 1
        toggleBg.position = CGPoint(x: size.width / 2 + cardWidth/2 - 45, y: yPosition)
        toggleBg.name = toggleName
        toggleBg.zPosition = 6
        addChild(toggleBg)

        // Toggle knob
        let knob = SKShapeNode(circleOfRadius: 12)
        knob.fillColor = theme.backgroundGradient.topColor.skColor
        knob.strokeColor = accentColor.withAlphaComponent(0.3)
        knob.lineWidth = 1
        let knobX: CGFloat = isEnabled ? 12 : -12
        knob.position = CGPoint(x: knobX, y: 0)
        knob.name = "\(toggleName)_knob"
        knob.zPosition = 1
        toggleBg.addChild(knob)
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
        label.fontSize = 16
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
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodes = self.nodes(at: location)

        for node in nodes {
            guard let nodeName = node.name else { continue }

            if nodeName == "backButton" {
                SoundManager.shared.buttonTapped()
                goBackToMenu()
                return
            }

            if nodeName == "soundToggle" {
                let currentState = SoundManager.shared.isSoundEnabled()
                SoundManager.shared.setSoundEnabled(!currentState)
                animateToggle(node, enabled: !currentState)
                if !currentState {
                    SoundManager.shared.playButton()
                }
                return
            }

            if nodeName == "hapticsToggle" {
                let currentState = SoundManager.shared.isHapticsEnabled()
                SoundManager.shared.setHapticsEnabled(!currentState)
                animateToggle(node, enabled: !currentState)
                if !currentState {
                    SoundManager.shared.hapticMedium()
                }
                return
            }

            #if DEBUG
            if nodeName == "debug_add100" {
                CoinManager.shared.addCoins(100)
                animateButtonPress(node)
                updateDebugBalanceLabel()
                SoundManager.shared.buttonTapped()
                return
            }

            if nodeName == "debug_add500" {
                CoinManager.shared.addCoins(500)
                animateButtonPress(node)
                updateDebugBalanceLabel()
                SoundManager.shared.buttonTapped()
                return
            }

            if nodeName == "debug_reset" {
                CoinManager.shared.resetBalance()
                animateButtonPress(node)
                updateDebugBalanceLabel()
                SoundManager.shared.buttonTapped()
                return
            }

            if nodeName == "debug_unlockThemes" {
                ThemeManager.shared.unlockAllThemes()
                animateButtonPress(node)
                SoundManager.shared.buttonTapped()
                return
            }
            #endif
        }

        // Reset scales
        for child in children where child.zPosition == 10 {
            child.run(SKAction.scale(to: 1.0, duration: 0.1))
        }
    }

    private func animateToggle(_ node: SKNode, enabled: Bool) {
        guard let toggle = node as? SKShapeNode else { return }
        guard let knob = toggle.childNode(withName: "\(node.name ?? "")_knob") else { return }

        // Animate background color
        let colorAction = SKAction.customAction(withDuration: 0.25) { [weak self] node, elapsedTime in
            guard let self = self, let shapeNode = node as? SKShapeNode else { return }
            let progress = elapsedTime / 0.25

            if enabled {
                shapeNode.fillColor = self.interpolateColor(
                    from: self.toggleOffColor,
                    to: self.toggleOnColor,
                    progress: progress
                )
            } else {
                shapeNode.fillColor = self.interpolateColor(
                    from: self.toggleOnColor,
                    to: self.toggleOffColor,
                    progress: progress
                )
            }
        }

        // Animate knob position
        let targetX: CGFloat = enabled ? 12 : -12
        let moveAction = SKAction.moveTo(x: targetX, duration: 0.25)
        moveAction.timingMode = .easeInEaseOut

        toggle.run(colorAction)
        knob.run(moveAction)
    }

    private func animateButtonPress(_ node: SKNode) {
        let scaleDown = SKAction.scale(to: 0.95, duration: 0.1)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.1)
        node.run(SKAction.sequence([scaleDown, scaleUp]))
    }

    private func goBackToMenu() {
        let transition = SKTransition.fade(withDuration: 0.4)
        let menuScene = MenuScene(size: size)
        menuScene.scaleMode = .aspectFill
        view?.presentScene(menuScene, transition: transition)
    }
}
