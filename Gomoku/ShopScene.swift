//
//  ShopScene.swift
//  Gomoku
//
//  Created by Claude on 12/13/25.
//

import SpriteKit

class ShopScene: SKScene {

    // MARK: - Theme Reference
    private var theme: BoardTheme { ThemeManager.shared.currentTheme }
    private var isZenTheme: Bool { theme.id == "zen" }
    private var uiFont: String { isZenTheme ? "Hiragino Mincho ProN" : "AvenirNext-Medium" }
    private var uiFontBold: String { isZenTheme ? "Hiragino Mincho ProN" : "AvenirNext-DemiBold" }

    // Theme-derived colors
    private var primaryTextColor: SKColor { theme.boardColor.skColor }
    private var secondaryTextColor: SKColor { theme.gridLineColor.skColor }
    private var accentColor: SKColor { theme.decorativeCircleColors.first?.skColor ?? SKColor.gray }
    private var secondaryAccent: SKColor { theme.decorativeCircleColors.count > 1 ? theme.decorativeCircleColors[1].skColor : accentColor }

    // Premium accent colors
    private let gold = SKColor(red: 0.92, green: 0.75, blue: 0.30, alpha: 1.0)
    private let goldDark = SKColor(red: 0.75, green: 0.58, blue: 0.18, alpha: 1.0)
    private let goldLight = SKColor(red: 1.0, green: 0.88, blue: 0.55, alpha: 1.0)
    private let purchaseGreen = SKColor(red: 0.35, green: 0.65, blue: 0.45, alpha: 1.0)
    private let purchaseGreenDark = SKColor(red: 0.25, green: 0.50, blue: 0.32, alpha: 1.0)
    private let selectedBlue = SKColor(red: 0.30, green: 0.55, blue: 0.78, alpha: 1.0)
    private let premiumPurple = SKColor(red: 0.55, green: 0.40, blue: 0.75, alpha: 1.0)

    // UI Elements
    private var coinDisplayContainer: SKNode!
    private var coinLabel: SKLabelNode!
    private var coinIcon: SKNode!
    private var hintDisplayContainer: SKNode!
    private var hintLabel: SKLabelNode!
    private var themeNodes: [SKNode] = []
    private var coinPackNodes: [SKNode] = []
    private var hintPackNodes: [SKNode] = []
    private var particleLayer: SKNode!

    // Scrolling
    private var scrollContainer: SKNode!
    private var scrollContentHeight: CGFloat = 0
    private var lastTouchY: CGFloat = 0
    private var scrollVelocity: CGFloat = 0
    private var isScrolling = false
    private var headerNode: SKNode!

    // Loading state
    private var isLoading = false
    private var loadingOverlay: SKNode?

    // Layout constants - using fixed values like MenuScene to avoid safe area calculation issues
    // 59 is the standard Dynamic Island safe area; this works for all modern iPhones
    private let topInset: CGFloat = 59
    private let headerHeight: CGFloat = 140
    private let sectionSpacing: CGFloat = 30

    // MARK: - Scene Lifecycle

