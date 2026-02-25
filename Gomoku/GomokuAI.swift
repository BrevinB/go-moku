//
//  GomokuAI.swift
//  Gomoku
//
//  Created by Brevin Blalock on 10/13/25.
//

import Foundation
import GameplayKit

enum AIDifficulty: String, Codable {
    case easy
    case medium
    case hard
}

class GomokuAI {
    private let difficulty: AIDifficulty
    private let randomSource: GKRandomSource
    private let strategist: GKStrategist
    private let candidateLimit: Int
    private let suboptimalChance: Int      // Percentage chance to pick suboptimal move
    private let blockOpenFourChance: Int   // Percentage chance to block open 4
    private let seeOpenThreeChance: Int    // Percentage chance to detect open 3 threats

    init(difficulty: AIDifficulty) {
        self.difficulty = difficulty
        self.randomSource = GKMersenneTwisterRandomSource()

        switch difficulty {
        case .easy:
            // Monte Carlo strategist for weaker, more varied play
            let mc = GKMonteCarloStrategist()
            mc.budget = 50
            mc.explorationParameter = 10
            mc.randomSource = GKMersenneTwisterRandomSource()
            self.strategist = mc
            self.candidateLimit = 10
            self.suboptimalChance = 40
            self.blockOpenFourChance = 70
            self.seeOpenThreeChance = 0

        case .medium:
            // Minimax with moderate look-ahead
            let mm = GKMinmaxStrategist()
            mm.maxLookAheadDepth = 2
            mm.randomSource = GKMersenneTwisterRandomSource()
            self.strategist = mm
            self.candidateLimit = 15
            self.suboptimalChance = 10
            self.blockOpenFourChance = 100
            self.seeOpenThreeChance = 80

        case .hard:
            // Deep minimax — deterministic best play
            let mm = GKMinmaxStrategist()
            mm.maxLookAheadDepth = 4
            self.strategist = mm
            self.candidateLimit = 20
            self.suboptimalChance = 0
            self.blockOpenFourChance = 100
            self.seeOpenThreeChance = 100
        }
    }

    func findBestMove(board: GomokuBoard, player: Player) -> (row: Int, col: Int)? {
        // Only hard mode uses opening book, and only for first 2 moves
        if difficulty == .hard {
            let moveCount = board.getMoveHistory().count
            if moveCount < 2 {
                if let bookMove = OpeningBook.shared.getBookMove(board: board, player: player) {
                    return bookMove
                }
            }
        }

        // Build the GameplayKit game model for this position
        let gameModel = GomokuGameModel(board: board)
        gameModel.candidateLimit = candidateLimit

        // First move — place in or near center with randomisation for variety
        if board.getMoveHistory().isEmpty {
            return firstMove(board: board)
        }

        // CRITICAL: Check for immediate win (all difficulties always take the win)
        if let winMove = findWinningMove(board: board, player: player) {
            return winMove
        }

        // CRITICAL: Block opponent's winning move (all difficulties always block 5-in-a-row)
        if let blockMove = findWinningMove(board: board, player: player.opposite) {
            return blockMove
        }

        // Check for open four — probability based on difficulty
        if randomSource.nextInt(upperBound: 100) < blockOpenFourChance {
            if let blockFour = findOpenFour(board: board, player: player.opposite) {
                return blockFour
            }
        }

        // Try to create open four
        if randomSource.nextInt(upperBound: 100) < blockOpenFourChance {
            if let createFour = findOpenFour(board: board, player: player) {
                return createFour
            }
        }

        // Check for open three threats — probability based on difficulty
        if randomSource.nextInt(upperBound: 100) < seeOpenThreeChance {
            if let blockThree = findOpenThree(board: board, player: player.opposite) {
                return blockThree
            }
            if let createThree = findOpenThree(board: board, player: player) {
                return createThree
            }
        }

        // Use GKStrategist for the general search
        strategist.gameModel = gameModel

        if let move = strategist.bestMoveForActivePlayer() as? GomokuMove {
            // Chance to pick a suboptimal move for variety (easy/medium)
            if suboptimalChance > 0 && randomSource.nextInt(upperBound: 100) < suboptimalChance {
                if let updates = gameModel.gameModelUpdates(for: GomokuPlayer.from(player)) as? [GomokuMove],
                   updates.count > 2 {
                    let maxIndex = min(3, updates.count - 1)
                    let randomIndex = randomSource.nextInt(upperBound: maxIndex) + 1
                    let altMove = updates[randomIndex]
                    return (altMove.row, altMove.col)
                }
            }
            return (move.row, move.col)
        }

        // Fallback: pick any candidate
        let candidates = getCandidateMoves(board: board)
        return candidates.first
    }

