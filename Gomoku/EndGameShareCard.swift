//
//  EndGameShareCard.swift
//  Gomoku
//
//  Renders a polished image of a finished game for sharing.
//

import UIKit

enum EndGameShareCard {

    /// App Store listing URL.
    static let appStoreURL = URL(string: "https://apps.apple.com/us/app/go-moku/id6755370673")!

    static func render(
        board: GomokuBoard,
        gameMode: GameMode,
        aiDifficulty: AIDifficulty,
        humanPlayer: Player,
        isPracticeMode: Bool,
        winner: Player?
    ) -> UIImage {
        let theme = ThemeManager.shared.currentTheme
        let size = CGSize(width: 1080, height: 1080)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { ctx in
            let cgctx = ctx.cgContext

            drawBackgroundGradient(in: CGRect(origin: .zero, size: size), theme: theme, context: cgctx)

            // Title
            let titleFont = UIFont(name: "AvenirNext-DemiBold", size: 64) ?? .boldSystemFont(ofSize: 64)
            drawCentered(
                text: "Gomoku",
                font: titleFont,
                color: theme.statusTextColor.skColor,
                y: 60,
                width: size.width
            )

            // Result line
            let resultText = makeResultText(
                gameMode: gameMode,
                aiDifficulty: aiDifficulty,
                humanPlayer: humanPlayer,
                isPracticeMode: isPracticeMode,
                winner: winner,
                moveCount: board.getMoveHistory().count
            )
            let resultFont = UIFont(name: "AvenirNext-Medium", size: 38) ?? .systemFont(ofSize: 38)
            drawCentered(
                text: resultText,
                font: resultFont,
                color: theme.statusTextColor.skColor.withAlphaComponent(0.85),
                y: 150,
                width: size.width
            )

            // Board
            let boardMargin: CGFloat = 90
            let boardTop: CGFloat = 240
            let boardWidth: CGFloat = size.width - boardMargin * 2
            let boardRect = CGRect(x: boardMargin, y: boardTop, width: boardWidth, height: boardWidth)
            drawBoard(in: boardRect, board: board, theme: theme, context: cgctx)

            // Footer
            let footerFont = UIFont(name: "AvenirNext-Medium", size: 30) ?? .systemFont(ofSize: 30)
            drawCentered(
                text: "Play 5-in-a-row · Free on the App Store",
                font: footerFont,
                color: theme.statusTextColor.skColor.withAlphaComponent(0.7),
                y: boardTop + boardWidth + 60,
                width: size.width
            )
        }
    }

    static func captionText(winner: Player?, gameMode: GameMode, humanPlayer: Player) -> String {
        let url = appStoreURL.absoluteString
        guard let w = winner else {
            return "A drawn Gomoku match. \(url)"
        }
        if gameMode == .vsAI {
            return w == humanPlayer
                ? "Just won a game of Gomoku! \(url)"
                : "Tough loss in Gomoku — coming back for revenge. \(url)"
        }
        let color = (w == .black) ? "Black" : "White"
        return "\(color) wins this Gomoku match. \(url)"
    }

    // MARK: - Drawing helpers

    private static func drawCentered(text: String, font: UIFont, color: UIColor, y: CGFloat, width: CGFloat) {
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let textSize = (text as NSString).size(withAttributes: attrs)
        (text as NSString).draw(at: CGPoint(x: (width - textSize.width) / 2, y: y), withAttributes: attrs)
    }