    override func didMove(to view: SKView) {
        initializeFontScaling()

        // Setup everything synchronously with fixed layout values
        setupParticleLayer()
        setupBackground()
        setupDecorations()
        setupScrollContainer()
        setupHeader()
        setupScrollableContent()

        // Initialize scroll state
        scrollVelocity = 0
        isScrolling = false
        scrollContainer.position.y = 0

        // Ambient coin sparkle
        startAmbientSparkles()

        // Observers
        NotificationCenter.default.addObserver(self, selector: #selector(updateCoinDisplay), name: .coinsUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateHintDisplay), name: .hintsUpdated, object: nil)
    }

    override func willMove(from view: SKView) {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Particle Layer

    private func setupParticleLayer() {
        particleLayer = SKNode()
        particleLayer.zPosition = 500
        addChild(particleLayer)
    }

    // MARK: - Background

    private func setupBackground() {
        let topColor = theme.backgroundGradient.topColor.skColor
        let midColor = theme.backgroundGradient.midColor.skColor
        let bottomColor = theme.backgroundGradient.bottomColor.skColor

        let steps = 12
        for i in 0..<steps {
            let progress = CGFloat(i) / CGFloat(steps - 1)
            let color: SKColor
            if progress < 0.5 {
                color = interpolateColor(from: topColor, to: midColor, progress: progress * 2)
            } else {
                color = interpolateColor(from: midColor, to: bottomColor, progress: (progress - 0.5) * 2)
            }
            let height = size.height / CGFloat(steps)
            let rect = SKShapeNode(rect: CGRect(x: 0, y: CGFloat(steps - 1 - i) * height, width: size.width, height: height + 1))
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
            setupModernDecorations()
        }
    }

    private func setupZenDecorations() {
        let gridAlpha: CGFloat = 0.025
        for i in stride(from: CGFloat(50), to: size.width, by: 50) {
            let line = SKShapeNode(rectOf: CGSize(width: 0.5, height: size.height))
            line.fillColor = primaryTextColor.withAlphaComponent(gridAlpha)
            line.strokeColor = .clear
            line.position = CGPoint(x: i, y: size.height / 2)
            line.zPosition = -95
            addChild(line)
        }
        for i in stride(from: CGFloat(50), to: size.height, by: 50) {
            let line = SKShapeNode(rectOf: CGSize(width: size.width, height: 0.5))
            line.fillColor = primaryTextColor.withAlphaComponent(gridAlpha)
            line.strokeColor = .clear
            line.position = CGPoint(x: size.width / 2, y: i)
            line.zPosition = -95
            addChild(line)
        }

        let circle = SKShapeNode(circleOfRadius: 120)
        circle.fillColor = primaryTextColor.withAlphaComponent(0.02)
        circle.strokeColor = .clear
        circle.position = CGPoint(x: size.width - 40, y: size.height - 60)
        circle.zPosition = -90
        addChild(circle)
    }

    private func setupModernDecorations() {
        let orbConfigs: [(x: CGFloat, y: CGFloat, radius: CGFloat, color: SKColor)] = [
            (0.9, 0.85, 100, gold.withAlphaComponent(0.08)),
            (0.1, 0.7, 80, purchaseGreen.withAlphaComponent(0.06)),
            (0.85, 0.3, 120, accentColor.withAlphaComponent(0.05)),
            (0.15, 0.2, 90, secondaryAccent.withAlphaComponent(0.04))
        ]

        for config in orbConfigs {
            let glow = SKShapeNode(circleOfRadius: config.radius * 1.5)
            glow.fillColor = config.color.withAlphaComponent(0.02)
            glow.strokeColor = .clear
            glow.position = CGPoint(x: size.width * config.x, y: size.height * config.y)
            glow.zPosition = -92
            addChild(glow)

            let orb = SKShapeNode(circleOfRadius: config.radius)
            orb.fillColor = config.color
            orb.strokeColor = .clear
            orb.position = CGPoint(x: size.width * config.x, y: size.height * config.y)
            orb.zPosition = -90
            addChild(orb)

            let moveUp = SKAction.moveBy(x: 0, y: 15, duration: Double.random(in: 3...5))
            let moveDown = SKAction.moveBy(x: 0, y: -15, duration: Double.random(in: 3...5))
            moveUp.timingMode = .easeInEaseOut
            moveDown.timingMode = .easeInEaseOut
            orb.run(SKAction.repeatForever(SKAction.sequence([moveUp, moveDown])))
            glow.run(SKAction.repeatForever(SKAction.sequence([moveUp, moveDown])))
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

    // MARK: - Scroll Container

    private func setupScrollContainer() {
        scrollContainer = SKNode()
        scrollContainer.zPosition = 5
        addChild(scrollContainer)
    }

    // MARK: - Header (Fixed, not scrollable)

    private func setupHeader() {
        headerNode = SKNode()
        headerNode.zPosition = 100
        addChild(headerNode)

        // Header background to cover scroll content
        let headerBg = SKShapeNode(rect: CGRect(x: 0, y: size.height - topInset - headerHeight, width: size.width, height: topInset + headerHeight))
        headerBg.fillColor = theme.backgroundGradient.topColor.skColor
        headerBg.strokeColor = .clear
        headerBg.zPosition = 99
        addChild(headerBg)

        // Back button - positioned below safe area
        let backContainer = SKNode()
        backContainer.position = CGPoint(x: 50, y: size.height - topInset - 35)
        backContainer.name = "backButton"
        backContainer.zPosition = 101
        headerNode.addChild(backContainer)

        let bg = SKShapeNode(rectOf: CGSize(width: 75, height: 36), cornerRadius: 18)
        bg.fillColor = theme.buttonBackgroundColor.skColor
        bg.strokeColor = theme.buttonStrokeColor.skColor
        bg.lineWidth = 1.5
        bg.name = "backButton"
        backContainer.addChild(bg)

        let label = SKLabelNode(fontNamed: uiFont)
        label.text = isZenTheme ? "← 戻る" : "← Back"
        label.fontSize = fontSize(.callout)
        label.fontColor = theme.buttonTextColor.skColor
        label.verticalAlignmentMode = .center
        label.name = "backButton"
        backContainer.addChild(label)

        // Title
        let titleContainer = SKNode()
        titleContainer.position = CGPoint(x: size.width / 2, y: size.height - topInset - 35)
        titleContainer.zPosition = 101
        headerNode.addChild(titleContainer)

        let titleLabel = SKLabelNode(fontNamed: uiFontBold)
        titleLabel.text = isZenTheme ? "商店" : "Shop"
        titleLabel.fontSize = scaledFontSize(28)
        titleLabel.fontColor = primaryTextColor
        titleContainer.addChild(titleLabel)

        // Decorative line
        let line = SKShapeNode(rectOf: CGSize(width: 50, height: 3), cornerRadius: 1.5)
        line.fillColor = gold
        line.strokeColor = .clear
        line.position = CGPoint(x: size.width / 2, y: size.height - topInset - 60)
        line.zPosition = 101
        headerNode.addChild(line)

        // Currency displays
        setupCurrencyDisplays()
    }

    private func setupCurrencyDisplays() {
        // Coin display
        coinDisplayContainer = SKNode()
        coinDisplayContainer.position = CGPoint(x: size.width / 2 - 55, y: size.height - topInset - 100)
        coinDisplayContainer.zPosition = 101
        headerNode.addChild(coinDisplayContainer)

        let coinBg = SKShapeNode(rectOf: CGSize(width: 100, height: 45), cornerRadius: 12)
        coinBg.fillColor = SKColor.white.withAlphaComponent(0.95)
        coinBg.strokeColor = gold.withAlphaComponent(0.5)
        coinBg.lineWidth = 2
        coinDisplayContainer.addChild(coinBg)

        let coinShadow = SKShapeNode(rectOf: CGSize(width: 100, height: 45), cornerRadius: 12)
        coinShadow.fillColor = SKColor.black.withAlphaComponent(0.1)
        coinShadow.strokeColor = .clear
        coinShadow.position = CGPoint(x: 2, y: -3)
        coinShadow.zPosition = -1
        coinDisplayContainer.addChild(coinShadow)

        coinIcon = createAnimatedCoinIcon(radius: 12)
        coinIcon.position = CGPoint(x: -30, y: 0)
        coinDisplayContainer.addChild(coinIcon)

        coinLabel = SKLabelNode(fontNamed: uiFontBold)
        coinLabel.text = "\(CoinManager.shared.balance)"
        coinLabel.fontSize = fontSize(.headline)
        coinLabel.fontColor = goldDark
        coinLabel.verticalAlignmentMode = .center
        coinLabel.horizontalAlignmentMode = .left
        coinLabel.position = CGPoint(x: -10, y: 0)
        coinDisplayContainer.addChild(coinLabel)

        // Hint display
        hintDisplayContainer = SKNode()
        hintDisplayContainer.position = CGPoint(x: size.width / 2 + 55, y: size.height - topInset - 100)
        hintDisplayContainer.zPosition = 101
        headerNode.addChild(hintDisplayContainer)

        let hintBg = SKShapeNode(rectOf: CGSize(width: 100, height: 45), cornerRadius: 12)
        hintBg.fillColor = SKColor.white.withAlphaComponent(0.95)
        hintBg.strokeColor = purchaseGreen.withAlphaComponent(0.5)
        hintBg.lineWidth = 2
        hintDisplayContainer.addChild(hintBg)

        let hintShadow = SKShapeNode(rectOf: CGSize(width: 100, height: 45), cornerRadius: 12)
        hintShadow.fillColor = SKColor.black.withAlphaComponent(0.1)
        hintShadow.strokeColor = .clear
        hintShadow.position = CGPoint(x: 2, y: -3)
        hintShadow.zPosition = -1
        hintDisplayContainer.addChild(hintShadow)

        let hintIcon = SKLabelNode(text: "💡")
        hintIcon.fontSize = fontSize(.title2)
        hintIcon.verticalAlignmentMode = .center
        hintIcon.position = CGPoint(x: -30, y: 0)
        hintDisplayContainer.addChild(hintIcon)

        hintLabel = SKLabelNode(fontNamed: uiFontBold)
        hintLabel.text = "\(HintManager.shared.balance)"
        hintLabel.fontSize = fontSize(.headline)
        hintLabel.fontColor = purchaseGreenDark
        hintLabel.verticalAlignmentMode = .center
        hintLabel.horizontalAlignmentMode = .left
        hintLabel.position = CGPoint(x: -10, y: 0)
        hintDisplayContainer.addChild(hintLabel)
    }

    private func createAnimatedCoinIcon(radius: CGFloat) -> SKNode {
        let container = SKNode()

        let coin = SKShapeNode(circleOfRadius: radius)
        coin.fillColor = gold
        coin.strokeColor = goldDark
        coin.lineWidth = 2
        coin.name = "coinBody"
        container.addChild(coin)

        let innerRing = SKShapeNode(circleOfRadius: radius * 0.7)
        innerRing.fillColor = .clear
        innerRing.strokeColor = goldDark.withAlphaComponent(0.3)
        innerRing.lineWidth = 1
        container.addChild(innerRing)

        let shine = SKShapeNode(circleOfRadius: radius * 0.35)
        shine.fillColor = goldLight.withAlphaComponent(0.6)
        shine.strokeColor = .clear
        shine.position = CGPoint(x: -radius * 0.25, y: radius * 0.25)
        container.addChild(shine)

        // Shimmer with crop mask
        let cropNode = SKCropNode()
        container.addChild(cropNode)

        let maskNode = SKShapeNode(circleOfRadius: radius)
        maskNode.fillColor = .white
        maskNode.strokeColor = .clear
        cropNode.maskNode = maskNode

        let shimmerContainer = SKNode()
        cropNode.addChild(shimmerContainer)

        let shimmerWidths: [(width: CGFloat, alpha: CGFloat)] = [
            (radius * 0.45, 0.2),
            (radius * 0.3, 0.35),
            (radius * 0.15, 0.7),
            (radius * 0.3, 0.35),
            (radius * 0.45, 0.2)
        ]

        var xOffset: CGFloat = -radius * 0.8
        for (width, alpha) in shimmerWidths {
            let shimmerLine = SKShapeNode(rectOf: CGSize(width: width, height: radius * 2.5), cornerRadius: width / 2)
            shimmerLine.fillColor = SKColor.white.withAlphaComponent(alpha)
            shimmerLine.strokeColor = .clear
            shimmerLine.position = CGPoint(x: xOffset, y: 0)
            shimmerContainer.addChild(shimmerLine)
            xOffset += width + radius * 0.04
        }

        shimmerContainer.zRotation = .pi / 6
        shimmerContainer.position = CGPoint(x: -radius * 1.5, y: 0)

        let shimMoveAcross = SKAction.moveTo(x: radius * 1.5, duration: 0.5)
        shimMoveAcross.timingMode = .easeInEaseOut
        let shimReset = SKAction.moveTo(x: -radius * 1.5, duration: 0)
        let shimWait = SKAction.wait(forDuration: 3.0)

        shimmerContainer.run(SKAction.repeatForever(SKAction.sequence([
            shimMoveAcross,
            shimReset,
            shimWait
        ])))

        return container
    }

    // MARK: - Scrollable Content

    private func setupScrollableContent() {
        let visibleTop = size.height - topInset - headerHeight - 20
        var currentY: CGFloat = visibleTop

        // Coin Packs Section
        currentY = setupCoinPackSection(at: currentY)
        currentY -= sectionSpacing

        // Hint Packs Section
        currentY = setupHintPackSection(at: currentY)
        currentY -= sectionSpacing

        // Themes Section
        currentY = setupThemeSection(at: currentY)
        currentY -= sectionSpacing

        // Legal Links Section
        currentY = setupLegalSection(at: currentY)
        currentY -= 50 // Bottom padding

        scrollContentHeight = visibleTop - currentY
    }

    // MARK: - Ambient Sparkles

    private func startAmbientSparkles() {
        let sparkleAction = SKAction.run { [weak self] in
            guard let self = self else { return }
            if let coinPos = self.coinDisplayContainer?.position {
                self.createSparkle(at: CGPoint(
                    x: coinPos.x + CGFloat.random(in: -40...40),
                    y: coinPos.y + CGFloat.random(in: -20...20)
                ), color: self.gold)
            }
        }
        let wait = SKAction.wait(forDuration: 2.0)
        run(SKAction.repeatForever(SKAction.sequence([wait, sparkleAction])))
    }

    private func createSparkle(at position: CGPoint, color: SKColor, count: Int = 1) {
        for _ in 0..<count {
            let sparkle = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.5...3))
            sparkle.fillColor = color
            sparkle.strokeColor = SKColor.white.withAlphaComponent(0.5)
            sparkle.lineWidth = 0.5
            sparkle.position = position
            sparkle.zPosition = 200
            sparkle.alpha = 0
            particleLayer.addChild(sparkle)

            let offsetX = CGFloat.random(in: -20...20)
            let offsetY = CGFloat.random(in: 10...30)

            let fadeIn = SKAction.fadeIn(withDuration: 0.15)
            let move = SKAction.moveBy(x: offsetX, y: offsetY, duration: 0.6)
            let fadeOut = SKAction.fadeOut(withDuration: 0.3)
            let scale = SKAction.scale(to: 0.3, duration: 0.6)
            let remove = SKAction.removeFromParent()

            move.timingMode = .easeOut
            sparkle.run(SKAction.sequence([
                fadeIn,
                SKAction.group([move, scale, SKAction.sequence([SKAction.wait(forDuration: 0.3), fadeOut])]),
                remove
            ]))
        }
    }

    // MARK: - Coin Pack Section

    private func setupCoinPackSection(at startY: CGFloat) -> CGFloat {
        var currentY = startY

        // Section header
        let headerContainer = createSectionHeader(
            title: isZenTheme ? "金貨パック" : "Coin Packs",
            subtitle: isZenTheme ? "Coin Packs" : nil,
            icon: "🪙",
            at: CGPoint(x: size.width / 2, y: currentY)
        )
        scrollContainer.addChild(headerContainer)
        currentY -= 35

        // Cards
        let packs = CoinPack.allCases
        let cardWidth: CGFloat = 100
        let cardHeight: CGFloat = 130
        let spacing: CGFloat = 12
        let totalWidth = CGFloat(packs.count) * cardWidth + CGFloat(packs.count - 1) * spacing
        let startX = (size.width - totalWidth) / 2 + cardWidth / 2
        let cardY = currentY - cardHeight / 2

        for (index, pack) in packs.enumerated() {
            let x = startX + CGFloat(index) * (cardWidth + spacing)
            let card = createCoinPackCard(pack: pack, at: CGPoint(x: x, y: cardY), size: CGSize(width: cardWidth, height: cardHeight), index: index)
            card.name = "coinPack_\(pack.rawValue)"
            scrollContainer.addChild(card)
            coinPackNodes.append(card)
        }

        return currentY - cardHeight - 10
    }

    private func createSectionHeader(title: String, subtitle: String?, icon: String, at position: CGPoint) -> SKNode {
        let container = SKNode()
        container.position = position

        let iconLabel = SKLabelNode(text: icon)
        iconLabel.fontSize = fontSize(.title2)
        iconLabel.position = CGPoint(x: -50, y: -5)
        container.addChild(iconLabel)

        let titleLabel = SKLabelNode(fontNamed: uiFontBold)
        titleLabel.text = title
        titleLabel.fontSize = fontSize(.headline)
        titleLabel.fontColor = primaryTextColor
        titleLabel.horizontalAlignmentMode = .left
        titleLabel.position = CGPoint(x: -30, y: 0)
        container.addChild(titleLabel)

        if let subtitle = subtitle {
            let subtitleLabel = SKLabelNode(fontNamed: uiFont)
            subtitleLabel.text = subtitle
            subtitleLabel.fontSize = fontSize(.footnote)
            subtitleLabel.fontColor = secondaryTextColor
            subtitleLabel.horizontalAlignmentMode = .left
            subtitleLabel.position = CGPoint(x: -30, y: -18)
            container.addChild(subtitleLabel)
        }

        return container
    }

    private func createCoinPackCard(pack: CoinPack, at position: CGPoint, size cardSize: CGSize, index: Int) -> SKNode {
        let container = SKNode()
        container.position = position

        let isBestValue = pack == .large
        let isPopular = pack == .medium

        // Card shadow
        let shadow = SKShapeNode(rectOf: CGSize(width: cardSize.width - 4, height: cardSize.height - 4), cornerRadius: 12)
        shadow.fillColor = SKColor.black.withAlphaComponent(0.12)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 2, y: -3)
        shadow.zPosition = -1
        container.addChild(shadow)

        // Card background
        let card = SKShapeNode(rectOf: cardSize, cornerRadius: 12)
        card.fillColor = SKColor.white
        card.strokeColor = isBestValue ? gold : (isPopular ? selectedBlue.withAlphaComponent(0.5) : accentColor.withAlphaComponent(0.3))
        card.lineWidth = isBestValue ? 2 : 1.5
        card.name = "coinPack_\(pack.rawValue)"
        container.addChild(card)

        // Top accent bar
        let accentBar = SKShapeNode(rectOf: CGSize(width: cardSize.width - 16, height: 3), cornerRadius: 1.5)
        accentBar.fillColor = gold
        accentBar.strokeColor = .clear
        accentBar.position = CGPoint(x: 0, y: cardSize.height / 2 - 10)
        container.addChild(accentBar)

        // Stacked coins visual - moved up
        let coinsVisual = createStackedCoins(count: index + 1, baseRadius: 12)
        coinsVisual.position = CGPoint(x: 0, y: 25)
        container.addChild(coinsVisual)

        // Badge in top-right corner (outside the coins area)
        if isBestValue || isPopular {
            let badgeText = isBestValue ? "BEST" : "HOT"
            let badgeColor = isBestValue ? gold : selectedBlue

            let badge = SKShapeNode(rectOf: CGSize(width: 36, height: 16), cornerRadius: 8)
            badge.fillColor = badgeColor
            badge.strokeColor = .clear
            badge.position = CGPoint(x: cardSize.width / 2 - 22, y: cardSize.height / 2 - 14)
            badge.zPosition = 10
            container.addChild(badge)

            let badgeLabel = SKLabelNode(fontNamed: uiFontBold)
            badgeLabel.text = badgeText
            badgeLabel.fontSize = fontSize(.caption2)
            badgeLabel.fontColor = .white
            badgeLabel.verticalAlignmentMode = .center
            badgeLabel.position = CGPoint(x: cardSize.width / 2 - 22, y: cardSize.height / 2 - 14)
            badgeLabel.zPosition = 11
            container.addChild(badgeLabel)
        }

        // Amount label
        let amountLabel = SKLabelNode(fontNamed: uiFontBold)
        amountLabel.text = "\(pack.coinAmount)"
        amountLabel.fontSize = fontSize(.title2)
        amountLabel.fontColor = goldDark
        amountLabel.position = CGPoint(x: 0, y: -12)
        amountLabel.verticalAlignmentMode = .center
        container.addChild(amountLabel)

        let coinsText = SKLabelNode(fontNamed: uiFont)
        coinsText.text = "coins"
        coinsText.fontSize = fontSize(.caption)
        coinsText.fontColor = secondaryTextColor
        coinsText.position = CGPoint(x: 0, y: -28)
        container.addChild(coinsText)

        // Price button
        let priceButton = SKShapeNode(rectOf: CGSize(width: 70, height: 28), cornerRadius: 14)
        priceButton.fillColor = purchaseGreen
        priceButton.strokeColor = purchaseGreenDark
        priceButton.lineWidth = 1
        priceButton.position = CGPoint(x: 0, y: -50)
        priceButton.name = "coinPack_\(pack.rawValue)"
        container.addChild(priceButton)

        let priceLabel = SKLabelNode(fontNamed: uiFontBold)
        priceLabel.text = StoreManager.shared.getLocalizedPrice(for: pack)
        priceLabel.fontSize = fontSize(.footnote)
        priceLabel.fontColor = .white
        priceLabel.position = CGPoint(x: 0, y: -50)
        priceLabel.verticalAlignmentMode = .center
        priceLabel.name = "coinPack_\(pack.rawValue)"
        container.addChild(priceLabel)

        return container
    }

    private func createStackedCoins(count: Int, baseRadius: CGFloat) -> SKNode {
        let container = SKNode()

        for i in 0..<min(count + 2, 5) {
            let yOffset = CGFloat(i) * 5
            let coin = SKShapeNode(circleOfRadius: baseRadius - CGFloat(i) * 0.5)
            coin.fillColor = gold
            coin.strokeColor = goldDark
            coin.lineWidth = 1.5
            coin.position = CGPoint(x: 0, y: yOffset)
            coin.zPosition = CGFloat(i)
            container.addChild(coin)

            if i == min(count + 1, 4) {
                let shine = SKShapeNode(circleOfRadius: (baseRadius - CGFloat(i) * 0.5) * 0.4)
                shine.fillColor = goldLight.withAlphaComponent(0.5)
                shine.strokeColor = .clear
                shine.position = CGPoint(x: -(baseRadius - CGFloat(i) * 0.5) * 0.3, y: yOffset + (baseRadius - CGFloat(i) * 0.5) * 0.3)
                shine.zPosition = CGFloat(i) + 0.5
                container.addChild(shine)
            }
        }

        return container
    }

    // MARK: - Hint Pack Section

    private func setupHintPackSection(at startY: CGFloat) -> CGFloat {
        var currentY = startY

        let headerContainer = createSectionHeader(
            title: isZenTheme ? "ヒントパック" : "Hint Packs",
            subtitle: isZenTheme ? "Hint Packs" : nil,
            icon: "💡",
            at: CGPoint(x: size.width / 2, y: currentY)
        )
        scrollContainer.addChild(headerContainer)
        currentY -= 35

        let packs = HintPack.allCases
        let cardWidth: CGFloat = 100
        let cardHeight: CGFloat = 115
        let spacing: CGFloat = 12
        let totalWidth = CGFloat(packs.count) * cardWidth + CGFloat(packs.count - 1) * spacing
        let startX = (size.width - totalWidth) / 2 + cardWidth / 2
        let cardY = currentY - cardHeight / 2

        for (index, pack) in packs.enumerated() {
            let x = startX + CGFloat(index) * (cardWidth + spacing)
            let card = createHintPackCard(pack: pack, at: CGPoint(x: x, y: cardY), size: CGSize(width: cardWidth, height: cardHeight), index: index)
            card.name = "hintPack_\(pack.rawValue)"
            scrollContainer.addChild(card)
            hintPackNodes.append(card)
        }

        return currentY - cardHeight - 10
    }

    private func createHintPackCard(pack: HintPack, at position: CGPoint, size cardSize: CGSize, index: Int) -> SKNode {
        let container = SKNode()
        container.position = position

        let canAfford = CoinManager.shared.balance >= pack.coinCost
        let hasSavings = pack.savingsText != nil

        // Shadow
        let shadow = SKShapeNode(rectOf: CGSize(width: cardSize.width - 4, height: cardSize.height - 4), cornerRadius: 10)
        shadow.fillColor = SKColor.black.withAlphaComponent(canAfford ? 0.10 : 0.05)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 2, y: -2)
        shadow.zPosition = -1
        container.addChild(shadow)

        // Card
        let card = SKShapeNode(rectOf: cardSize, cornerRadius: 10)
        card.fillColor = canAfford ? SKColor.white : SKColor.white.withAlphaComponent(0.7)
        card.strokeColor = canAfford ? purchaseGreen.withAlphaComponent(0.5) : secondaryTextColor.withAlphaComponent(0.3)
        card.lineWidth = 1.5
        card.name = "hintPack_\(pack.rawValue)"
        container.addChild(card)

        // Top accent
        let accent = SKShapeNode(rectOf: CGSize(width: cardSize.width - 16, height: 3), cornerRadius: 1.5)
        accent.fillColor = canAfford ? purchaseGreen : secondaryTextColor.withAlphaComponent(0.4)
        accent.strokeColor = .clear
        accent.position = CGPoint(x: 0, y: cardSize.height / 2 - 10)
        container.addChild(accent)

        // Lightbulb icon - centered and not covered by badge
        let bulbContainer = SKNode()
        bulbContainer.position = CGPoint(x: 0, y: 22)
        container.addChild(bulbContainer)

        if canAfford {
            let glow = SKShapeNode(circleOfRadius: 18)
            glow.fillColor = SKColor.yellow.withAlphaComponent(0.12)
            glow.strokeColor = .clear
            bulbContainer.addChild(glow)
        }

        let bulb = SKLabelNode(text: "💡")
        bulb.fontSize = scaledFontSize(30)
        bulb.alpha = canAfford ? 1.0 : 0.5
        bulbContainer.addChild(bulb)

        // Savings badge - top right corner
        if hasSavings {
            let badge = SKShapeNode(rectOf: CGSize(width: 50, height: 16), cornerRadius: 8)
            badge.fillColor = purchaseGreen
            badge.strokeColor = .clear
            badge.position = CGPoint(x: cardSize.width / 2 - 28, y: cardSize.height / 2 - 14)
            badge.zPosition = 10
            container.addChild(badge)

            let badgeLabel = SKLabelNode(fontNamed: uiFontBold)
            badgeLabel.text = pack.savingsText!
            badgeLabel.fontSize = fontSize(.caption2)
            badgeLabel.fontColor = .white
            badgeLabel.verticalAlignmentMode = .center
            badgeLabel.position = CGPoint(x: cardSize.width / 2 - 28, y: cardSize.height / 2 - 14)
            badgeLabel.zPosition = 11
            container.addChild(badgeLabel)
        }

        // Amount
        let amountLabel = SKLabelNode(fontNamed: uiFontBold)
        amountLabel.text = "\(pack.hintCount) Hints"
        amountLabel.fontSize = fontSize(.subheadline)
        amountLabel.fontColor = canAfford ? primaryTextColor : secondaryTextColor
        amountLabel.position = CGPoint(x: 0, y: -10)
        container.addChild(amountLabel)

        // Price with coin icon
        let priceContainer = SKNode()
        priceContainer.position = CGPoint(x: 0, y: -35)
        container.addChild(priceContainer)

        let priceBg = SKShapeNode(rectOf: CGSize(width: 60, height: 24), cornerRadius: 12)
        priceBg.fillColor = canAfford ? gold : secondaryTextColor.withAlphaComponent(0.3)
        priceBg.strokeColor = canAfford ? goldDark : .clear
        priceBg.lineWidth = 1
        priceBg.name = "hintPack_\(pack.rawValue)"
        priceContainer.addChild(priceBg)

        let miniCoin = SKShapeNode(circleOfRadius: 6)
        miniCoin.fillColor = canAfford ? goldLight : secondaryTextColor.withAlphaComponent(0.5)
        miniCoin.strokeColor = canAfford ? goldDark.withAlphaComponent(0.5) : .clear
        miniCoin.lineWidth = 1
        miniCoin.position = CGPoint(x: -18, y: 0)
        priceContainer.addChild(miniCoin)

        let priceLabel = SKLabelNode(fontNamed: uiFontBold)
        priceLabel.text = "\(pack.coinCost)"
        priceLabel.fontSize = fontSize(.caption)
        priceLabel.fontColor = canAfford ? .white : .white.withAlphaComponent(0.8)
        priceLabel.verticalAlignmentMode = .center
        priceLabel.position = CGPoint(x: 4, y: 0)
        priceLabel.name = "hintPack_\(pack.rawValue)"
        priceContainer.addChild(priceLabel)

        return container
    }

