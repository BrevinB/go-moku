//
//  OpeningBook.swift
//  Gomoku
//
//  Pre-computed opening moves for faster and stronger AI play.
//  Based on standard Gomoku opening theory and joseki patterns.
//

import Foundation

/// Opening book for Gomoku AI with pre-computed moves for early game positions
class OpeningBook {
    static let shared = OpeningBook()

    /// Maximum number of moves to use opening book (after this, use full AI)
    private let maxBookMoves = 8

    /// Center of a 15x15 board
    private let center = 7

    private init() {}

    /// Attempts to find a book move for the current position
    /// - Parameters:
    ///   - board: Current game board
    ///   - player: Player to move
    /// - Returns: A pre-computed move if position is in the book, nil otherwise
    func getBookMove(board: GomokuBoard, player: Player) -> (row: Int, col: Int)? {
        let moveHistory = board.getMoveHistory()
        let moveCount = moveHistory.count

        // Only use book for early game
        guard moveCount < maxBookMoves else { return nil }

        // First move: always play center (with slight variation for variety)
        if moveCount == 0 {
            return getFirstMove()
        }

        // Get normalized position pattern
        if let move = findPatternMatch(board: board, moveHistory: moveHistory, player: player) {
            return move
        }

        return nil
    }

    // MARK: - First Move

    private func getFirstMove() -> (row: Int, col: Int) {
        // Center is the strongest first move in Gomoku
        // Add slight randomization for variety (within 1 square of center)
        let offsets = [0, 0, 0, 0, -1, 1] // Weighted toward exact center
        let rowOffset = offsets.randomElement() ?? 0
        let colOffset = offsets.randomElement() ?? 0
        return (center + rowOffset, center + colOffset)
    }

    // MARK: - Pattern Matching

    private func findPatternMatch(board: GomokuBoard, moveHistory: [Move], player: Player) -> (row: Int, col: Int)? {
        let moveCount = moveHistory.count

        // Second move (responding to opponent's first move)
        if moveCount == 1 {
            return getSecondMoveResponse(opponentMove: moveHistory[0], board: board)
        }

        // Third move and beyond - use pattern library
        if moveCount >= 2 {
            return getPatternResponse(moveHistory: moveHistory, board: board, player: player)
        }

        return nil
    }

    // MARK: - Second Move Responses

    private func getSecondMoveResponse(opponentMove: Move, board: GomokuBoard) -> (row: Int, col: Int)? {
        let oppRow = opponentMove.row
        let oppCol = opponentMove.col

        // If opponent played center, play adjacent (diagonal is strongest)
        if oppRow == center && oppCol == center {
            return getAdjacentMove(to: (center, center), board: board, preferDiagonal: true)
        }

        // If opponent played near center, take center if available
        if abs(oppRow - center) <= 2 && abs(oppCol - center) <= 2 {
            if board.getPlayer(at: center, col: center) == .none {
                return (center, center)
            }
        }

        // Otherwise, play adjacent to opponent's stone
        return getAdjacentMove(to: (oppRow, oppCol), board: board, preferDiagonal: true)
    }

    // MARK: - Pattern Responses (Moves 3+)

    private func getPatternResponse(moveHistory: [Move], board: GomokuBoard, player: Player) -> (row: Int, col: Int)? {
        // Check for direct attack/defense patterns first
        if let tacticalMove = getTacticalBookMove(board: board, player: player) {
            return tacticalMove
        }

        // Standard opening patterns based on move count
        let moveCount = moveHistory.count

        switch moveCount {
        case 2:
            return getThirdMove(moveHistory: moveHistory, board: board, player: player)
        case 3:
            return getFourthMove(moveHistory: moveHistory, board: board, player: player)
        case 4, 5, 6, 7:
            return getMidOpeningMove(moveHistory: moveHistory, board: board, player: player)
        default:
            return nil
        }
    }

    // MARK: - Specific Move Patterns