    private static func drawBackgroundGradient(in rect: CGRect, theme: BoardTheme, context: CGContext) {
        let colors = [
            theme.backgroundGradient.topColor.skColor.cgColor,
            theme.backgroundGradient.midColor.skColor.cgColor,
            theme.backgroundGradient.bottomColor.skColor.cgColor
        ]
        let space = CGColorSpaceCreateDeviceRGB()
        guard let gradient = CGGradient(colorsSpace: space, colors: colors as CFArray, locations: [0, 0.5, 1]) else {
            theme.innerBoardColor.skColor.setFill()
            UIRectFill(rect)
            return
        }
        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: rect.midX, y: rect.minY),
            end: CGPoint(x: rect.midX, y: rect.maxY),
            options: []
        )
    }

    private static func drawBoard(in rect: CGRect, board: GomokuBoard, theme: BoardTheme, context: CGContext) {
        // Panel
        let panelPath = UIBezierPath(roundedRect: rect, cornerRadius: 24)
        theme.innerBoardColor.skColor.setFill()
        panelPath.fill()
        theme.boardStrokeColor.skColor.setStroke()
        panelPath.lineWidth = 3
        panelPath.stroke()

        // Grid
        let n = board.size
        let innerPadding: CGFloat = 50
        let gridRect = rect.insetBy(dx: innerPadding, dy: innerPadding)
        let cellSize = gridRect.width / CGFloat(n - 1)

        context.setLineWidth(1.2)
        context.setStrokeColor(theme.gridLineColor.skColor.cgColor)
        for i in 0..<n {
            let x = gridRect.minX + CGFloat(i) * cellSize
            context.move(to: CGPoint(x: x, y: gridRect.minY))
            context.addLine(to: CGPoint(x: x, y: gridRect.maxY))
            let y = gridRect.minY + CGFloat(i) * cellSize
            context.move(to: CGPoint(x: gridRect.minX, y: y))
            context.addLine(to: CGPoint(x: gridRect.maxX, y: y))
        }
        context.strokePath()

        // Hoshi (star points) on a 15x15
        if n == 15 {
            context.setFillColor(theme.starPointColor.skColor.cgColor)
            for r in [3, 7, 11] {
                for c in [3, 7, 11] {
                    let x = gridRect.minX + CGFloat(c) * cellSize
                    let y = gridRect.minY + CGFloat(r) * cellSize
                    context.fillEllipse(in: CGRect(x: x - 5, y: y - 5, width: 10, height: 10))
                }
            }
        }

        // Stones
        let stoneRadius = cellSize * 0.42
        for r in 0..<n {
            for c in 0..<n {
                let player = board.getPlayer(at: r, col: c)
                guard player != .none else { continue }
                let x = gridRect.minX + CGFloat(c) * cellSize
                let y = gridRect.minY + CGFloat(r) * cellSize
                let stoneRect = CGRect(x: x - stoneRadius, y: y - stoneRadius, width: stoneRadius * 2, height: stoneRadius * 2)
                let fillColor = (player == .black) ? theme.blackStoneColor.skColor : theme.whiteStoneColor.skColor
                context.setFillColor(fillColor.cgColor)
                context.fillEllipse(in: stoneRect)
                context.setStrokeColor(UIColor.black.withAlphaComponent(0.35).cgColor)
                context.setLineWidth(1.5)
                context.strokeEllipse(in: stoneRect)
            }
        }
    }

    // MARK: - Result text

    private static func makeResultText(
        gameMode: GameMode,
        aiDifficulty: AIDifficulty,
        humanPlayer: Player,
        isPracticeMode: Bool,
        winner: Player?,
        moveCount: Int
    ) -> String {
        let movesSuffix = " · \(moveCount) moves"

        guard let winner = winner else {
            return "Draw" + movesSuffix
        }

        switch gameMode {
        case .vsAI:
            let difficultyName: String
            switch aiDifficulty {
            case .easy: difficultyName = "Easy"
            case .medium: difficultyName = "Medium"
            case .hard: difficultyName = "Hard"
            }
            if isPracticeMode {
                return "Practice vs \(difficultyName) AI" + movesSuffix
            }
            return winner == humanPlayer
                ? "Won vs \(difficultyName) AI" + movesSuffix
                : "Lost vs \(difficultyName) AI" + movesSuffix
        case .twoPlayer:
            let color = (winner == .black) ? "Black" : "White"
            return "\(color) wins" + movesSuffix
        }
    }
}