    // MARK: - Theme Section

    private func setupThemeSection(at startY: CGFloat) -> CGFloat {
        var currentY = startY

        let headerContainer = createSectionHeader(
            title: isZenTheme ? "テーマ" : "Board Themes",
            subtitle: isZenTheme ? "Board Themes" : nil,
            icon: "🎨",
            at: CGPoint(x: size.width / 2, y: currentY)
        )
        scrollContainer.addChild(headerContainer)
        currentY -= 35

        currentY = setupThemeGrid(startY: currentY)

        return currentY
    }

    private func setupThemeGrid(startY: CGFloat) -> CGFloat {
        let themes = BoardTheme.allThemes
        let cardWidth: CGFloat = 155
        let cardHeight: CGFloat = 90
        let horizontalSpacing: CGFloat = 12
        let verticalSpacing: CGFloat = 12
        let cardsPerRow = 2
        let totalRowWidth = CGFloat(cardsPerRow) * cardWidth + CGFloat(cardsPerRow - 1) * horizontalSpacing
        let startX = (size.width - totalRowWidth) / 2 + cardWidth / 2

        var lowestY = startY

        for (index, boardTheme) in themes.enumerated() {
            let row = index / cardsPerRow
            let col = index % cardsPerRow
            let x = startX + CGFloat(col) * (cardWidth + horizontalSpacing)
            let y = startY - cardHeight / 2 - CGFloat(row) * (cardHeight + verticalSpacing)

            let card = createThemeCard(theme: boardTheme, at: CGPoint(x: x, y: y), size: CGSize(width: cardWidth, height: cardHeight))
            card.name = "theme_\(boardTheme.id)"
            scrollContainer.addChild(card)
            themeNodes.append(card)

            lowestY = min(lowestY, y - cardHeight / 2)
        }

        return lowestY
    }