    private func getThirdMove(moveHistory: [Move], board: GomokuBoard, player: Player) -> (row: Int, col: Int)? {
        // Third move: extend our line or block opponent's potential
        guard moveHistory.count >= 2 else { return nil }

        let myMoves = moveHistory.filter { $0.player == player }
        let oppMoves = moveHistory.filter { $0.player != player }

        if let myFirst = myMoves.first {
            // Try to extend in a good direction
            if let extMove = findBestExtension(from: (myFirst.row, myFirst.col), board: board) {
                return extMove
            }
        }

        // If can't extend, play near opponent
        if let oppFirst = oppMoves.first {
            return getAdjacentMove(to: (oppFirst.row, oppFirst.col), board: board, preferDiagonal: false)
        }

        return nil
    }

    private func getFourthMove(moveHistory: [Move], board: GomokuBoard, player: Player) -> (row: Int, col: Int)? {
        guard moveHistory.count >= 3 else { return nil }

        let myMoves = moveHistory.filter { $0.player == player }

        // Try to form a line with our stones
        if myMoves.count >= 2 {
            if let lineMove = findLineExtension(moves: myMoves, board: board) {
                return lineMove
            }
        }

        // Otherwise extend from any of our stones
        for move in myMoves {
            if let ext = findBestExtension(from: (move.row, move.col), board: board) {
                return ext
            }
        }

        return nil
    }

    private func getMidOpeningMove(moveHistory: [Move], board: GomokuBoard, player: Player) -> (row: Int, col: Int)? {
        let myMoves = moveHistory.filter { $0.player == player }

        // Priority: extend existing lines
        if let lineMove = findLineExtension(moves: myMoves, board: board) {
            return lineMove
        }

        // Try to create connected groups
        if let connectedMove = findConnectingMove(moves: myMoves, board: board) {
            return connectedMove
        }

        return nil
    }

    // MARK: - Tactical Book Moves

    private func getTacticalBookMove(board: GomokuBoard, player: Player) -> (row: Int, col: Int)? {
        // Check for forcing sequences we can recognize from patterns
        // This is a simplified tactical check for common patterns

        let size = board.size
        var strongSquares: [(row: Int, col: Int)] = []

        // Look for "must-play" squares based on threat patterns
        for row in 0..<size {
            for col in 0..<size {
                guard board.getPlayer(at: row, col: col) == .none else { continue }

                // Check if this creates a significant threat
                if isStrongOpeningSquare(row: row, col: col, board: board, player: player) {
                    strongSquares.append((row, col))
                }
            }
        }

        // Randomly select among strong squares for variety
        return strongSquares.randomElement()
    }

    private func isStrongOpeningSquare(row: Int, col: Int, board: GomokuBoard, player: Player) -> Bool {
        // Check if placing here creates good shape
        var friendlyNeighbors = 0
        var emptyNeighbors = 0

        let directions = [(-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)]

        for (dr, dc) in directions {
            let nr = row + dr
            let nc = col + dc
            if nr >= 0 && nr < board.size && nc >= 0 && nc < board.size {
                let occupant = board.getPlayer(at: nr, col: nc)
                if occupant == player {
                    friendlyNeighbors += 1
                } else if occupant == .none {
                    emptyNeighbors += 1
                }
            }
        }

        // Good opening squares have 1-2 friendly neighbors and open space
        return friendlyNeighbors >= 1 && friendlyNeighbors <= 2 && emptyNeighbors >= 5
    }

    // MARK: - Helper Functions

    private func getAdjacentMove(to position: (Int, Int), board: GomokuBoard, preferDiagonal: Bool) -> (row: Int, col: Int)? {
        let (row, col) = position

        // Diagonal positions (stronger in Gomoku)
        let diagonals = [(-1, -1), (-1, 1), (1, -1), (1, 1)]
        // Orthogonal positions
        let orthogonals = [(-1, 0), (1, 0), (0, -1), (0, 1)]

        // Shuffle within each category for variety
        let shuffledDiagonals = diagonals.shuffled()
        let shuffledOrthogonals = orthogonals.shuffled()
        let shuffledDirections = preferDiagonal ?
            shuffledDiagonals + shuffledOrthogonals :
            shuffledOrthogonals + shuffledDiagonals

        for (dr, dc) in shuffledDirections {
            let nr = row + dr
            let nc = col + dc
            if nr >= 0 && nr < board.size && nc >= 0 && nc < board.size {
                if board.getPlayer(at: nr, col: nc) == .none {
                    return (nr, nc)
                }
            }
        }

        return nil
    }