    // MARK: - First Move

    private func firstMove(board: GomokuBoard) -> (row: Int, col: Int) {
        let center = board.size / 2
        switch difficulty {
        case .easy:
            let offset = randomSource.nextInt(upperBound: 5) - 2
            return (center + offset, center + randomSource.nextInt(upperBound: 5) - 2)
        case .medium:
            let offsets = [0, 0, 0, -1, 1]
            let rowOffset = offsets[randomSource.nextInt(upperBound: offsets.count)]
            let colOffset = offsets[randomSource.nextInt(upperBound: offsets.count)]
            return (center + rowOffset, center + colOffset)
        case .hard:
            let offsets = [0, 0, 0, 0, -1, 1]
            let rowOffset = offsets[randomSource.nextInt(upperBound: offsets.count)]
            let colOffset = offsets[randomSource.nextInt(upperBound: offsets.count)]
            return (center + rowOffset, center + colOffset)
        }
    }

    // MARK: - Tactical Checks

    private func findWinningMove(board: GomokuBoard, player: Player) -> (row: Int, col: Int)? {
        let candidates = getCandidateMoves(board: board)

        for (row, col) in candidates {
            let testBoard = GomokuBoard(copying: board)
            testBoard.currentPlayer = player

            if testBoard.placeStone(at: row, col: col) {
                if case .won = testBoard.gameState {
                    return (row, col)
                }
            }
        }

        return nil
    }

    private func findOpenFour(board: GomokuBoard, player: Player) -> (row: Int, col: Int)? {
        let candidates = getCandidateMoves(board: board)
        let directions = [(0, 1), (1, 0), (1, 1), (1, -1)]

        for (row, col) in candidates {
            for (dx, dy) in directions {
                let pattern = analyzeLine(board: board, row: row, col: col, dx: dx, dy: dy, player: player)
                if pattern.count == 4 && pattern.openEnds >= 1 {
                    return (row, col)
                }
            }
        }

        return nil
    }

    private func findOpenThree(board: GomokuBoard, player: Player) -> (row: Int, col: Int)? {
        let candidates = getCandidateMoves(board: board)
        let directions = [(0, 1), (1, 0), (1, 1), (1, -1)]

        var openThrees: [(row: Int, col: Int)] = []

        for (row, col) in candidates {
            for (dx, dy) in directions {
                let pattern = analyzeLine(board: board, row: row, col: col, dx: dx, dy: dy, player: player)
                if pattern.count == 3 && pattern.openEnds == 2 {
                    openThrees.append((row, col))
                }
            }
        }

        // Pick one at random for variety
        if openThrees.isEmpty { return nil }
        return openThrees[randomSource.nextInt(upperBound: openThrees.count)]
    }

    // MARK: - Helpers

    private func getCandidateMoves(board: GomokuBoard) -> [(row: Int, col: Int)] {
        var candidates: Set<Int> = []
        let range = 2

        for row in 0..<board.size {
            for col in 0..<board.size {
                if board.getPlayer(at: row, col: col) != .none {
                    for dr in -range...range {
                        for dc in -range...range {
                            let r = row + dr
                            let c = col + dc
                            if r >= 0 && r < board.size && c >= 0 && c < board.size {
                                if board.getPlayer(at: r, col: c) == .none {
                                    candidates.insert(r * board.size + c)
                                }
                            }
                        }
                    }
                }
            }
        }

        return candidates.map { hash in
            let row = hash / board.size
            let col = hash % board.size
            return (row, col)
        }
    }

    private func analyzeLine(board: GomokuBoard, row: Int, col: Int, dx: Int, dy: Int, player: Player) -> (count: Int, openEnds: Int) {
        var count = 0
        var openEnds = 0

        var r = row
        var c = col
        while r >= 0 && r < board.size && c >= 0 && c < board.size && board.getPlayer(at: r, col: c) == player {
            count += 1
            r += dx
            c += dy
        }
        if r >= 0 && r < board.size && c >= 0 && c < board.size && board.getPlayer(at: r, col: c) == .none {
            openEnds += 1
        }

        r = row - dx
        c = col - dy
        while r >= 0 && r < board.size && c >= 0 && c < board.size && board.getPlayer(at: r, col: c) == player {
            count += 1
            r -= dx
            c -= dy
        }
        if r >= 0 && r < board.size && c >= 0 && c < board.size && board.getPlayer(at: r, col: c) == .none {
            openEnds += 1
        }

        return (count, openEnds)
    }
}