    private func createThemeCard(theme boardTheme: BoardTheme, at position: CGPoint, size cardSize: CGSize) -> SKNode {
        let container = SKNode()
        container.position = position

        let isUnlocked = ThemeManager.shared.isUnlocked(boardTheme)
        let isSelected = ThemeManager.shared.currentTheme.id == boardTheme.id
        let canAfford = CoinManager.shared.balance >= boardTheme.price

        // Shadow
        let shadow = SKShapeNode(rectOf: CGSize(width: cardSize.width - 4, height: cardSize.height - 4), cornerRadius: 8)
        shadow.fillColor = SKColor.black.withAlphaComponent(isSelected ? 0.15 : 0.08)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 2, y: -2)
        shadow.zPosition = -1
        container.addChild(shadow)

        // Card
        let card = SKShapeNode(rectOf: cardSize, cornerRadius: 8)
        card.fillColor = boardTheme.innerBoardColor.skColor
        if isSelected {
            card.strokeColor = selectedBlue
            card.lineWidth = 2.5
        } else if !isUnlocked && !canAfford {
            card.strokeColor = secondaryTextColor.withAlphaComponent(0.3)
            card.lineWidth = 1
        } else {
            card.strokeColor = accentColor.withAlphaComponent(0.4)
            card.lineWidth = 1
        }
        card.name = "theme_\(boardTheme.id)"
        container.addChild(card)

