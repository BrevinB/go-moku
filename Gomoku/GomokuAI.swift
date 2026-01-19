//
//  GomokuAI.swift
//  Gomoku
//
//  Created by Brevin Blalock on 10/13/25.
//

import Foundation

enum AIDifficulty: String, Codable {
    case easy
    case medium
    case hard
}

class GomokuAI {
    private let difficulty: AIDifficulty
    private let maxDepth: Int
    private let candidateLimit: Int
    private let suboptimalChance: Int      // Percentage chance to pick suboptimal move
    private let blockOpenFourChance: Int   // Percentage chance to block open 4
    private let seeOpenThreeChance: Int    // Percentage chance to detect open 3 threats

    init(difficulty: AIDifficulty) {
        self.difficulty = difficulty
        switch difficulty {
        case .easy:
            // Beginners should learn then win consistently
            self.maxDepth = 1
            self.candidateLimit = 5
            self.suboptimalChance = 40
            self.blockOpenFourChance = 70
            self.seeOpenThreeChance = 0     // Never sees open 3 threats
        case .medium:
            // Requires thinking but beatable with basic strategy
            self.maxDepth = 2
            self.candidateLimit = 10
            self.suboptimalChance = 10
            self.blockOpenFourChance = 100
            self.seeOpenThreeChance = 80    // Sometimes misses open 3
        case .hard:
            // Requires proper Gomoku knowledge to beat
            self.maxDepth = 4
            self.candidateLimit = 15
            self.suboptimalChance = 0
            self.blockOpenFourChance = 100
            self.seeOpenThreeChance = 100   // Always sees threats
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

        // Find promising moves near existing stones
        var candidateMoves = getCandidateMoves(board: board)

        if candidateMoves.isEmpty {
            // First move - place in or near center with randomization for variety
            let center = board.size / 2
            switch difficulty {
            case .easy:
                // More random placement for easy
                let offset = Int.random(in: -2...2)
                return (center + offset, center + Int.random(in: -2...2))
            case .medium:
                // Small variation for medium
                let offsets = [0, 0, 0, -1, 1]
                let rowOffset = offsets.randomElement() ?? 0
                let colOffset = offsets.randomElement() ?? 0
                return (center + rowOffset, center + colOffset)
            case .hard:
                // Slight variation even for hard - still strong but not robotic
                let offsets = [0, 0, 0, 0, -1, 1]
                let rowOffset = offsets.randomElement() ?? 0
                let colOffset = offsets.randomElement() ?? 0
                return (center + rowOffset, center + colOffset)
            }
        }

        // CRITICAL: Check for immediate win (all difficulties always take the win)
        if let winMove = findWinningMove(board: board, player: player) {
            return winMove
        }

        // CRITICAL: Block opponent's winning move (all difficulties always block 5-in-a-row)
        if let blockMove = findWinningMove(board: board, player: player.opposite) {
            return blockMove
        }

        // Check for open four - probability based on difficulty
        if Int.random(in: 1...100) <= blockOpenFourChance {
            if let blockFour = findOpenFour(board: board, player: player.opposite) {
                return blockFour
            }
        }

        // Try to create open four
        if Int.random(in: 1...100) <= blockOpenFourChance {
            if let createFour = findOpenFour(board: board, player: player) {
                return createFour
            }
        }

        // Check for open three threats - probability based on difficulty
        if Int.random(in: 1...100) <= seeOpenThreeChance {
            if let blockThree = findOpenThree(board: board, player: player.opposite) {
                return blockThree
            }
            if let createThree = findOpenThree(board: board, player: player) {
                return createThree
            }
        }

        // Sort candidates by their heuristic value for better pruning and move ordering
        candidateMoves = candidateMoves.sorted { move1, move2 in
            let score1 = quickEvaluate(board: board, row: move1.row, col: move1.col, player: player)
            let score2 = quickEvaluate(board: board, row: move2.row, col: move2.col, player: player)
            return score1 > score2
        }

        // Limit candidates based on difficulty
        candidateMoves = Array(candidateMoves.prefix(candidateLimit))

        // Chance to pick a suboptimal move for variety (easy/medium)
        if suboptimalChance > 0 && candidateMoves.count > 2 && Int.random(in: 1...100) <= suboptimalChance {
            // Pick from positions 2-4 instead of the best
            let maxIndex = min(3, candidateMoves.count - 1)
            return candidateMoves[Int.random(in: 1...maxIndex)]
        }

        // Use minimax for best move, collecting all moves with the best score
        var bestScore = Int.min
        var bestMoves: [(Int, Int)] = []

        for move in candidateMoves {
            let testBoard = GomokuBoard(copying: board)
            if testBoard.placeStone(at: move.row, col: move.col) {
                let score = minimax(board: testBoard, depth: maxDepth - 1, alpha: Int.min, beta: Int.max, isMaximizing: false, player: player)

                if score > bestScore {
                    bestScore = score
                    bestMoves = [move]
                } else if score == bestScore {
                    // Collect all equally good moves for variety
                    bestMoves.append(move)
                }
            }
        }

        // Randomly select among equally good moves for variety
        if !bestMoves.isEmpty {
            return bestMoves.randomElement()
        }
        return candidateMoves.first
    }

    private func minimax(board: GomokuBoard, depth: Int, alpha: Int, beta: Int, isMaximizing: Bool, player: Player) -> Int {
        // Terminal conditions
        if case .won(let winner) = board.gameState {
            let depthBonus = depth * 100 // Prefer quicker wins
            return winner == player ? 100000 + depthBonus : -100000 - depthBonus
        }

        if case .draw = board.gameState {
            return 0
        }

        if depth == 0 {
            return evaluateBoard(board: board, player: player)
        }

        // Get and sort candidate moves for better alpha-beta pruning
        var candidateMoves = getCandidateMoves(board: board)

        // Limit candidates in deeper searches to save time
        let moveLimit = max(8, 12 - depth) // Fewer moves as we go deeper
        if candidateMoves.count > moveLimit {
            // Quick sort by position quality
            candidateMoves = candidateMoves.sorted { move1, move2 in
                let score1 = quickEvaluate(board: board, row: move1.row, col: move1.col, player: isMaximizing ? player : player.opposite)
                let score2 = quickEvaluate(board: board, row: move2.row, col: move2.col, player: isMaximizing ? player : player.opposite)
                return score1 > score2
            }
            candidateMoves = Array(candidateMoves.prefix(moveLimit))
        }

        var alpha = alpha
        var beta = beta

        if isMaximizing {
            var maxScore = Int.min
            for move in candidateMoves {
                let testBoard = GomokuBoard(copying: board)
                if testBoard.placeStone(at: move.row, col: move.col) {
                    let score = minimax(board: testBoard, depth: depth - 1, alpha: alpha, beta: beta, isMaximizing: false, player: player)
                    maxScore = max(maxScore, score)
                    alpha = max(alpha, score)
                    if beta <= alpha {
                        break // Beta cutoff
                    }
                }
            }
            return maxScore == Int.min ? 0 : maxScore
        } else {
            var minScore = Int.max
            for move in candidateMoves {
                let testBoard = GomokuBoard(copying: board)
                if testBoard.placeStone(at: move.row, col: move.col) {
                    let score = minimax(board: testBoard, depth: depth - 1, alpha: alpha, beta: beta, isMaximizing: true, player: player)
                    minScore = min(minScore, score)
                    beta = min(beta, score)
                    if beta <= alpha {
                        break // Alpha cutoff
                    }
                }
            }
            return minScore == Int.max ? 0 : minScore
        }
    }

    private func evaluateBoard(board: GomokuBoard, player: Player) -> Int {
        var score = 0

        // Evaluate all lines (horizontal, vertical, diagonals)
        score += evaluateLines(board: board, player: player)

        // Add positional bonuses (center control)
        score += evaluateCenterControl(board: board, player: player)

        return score
    }

    private func evaluateLines(board: GomokuBoard, player: Player) -> Int {
        var score = 0
        let directions = [(0, 1), (1, 0), (1, 1), (1, -1)]

        for row in 0..<board.size {
            for col in 0..<board.size {
                for (dx, dy) in directions {
                    let pattern = analyzeLine(board: board, row: row, col: col, dx: dx, dy: dy, player: player)
                    score += scorePattern(pattern: pattern, isAI: true)

                    let oppPattern = analyzeLine(board: board, row: row, col: col, dx: dx, dy: dy, player: player.opposite)
                    score -= scorePattern(pattern: oppPattern, isAI: false)
                }
            }
        }

        return score
    }

    private func analyzeLine(board: GomokuBoard, row: Int, col: Int, dx: Int, dy: Int, player: Player) -> (count: Int, openEnds: Int) {
        var count = 0
        var openEnds = 0

        // Count consecutive stones
        var r = row
        var c = col
        while r >= 0 && r < board.size && c >= 0 && c < board.size && board.getPlayer(at: r, col: c) == player {
            count += 1
            r += dx
            c += dy
        }

        // Check if the end is open
        if r >= 0 && r < board.size && c >= 0 && c < board.size && board.getPlayer(at: r, col: c) == .none {
            openEnds += 1
        }

        // Check backward direction
        r = row - dx
        c = col - dy
        while r >= 0 && r < board.size && c >= 0 && c < board.size && board.getPlayer(at: r, col: c) == player {
            count += 1
            r -= dx
            c -= dy
        }

        // Check if the other end is open
        if r >= 0 && r < board.size && c >= 0 && c < board.size && board.getPlayer(at: r, col: c) == .none {
            openEnds += 1
        }

        return (count, openEnds)
    }

    private func scorePattern(pattern: (count: Int, openEnds: Int), isAI: Bool) -> Int {
        let (count, openEnds) = pattern
        let multiplier = isAI ? 1 : 1  // Equal weight to attack and defense

        switch count {
        case 5...:
            return 100000 * multiplier
        case 4:
            if openEnds == 2 {
                return 50000 * multiplier  // Open four - almost winning
            } else if openEnds == 1 {
                return 1000 * multiplier   // Closed four - still dangerous
            }
        case 3:
            if openEnds == 2 {
                return 5000 * multiplier   // Open three - very strong
            } else if openEnds == 1 {
                return 200 * multiplier    // Closed three
            }
        case 2:
            if openEnds == 2 {
                return 150 * multiplier    // Open two
            } else if openEnds == 1 {
                return 15 * multiplier     // Closed two
            }
        case 1:
            if openEnds == 2 {
                return 10 * multiplier
            }
        default:
            break
        }

        return 0
    }

    private func evaluateCenterControl(board: GomokuBoard, player: Player) -> Int {
        var score = 0
        let center = board.size / 2

        for row in 0..<board.size {
            for col in 0..<board.size {
                let p = board.getPlayer(at: row, col: col)
                if p == player {
                    let distanceFromCenter = abs(row - center) + abs(col - center)
                    score += max(0, 10 - distanceFromCenter)
                } else if p == player.opposite {
                    let distanceFromCenter = abs(row - center) + abs(col - center)
                    score -= max(0, 8 - distanceFromCenter)
                }
            }
        }

        return score
    }

    private func quickEvaluate(board: GomokuBoard, row: Int, col: Int, player: Player) -> Int {
        var score = 0
        let directions = [(0, 1), (1, 0), (1, 1), (1, -1)]

        for (dx, dy) in directions {
            let pattern = analyzeLine(board: board, row: row, col: col, dx: dx, dy: dy, player: player)
            score += scorePattern(pattern: pattern, isAI: true) / 10

            let oppPattern = analyzeLine(board: board, row: row, col: col, dx: dx, dy: dy, player: player.opposite)
            score += scorePattern(pattern: oppPattern, isAI: false) / 10
        }

        return score
    }

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
                // Only detect actual 4-in-a-row threats here
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
                // Open three: 3 stones with both ends open (very dangerous)
                if pattern.count == 3 && pattern.openEnds == 2 {
                    openThrees.append((row, col))
                }
            }
        }

        // Return random one for variety
        return openThrees.randomElement()
    }

    private func getCandidateMoves(board: GomokuBoard) -> [(row: Int, col: Int)] {
        var candidates: Set<Int> = [] // Use set with hash for deduplication
        let range = 2 // Look within 2 cells of existing stones

        // Only scan positions near existing stones for efficiency
        for row in 0..<board.size {
            for col in 0..<board.size {
                if board.getPlayer(at: row, col: col) != .none {
                    // Add all empty positions around this stone
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

    private func findRandomMove(board: GomokuBoard) -> (row: Int, col: Int)? {
        let candidates = getCandidateMoves(board: board)
        return candidates.isEmpty ? nil : candidates.randomElement()
    }
}