    private func findBestExtension(from position: (Int, Int), board: GomokuBoard) -> (row: Int, col: Int)? {
        let (row, col) = position

        // Try extending in all 8 directions, prefer moves toward center
        let directions = [(-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)].shuffled()

        var bestMoves: [(row: Int, col: Int)] = []
        var bestScore = Int.min

        for (dr, dc) in directions {
            // Check 1 and 2 squares away
            for distance in 1...2 {
                let nr = row + dr * distance
                let nc = col + dc * distance

                if nr >= 0 && nr < board.size && nc >= 0 && nc < board.size {
                    if board.getPlayer(at: nr, col: nc) == .none {
                        // Score based on centrality
                        let centralityScore = board.size - abs(nr - center) - abs(nc - center)

                        if centralityScore > bestScore {
                            bestScore = centralityScore
                            bestMoves = [(nr, nc)]
                        } else if centralityScore == bestScore {
                            bestMoves.append((nr, nc))
                        }
                    }
                }
            }
        }

        // Randomly select among equally good moves
        return bestMoves.randomElement()
    }

    private func findLineExtension(moves: [Move], board: GomokuBoard) -> (row: Int, col: Int)? {
        guard moves.count >= 2 else { return nil }

        var validExtensions: [(row: Int, col: Int)] = []

        // Check if any two moves are aligned
        for i in 0..<moves.count {
            for j in (i + 1)..<moves.count {
                let m1 = moves[i]
                let m2 = moves[j]

                let dr = m2.row - m1.row
                let dc = m2.col - m1.col

                // Check if they're on a line (adjacent or with gap)
                let distance = max(abs(dr), abs(dc))
                if distance <= 2 {
                    // Normalize direction
                    let ndr = dr == 0 ? 0 : dr / abs(dr)
                    let ndc = dc == 0 ? 0 : dc / abs(dc)

                    // Try extending in both directions
                    for dir in [-1, 1] {
                        let nr = (dir == 1 ? m2.row : m1.row) + ndr * dir
                        let nc = (dir == 1 ? m2.col : m1.col) + ndc * dir

                        if nr >= 0 && nr < board.size && nc >= 0 && nc < board.size {
                            if board.getPlayer(at: nr, col: nc) == .none {
                                validExtensions.append((nr, nc))
                            }
                        }
                    }
                }
            }
        }

        // Randomly select among valid extensions for variety
        return validExtensions.randomElement()
    }

    private func findConnectingMove(moves: [Move], board: GomokuBoard) -> (row: Int, col: Int)? {
        guard !moves.isEmpty else { return nil }

        // Find a move that's adjacent to multiple friendly stones
        var candidateScores: [(row: Int, col: Int, score: Int)] = []

        let checked = Set(moves.map { "\($0.row),\($0.col)" })

        for move in moves {
            let directions = [(-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)]

            for (dr, dc) in directions {
                let nr = move.row + dr
                let nc = move.col + dc

                if nr >= 0 && nr < board.size && nc >= 0 && nc < board.size {
                    if board.getPlayer(at: nr, col: nc) == .none {
                        let key = "\(nr),\(nc)"
                        if !checked.contains(key) {
                            // Count adjacent friendly stones
                            var score = countAdjacentFriendly(row: nr, col: nc, player: moves[0].player, board: board)
                            // Bonus for centrality
                            score += (board.size - abs(nr - center) - abs(nc - center)) / 2

                            candidateScores.append((nr, nc, score))
                        }
                    }
                }
            }
        }

        // Find the best score
        guard let maxScore = candidateScores.map({ $0.score }).max() else { return nil }

        // Collect all candidates with the best score
        let bestCandidates = candidateScores.filter { $0.score == maxScore }

        // Randomly select among equally good candidates for variety
        if let selected = bestCandidates.randomElement() {
            return (selected.row, selected.col)
        }

        return nil
    }

    private func countAdjacentFriendly(row: Int, col: Int, player: Player, board: GomokuBoard) -> Int {
        var count = 0
        let directions = [(-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)]

        for (dr, dc) in directions {
            let nr = row + dr
            let nc = col + dc
            if nr >= 0 && nr < board.size && nc >= 0 && nc < board.size {
                if board.getPlayer(at: nr, col: nc) == player {
                    count += 1
                }
            }
        }

        return count
    }
}