        // Mini board preview
        let gridPreview = SKNode()
        gridPreview.position = CGPoint(x: -cardSize.width / 2 + 28, y: 10)
        container.addChild(gridPreview)

        for i in 0..<3 {
            for j in 0..<3 {
                let dot = SKShapeNode(circleOfRadius: 1.2)
                dot.fillColor = boardTheme.gridLineColor.skColor.withAlphaComponent(0.7)
                dot.strokeColor = .clear
                dot.position = CGPoint(x: CGFloat(i) * 8, y: CGFloat(j) * 8)
                gridPreview.addChild(dot)
            }
        }

        // Stone previews
        let blackStone = SKShapeNode(circleOfRadius: 9)
        blackStone.fillColor = boardTheme.blackStoneColor.skColor
        blackStone.strokeColor = boardTheme.blackStoneHighlight.skColor.withAlphaComponent(0.5)
        blackStone.lineWidth = 1
        blackStone.position = CGPoint(x: 25, y: 14)
        container.addChild(blackStone)

        let whiteStone = SKShapeNode(circleOfRadius: 9)
        whiteStone.fillColor = boardTheme.whiteStoneColor.skColor
        whiteStone.strokeColor = boardTheme.whiteStoneHighlight.skColor.withAlphaComponent(0.5)
        whiteStone.lineWidth = 1
        whiteStone.position = CGPoint(x: 46, y: 14)
        container.addChild(whiteStone)

        // Theme name
        let textColor = getContrastingTextColor(for: boardTheme.innerBoardColor.skColor)
        let nameLabel = SKLabelNode(fontNamed: uiFontBold)
        nameLabel.text = boardTheme.name
        nameLabel.fontSize = fontSize(.footnote)
        nameLabel.fontColor = textColor
        nameLabel.position = CGPoint(x: 0, y: -20)
        container.addChild(nameLabel)

        // Status indicator
        if isUnlocked {
            if isSelected {
                let badge = SKShapeNode(rectOf: CGSize(width: 55, height: 18), cornerRadius: 9)
                badge.fillColor = selectedBlue
                badge.strokeColor = .clear
                badge.position = CGPoint(x: 0, y: -38)
                container.addChild(badge)

                let checkLabel = SKLabelNode(fontNamed: uiFont)
                checkLabel.text = isZenTheme ? "✓ 選択中" : "✓ Active"
                checkLabel.fontSize = fontSize(.caption)
                checkLabel.fontColor = .white
                checkLabel.verticalAlignmentMode = .center
                checkLabel.position = CGPoint(x: 0, y: -38)
                container.addChild(checkLabel)
            }
        } else {
            let priceTag = SKShapeNode(rectOf: CGSize(width: 50, height: 18), cornerRadius: 9)
            priceTag.fillColor = canAfford ? gold : secondaryTextColor.withAlphaComponent(0.5)
            priceTag.strokeColor = canAfford ? goldDark : .clear
            priceTag.lineWidth = 1
            priceTag.position = CGPoint(x: 0, y: -38)
            priceTag.name = "theme_\(boardTheme.id)"
            container.addChild(priceTag)

            if canAfford {
                let miniCoin = SKShapeNode(circleOfRadius: 5)
                miniCoin.fillColor = goldLight
                miniCoin.strokeColor = .clear
                miniCoin.position = CGPoint(x: -14, y: -38)
                container.addChild(miniCoin)
            }

            let priceLabel = SKLabelNode(fontNamed: uiFontBold)
            priceLabel.text = "\(boardTheme.price)"
            priceLabel.fontSize = fontSize(.caption)
            priceLabel.fontColor = canAfford ? .white : .white.withAlphaComponent(0.8)
            priceLabel.verticalAlignmentMode = .center
            priceLabel.position = CGPoint(x: canAfford ? 4 : 0, y: -38)
            priceLabel.name = "theme_\(boardTheme.id)"
            container.addChild(priceLabel)

            if !canAfford {
                let lockOverlay = SKShapeNode(rectOf: cardSize, cornerRadius: 8)
                lockOverlay.fillColor = SKColor.black.withAlphaComponent(0.12)
                lockOverlay.strokeColor = .clear
                lockOverlay.zPosition = 5
                container.addChild(lockOverlay)
            }
        }

        return container
    }

    private func getContrastingTextColor(for color: SKColor) -> SKColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        let brightness = (r * 299 + g * 587 + b * 114) / 1000
        return brightness > 0.5 ? primaryTextColor : theme.backgroundGradient.topColor.skColor
    }

    // MARK: - Legal Section

    private func setupLegalSection(at startY: CGFloat) -> CGFloat {
        var currentY = startY

        // Divider line
        let divider = SKShapeNode(rectOf: CGSize(width: size.width - 80, height: 1))
        divider.fillColor = secondaryTextColor.withAlphaComponent(0.2)
        divider.strokeColor = .clear
        divider.position = CGPoint(x: size.width / 2, y: currentY)
        scrollContainer.addChild(divider)
        currentY -= 25

        // Legal links container
        let linksContainer = SKNode()
        linksContainer.position = CGPoint(x: size.width / 2, y: currentY)
        scrollContainer.addChild(linksContainer)

        // Privacy Policy link
        let privacyLabel = SKLabelNode(fontNamed: uiFont)
        privacyLabel.text = isZenTheme ? "プライバシーポリシー" : "Privacy Policy"
        privacyLabel.fontSize = fontSize(.subheadline)
        privacyLabel.fontColor = secondaryTextColor
        privacyLabel.name = "privacyPolicy"
        privacyLabel.position = CGPoint(x: -60, y: 0)
        linksContainer.addChild(privacyLabel)

        // Separator dot
        let dot = SKLabelNode(fontNamed: uiFont)
        dot.text = "•"
        dot.fontSize = fontSize(.subheadline)
        dot.fontColor = secondaryTextColor.withAlphaComponent(0.5)
        dot.position = CGPoint(x: 0, y: 0)
        linksContainer.addChild(dot)

        // Terms of Service link
        let termsLabel = SKLabelNode(fontNamed: uiFont)
        termsLabel.text = isZenTheme ? "利用規約" : "Terms of Service"
        termsLabel.fontSize = fontSize(.subheadline)
        termsLabel.fontColor = secondaryTextColor
        termsLabel.name = "termsOfService"
        termsLabel.position = CGPoint(x: 60, y: 0)
        linksContainer.addChild(termsLabel)

        currentY -= 30

        return currentY
    }

    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Display Updates

    @objc private func updateCoinDisplay() {
        coinLabel.text = "\(CoinManager.shared.balance)"

        let scaleUp = SKAction.scale(to: 1.2, duration: 0.15)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.15)
        scaleUp.timingMode = .easeOut
        scaleDown.timingMode = .easeOut
        coinDisplayContainer.run(SKAction.sequence([scaleUp, scaleDown]))

        createSparkle(at: coinDisplayContainer.position, color: gold, count: 5)

        refreshHintPackCards()
        refreshThemeCards()
    }

    @objc private func updateHintDisplay() {
        hintLabel.text = "\(HintManager.shared.balance)"

        let scaleUp = SKAction.scale(to: 1.2, duration: 0.15)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.15)
        scaleUp.timingMode = .easeOut
        hintDisplayContainer.run(SKAction.sequence([scaleUp, scaleDown]))

        createSparkle(at: hintDisplayContainer.position, color: purchaseGreen, count: 3)
    }

    // MARK: - Touch Handling & Scrolling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        lastTouchY = location.y
        scrollVelocity = 0
        isScrolling = false
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        let deltaY = location.y - lastTouchY

        if abs(deltaY) > 8 {
            isScrolling = true
        }

        if isScrolling {
            scrollVelocity = deltaY
            scrollContent(by: deltaY)
        }

        lastTouchY = location.y
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        if !isScrolling {
            handleTap(at: location)
        } else {
            applyScrollMomentum()
        }

        isScrolling = false
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isScrolling = false
    }

    private func scrollContent(by deltaY: CGFloat) {
        let newY = scrollContainer.position.y + deltaY

        // Calculate bounds
        let minY: CGFloat = 0
        let maxY = max(0, scrollContentHeight - (size.height - topInset - headerHeight - 100))

        // Apply with rubber banding at edges
        if newY < minY {
            scrollContainer.position.y = minY + (newY - minY) * 0.3
        } else if newY > maxY {
            scrollContainer.position.y = maxY + (newY - maxY) * 0.3
        } else {
            scrollContainer.position.y = newY
        }
    }

    private func applyScrollMomentum() {
        let minY: CGFloat = 0
        let maxY = max(0, scrollContentHeight - (size.height - topInset - headerHeight - 100))

        // Bounce back if out of bounds
        if scrollContainer.position.y < minY {
            let bounce = SKAction.moveTo(y: minY, duration: 0.3)
            bounce.timingMode = .easeOut
            scrollContainer.run(bounce)
        } else if scrollContainer.position.y > maxY {
            let bounce = SKAction.moveTo(y: maxY, duration: 0.3)
            bounce.timingMode = .easeOut
            scrollContainer.run(bounce)
        } else if abs(scrollVelocity) > 5 {
            // Apply momentum
            let targetY = scrollContainer.position.y + scrollVelocity * 8
            let clampedY = max(minY, min(maxY, targetY))
            let momentum = SKAction.moveTo(y: clampedY, duration: 0.4)
            momentum.timingMode = .easeOut
            scrollContainer.run(momentum)
        }
    }

    private func handleTap(at location: CGPoint) {
        let nodes = self.nodes(at: location)

        for node in nodes {
            guard let name = node.name else { continue }

            if name == "backButton" {
                SoundManager.shared.buttonTapped()
                goBackToMenu()
                return
            }

            if name.hasPrefix("coinPack_") {
                let packId = String(name.dropFirst("coinPack_".count))
                if let pack = CoinPack.allCases.first(where: { $0.rawValue == packId }) {
                    SoundManager.shared.buttonTapped()
                    purchaseCoinPack(pack)
                    return
                }
            }

            if name.hasPrefix("hintPack_") {
                let packId = String(name.dropFirst("hintPack_".count))
                if let pack = HintPack.allCases.first(where: { $0.rawValue == packId }) {
                    SoundManager.shared.buttonTapped()
                    handleHintPackTap(pack)
                    return
                }
            }

            if name.hasPrefix("theme_") {
                let themeId = String(name.dropFirst("theme_".count))
                if let boardTheme = BoardTheme.allThemes.first(where: { $0.id == themeId }) {
                    SoundManager.shared.buttonTapped()
                    handleThemeTap(boardTheme)
                    return
                }
            }

            if name == "privacyPolicy" {
                SoundManager.shared.buttonTapped()
                openURL("https://brevinb.github.io/go-moku-legal/privacy-policy.html")
                return
            }

            if name == "termsOfService" {
                SoundManager.shared.buttonTapped()
                openURL("https://brevinb.github.io/go-moku-legal/terms-of-service.html")
                return
            }
        }
    }

    // MARK: - Purchases

    private func purchaseCoinPack(_ pack: CoinPack) {
        guard !isLoading else { return }
        isLoading = true
        showLoadingOverlay()

        Task { @MainActor in
            do {
                let success = try await StoreManager.shared.purchase(pack)
                hideLoadingOverlay()
                isLoading = false

                if success {
                    showCoinPurchaseSuccess(amount: pack.coinAmount)
                }
            } catch {
                hideLoadingOverlay()
                isLoading = false
                showError(error.localizedDescription)
            }
        }
    }

    private func handleHintPackTap(_ pack: HintPack) {
        if CoinManager.shared.balance >= pack.coinCost {
            showHintPurchaseConfirmation(for: pack)
        } else {
            showInsufficientCoins(needed: pack.coinCost, for: "hint pack")
        }
    }

    private func handleThemeTap(_ boardTheme: BoardTheme) {
        if ThemeManager.shared.isUnlocked(boardTheme) {
            if ThemeManager.shared.currentTheme.id != boardTheme.id {
                ThemeManager.shared.applyTheme(boardTheme)
                // Reload entire scene to apply new theme colors everywhere
                reloadSceneWithNewTheme(showingToast: "\(boardTheme.name) Applied!")
            }
        } else if ThemeManager.shared.canAfford(boardTheme) {
            showThemePurchaseConfirmation(for: boardTheme)
        } else {
            showInsufficientCoins(needed: boardTheme.price, for: "theme")
        }
    }

    // MARK: - Confirmation Dialogs

    private func showHintPurchaseConfirmation(for pack: HintPack) {
        guard let vc = view?.window?.rootViewController else { return }

        let title = isZenTheme ? "\(pack.displayName)を購入" : "Purchase \(pack.displayName)"
        let message = isZenTheme
            ? "このパックは\(pack.coinCost)コインです。"
            : "This pack costs \(pack.coinCost) coins."

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: isZenTheme ? "キャンセル" : "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: isZenTheme ? "購入" : "Purchase", style: .default) { [weak self] _ in
            if HintManager.shared.purchaseHintPack(pack) {
                self?.showHintPurchaseSuccess(amount: pack.hintCount)
            }
        })
        vc.present(alert, animated: true)
    }

    private func showThemePurchaseConfirmation(for boardTheme: BoardTheme) {
        guard let vc = view?.window?.rootViewController else { return }

        let title = isZenTheme ? "\(boardTheme.name)を購入" : "Purchase \(boardTheme.name)"
        let message = isZenTheme
            ? "このテーマは\(boardTheme.price)コインです。"
            : "This theme costs \(boardTheme.price) coins."

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: isZenTheme ? "キャンセル" : "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: isZenTheme ? "購入" : "Purchase", style: .default) { [weak self] _ in
            if ThemeManager.shared.purchaseTheme(boardTheme) {
                ThemeManager.shared.applyTheme(boardTheme)
                // Reload entire scene to apply new theme colors everywhere
                self?.reloadSceneWithNewTheme(showingToast: "\(boardTheme.name) Unlocked!", celebration: true)
            }
        })
        vc.present(alert, animated: true)
    }

    private func showInsufficientCoins(needed: Int, for item: String) {
        guard let vc = view?.window?.rootViewController else { return }

        let deficit = needed - CoinManager.shared.balance
        let title = isZenTheme ? "コイン不足" : "Insufficient Coins"
        let message = isZenTheme
            ? "あと\(deficit)コイン必要です。"
            : "You need \(deficit) more coins for this \(item)."

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        vc.present(alert, animated: true)
    }

    // MARK: - Success Animations

    private func showCoinPurchaseSuccess(amount: Int) {
        let startPos = CGPoint(x: size.width / 2, y: size.height / 2)
        let endPos = coinDisplayContainer.position

        for i in 0..<min(amount / 10, 15) {
            let coin = createAnimatedCoinIcon(radius: 12)
            coin.position = startPos
            coin.alpha = 0
            coin.zPosition = 300
            particleLayer.addChild(coin)

            let delay = Double(i) * 0.05
            let randomOffset = CGPoint(x: CGFloat.random(in: -30...30), y: CGFloat.random(in: -30...30))
            let midPoint = CGPoint(x: (startPos.x + endPos.x) / 2 + randomOffset.x, y: startPos.y + 50 + randomOffset.y)

            let path = CGMutablePath()
            path.move(to: startPos)
            path.addQuadCurve(to: endPos, control: midPoint)

            let followPath = SKAction.follow(path, asOffset: false, orientToPath: false, duration: 0.6)
            followPath.timingMode = .easeIn
            let fadeIn = SKAction.fadeIn(withDuration: 0.1)
            let fadeOut = SKAction.fadeOut(withDuration: 0.1)
            let scale = SKAction.scale(to: 0.5, duration: 0.6)
            let remove = SKAction.removeFromParent()

            coin.run(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                fadeIn,
                SKAction.group([followPath, scale]),
                fadeOut,
                remove
            ]))
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.createCelebrationBurst(at: self?.coinDisplayContainer.position ?? .zero, color: self?.gold ?? .yellow)
            self?.showSuccessToast(text: "+\(amount) Coins!", color: self?.purchaseGreen ?? .green)
        }
    }

    private func showHintPurchaseSuccess(amount: Int) {
        createCelebrationBurst(at: hintDisplayContainer.position, color: purchaseGreen)
        showSuccessToast(text: "+\(amount) Hints!", color: purchaseGreen)
    }

    private func showThemeApplied(_ name: String) {
        showSuccessToast(text: "\(name) Applied!", color: selectedBlue)
    }

    private func showThemeUnlockCelebration(_ name: String) {
        for _ in 0..<30 {
            let confetti = SKShapeNode(rectOf: CGSize(width: 8, height: 4), cornerRadius: 2)
            confetti.fillColor = [gold, purchaseGreen, selectedBlue, premiumPurple].randomElement()!
            confetti.strokeColor = .clear
            confetti.position = CGPoint(x: size.width / 2, y: size.height / 2)
            confetti.zPosition = 400
            confetti.zRotation = CGFloat.random(in: 0...(.pi * 2))
            particleLayer.addChild(confetti)

            let endX = CGFloat.random(in: 0...size.width)
            let endY = CGFloat.random(in: -50...size.height * 0.3)
            let duration = Double.random(in: 1.0...2.0)

            let move = SKAction.move(to: CGPoint(x: endX, y: endY), duration: duration)
            move.timingMode = .easeOut
            let rotate = SKAction.rotate(byAngle: CGFloat.random(in: -10...10), duration: duration)
            let fadeOut = SKAction.fadeOut(withDuration: duration * 0.3)
            let remove = SKAction.removeFromParent()

            confetti.run(SKAction.sequence([
                SKAction.group([move, rotate, SKAction.sequence([SKAction.wait(forDuration: duration * 0.7), fadeOut])]),
                remove
            ]))
        }

        showSuccessToast(text: "\(name) Unlocked!", color: premiumPurple)
    }

    private func createCelebrationBurst(at position: CGPoint, color: SKColor) {
        for _ in 0..<12 {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 3...6))
            particle.fillColor = color
            particle.strokeColor = SKColor.white.withAlphaComponent(0.5)
            particle.lineWidth = 1
            particle.position = position
            particle.zPosition = 250
            particleLayer.addChild(particle)

            let angle = CGFloat.random(in: 0...(.pi * 2))
            let distance = CGFloat.random(in: 40...80)
            let endPoint = CGPoint(x: position.x + cos(angle) * distance, y: position.y + sin(angle) * distance)

            let move = SKAction.move(to: endPoint, duration: 0.4)
            move.timingMode = .easeOut
            let fadeOut = SKAction.fadeOut(withDuration: 0.3)
            let scale = SKAction.scale(to: 0.2, duration: 0.4)
            let remove = SKAction.removeFromParent()

            particle.run(SKAction.sequence([
                SKAction.group([move, scale, SKAction.sequence([SKAction.wait(forDuration: 0.2), fadeOut])]),
                remove
            ]))
        }
    }

    private func showSuccessToast(text: String, color: SKColor) {
        let toast = SKNode()
        toast.position = CGPoint(x: size.width / 2, y: size.height / 2 + 50)
        toast.zPosition = 600
        toast.alpha = 0
        toast.setScale(0.7)
        addChild(toast)

        let bg = SKShapeNode(rectOf: CGSize(width: 200, height: 55), cornerRadius: 27)
        bg.fillColor = color
        bg.strokeColor = SKColor.white.withAlphaComponent(0.3)
        bg.lineWidth = 2
        toast.addChild(bg)

        let glow = SKShapeNode(rectOf: CGSize(width: 190, height: 45), cornerRadius: 22)
        glow.fillColor = SKColor.white.withAlphaComponent(0.15)
        glow.strokeColor = .clear
        toast.addChild(glow)

        let label = SKLabelNode(fontNamed: uiFontBold)
        label.text = text
        label.fontSize = fontSize(.headline)
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        toast.addChild(label)

        let fadeIn = SKAction.fadeIn(withDuration: 0.2)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.2)
        scaleUp.timingMode = .easeOut
        let wait = SKAction.wait(forDuration: 1.5)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let moveUp = SKAction.moveBy(x: 0, y: 30, duration: 0.3)
        let remove = SKAction.removeFromParent()

        toast.run(SKAction.sequence([
            SKAction.group([fadeIn, scaleUp]),
            wait,
            SKAction.group([fadeOut, moveUp]),
            remove
        ]))
    }

    // MARK: - Loading Overlay

    private func showLoadingOverlay() {
        let overlay = SKNode()
        overlay.zPosition = 800
        addChild(overlay)
        loadingOverlay = overlay

        let bg = SKShapeNode(rect: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        bg.fillColor = SKColor.black.withAlphaComponent(0.4)
        bg.strokeColor = .clear
        overlay.addChild(bg)

        let card = SKShapeNode(rectOf: CGSize(width: 140, height: 100), cornerRadius: 16)
        card.fillColor = SKColor.white.withAlphaComponent(0.98)
        card.strokeColor = accentColor.withAlphaComponent(0.3)
        card.lineWidth = 1
        card.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.addChild(card)

        let spinnerContainer = SKNode()
        spinnerContainer.position = CGPoint(x: size.width / 2, y: size.height / 2 + 10)
        overlay.addChild(spinnerContainer)

        for i in 0..<3 {
            let coin = SKShapeNode(circleOfRadius: 8)
            coin.fillColor = gold
            coin.strokeColor = goldDark
            coin.lineWidth = 1
            let angle = CGFloat(i) * (.pi * 2 / 3)
            coin.position = CGPoint(x: cos(angle) * 20, y: sin(angle) * 20)
            spinnerContainer.addChild(coin)
        }

        let rotate = SKAction.rotate(byAngle: .pi * 2, duration: 1.2)
        spinnerContainer.run(SKAction.repeatForever(rotate))

        let label = SKLabelNode(fontNamed: uiFont)
        label.text = isZenTheme ? "処理中..." : "Processing..."
        label.fontSize = fontSize(.subheadline)
        label.fontColor = primaryTextColor
        label.position = CGPoint(x: size.width / 2, y: size.height / 2 - 30)
        overlay.addChild(label)
    }

    private func hideLoadingOverlay() {
        loadingOverlay?.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.2),
            SKAction.removeFromParent()
        ]))
        loadingOverlay = nil
    }

    private func showError(_ message: String) {
        guard let vc = view?.window?.rootViewController else { return }
        let alert = UIAlertController(title: isZenTheme ? "エラー" : "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        vc.present(alert, animated: true)
    }

    // MARK: - Refresh Cards

    private func refreshHintPackCards() {
        for node in hintPackNodes {
            node.removeFromParent()
        }
        hintPackNodes.removeAll()

        // Recalculate position based on current scroll content
        let visibleTop = size.height - topInset - headerHeight - 20
        let coinPackHeight: CGFloat = 165 // header + cards
        let sectionY = visibleTop - coinPackHeight - sectionSpacing - 35

        let packs = HintPack.allCases
        let cardWidth: CGFloat = 100
        let cardHeight: CGFloat = 115
        let spacing: CGFloat = 12
        let totalWidth = CGFloat(packs.count) * cardWidth + CGFloat(packs.count - 1) * spacing
        let startX = (size.width - totalWidth) / 2 + cardWidth / 2
        let cardY = sectionY - cardHeight / 2

        for (index, pack) in packs.enumerated() {
            let x = startX + CGFloat(index) * (cardWidth + spacing)
            let card = createHintPackCard(pack: pack, at: CGPoint(x: x, y: cardY), size: CGSize(width: cardWidth, height: cardHeight), index: index)
            card.name = "hintPack_\(pack.rawValue)"
            scrollContainer.addChild(card)
            hintPackNodes.append(card)
        }
    }

    private func refreshThemeCards() {
        for node in themeNodes {
            node.removeFromParent()
        }
        themeNodes.removeAll()

        let visibleTop = size.height - topInset - headerHeight - 20
        let coinPackHeight: CGFloat = 165
        let hintPackHeight: CGFloat = 150
        let sectionY = visibleTop - coinPackHeight - sectionSpacing - hintPackHeight - sectionSpacing - 35

        _ = setupThemeGrid(startY: sectionY)
    }

    // MARK: - Navigation

    private func goBackToMenu() {
        let transition = SKTransition.fade(withDuration: 0.4)
        let menuScene = MenuScene(size: size)
        menuScene.scaleMode = .aspectFill
        view?.presentScene(menuScene, transition: transition)
    }

    private func reloadSceneWithNewTheme(showingToast text: String, celebration: Bool = false) {
        // Create a new shop scene with the new theme applied
        let newShopScene = ShopScene(size: size)
        newShopScene.scaleMode = .aspectFill

        // Quick crossfade transition
        let transition = SKTransition.crossFade(withDuration: 0.3)
        view?.presentScene(newShopScene, transition: transition)

        // Show toast and celebration after transition
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            if celebration {
                newShopScene.showThemeUnlockCelebration(text.replacingOccurrences(of: " Unlocked!", with: ""))
            } else {
                newShopScene.showSuccessToast(text: text, color: newShopScene.selectedBlue)
            }
        }
    }
}
